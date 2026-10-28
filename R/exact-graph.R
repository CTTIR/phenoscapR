.ed_prepare_registry <- function(
  nodes, frames, groups, frame, id, x, y,
  point_order, orientation_rank, geometry, eligible, unit_column, coordinate_unit,
  edge_order, window_policy, cap_policy, eps, mode, caps = numeric(), initial_madj = 64L,
    max_retries = 32L
) {
  .ed_assert(.ed_names(groups), "Invalid group names")
  roles <- list(frame, id, x, y, point_order, orientation_rank, geometry, eligible, unit_column)
  .ed_assert(
    all(vapply(roles, function(z) .ed_names(z) && length(z) == 1L, logical(1))),
    "Selected roles must be scalar names"
  )
  keys <- c(groups, frame)
  selected <- c(keys, id, x, y, point_order, orientation_rank, geometry, eligible)
  .ed_assert(.ed_names(selected) && .ed_names(c(keys, unit_column)), "Selected roles collide")
  outputs <- c(
    "ind1", "ind2", "x1", "y1", "x2", "y2", "from_id", "to_id",
    "from_geometry_index", "to_geometry_index", "from_orientation_rank", "to_orientation_rank",
    "distance", "analysis_edge", "edge_row", "geometry_index", "source_row", "n_nodes",
    "n_geometry", "n_eligible", "n_full_edges", "n_analysis_edges", "status"
  )
  .ed_assert(!any(keys %in% outputs) && !any(c(id, x, y, point_order, orientation_rank,
    geometry, eligible) %in%
    c("geometry_index", "source_row")), "Keys or roles collide with output fields")
  table <- function(z, cols) {
    .ed_assert(
      is.data.frame(z) && !anyDuplicated(names(z)) && all(cols %in% names(z)),
      "Invalid table schema"
    )
    as.data.frame(z, stringsAsFactors = FALSE)
  }
  nodes <- table(nodes, selected)
  frames <- table(frames, c(keys, unit_column))
  .ed_assert(
    nrow(nodes) <= .Machine$integer.max && nrow(frames) <= .Machine$integer.max,
    "Registry exceeds supported row capacity"
  )
  fk <- .ed_keys(frames, keys)
  nk <- .ed_keys(nodes, c(keys, id))
  .ed_assert(!anyDuplicated(fk) && !anyDuplicated(nk), "Duplicate frame or node ID")
  nf <- match(.ed_keys(nodes, keys), fk)
  .ed_assert(!anyNA(nf), "Unknown declared frame")
  .ed_assert(.ed_names(coordinate_unit) && length(coordinate_unit) == 1L &&
    coordinate_unit %in% c("nm", "um", "mm", "cm", "m") && .ed_text(frames[[unit_column]]) &&
    all(frames[[unit_column]] == coordinate_unit), "Declared coordinate units differ")
  .ed_assert(identical(edge_order, "orientation_rank"),
    "Explicit edge_order must be orientation_rank")
  .ed_assert(identical(window_policy, "span_padding_v1"),
    "Explicit supported window policy required")
  .ed_assert(identical(cap_policy, "distance_leq"),
    "Explicit inclusive distance cap policy required")
  .ed_assert(.ed_number(nodes[[x]]) && .ed_number(nodes[[y]]),
    "Coordinates must be finite real vectors")
  for (k in c(point_order, orientation_rank)) {
    z <- nodes[[k]]
    .ed_assert(
      .ed_number(z) && all(z >= 1 & z <= .Machine$integer.max & z == floor(z)),
      "Orders must be positive whole vectors within integer capacity"
    )
  }
  for (k in c(geometry, eligible)) {
    .ed_assert(is.logical(nodes[[k]]) && !is.object(nodes[[k]]) && is.null(dim(nodes[[k]])) &&
      !anyNA(nodes[[k]]), "Memberships must be nonmissing logical vectors")
  }
  .ed_assert(all(!nodes[[eligible]] | nodes[[geometry]]), "Eligible nodes must belong to geometry")
  .ed_assert(.ed_number(caps) && all(caps > 0) && (!length(caps) || (.ed_names(names(caps)) &&
    length(names(caps)) == length(caps))), "Caps must be explicitly named positive finite values")
  .ed_assert(.ed_number(eps) && length(eps) == 1L && eps > 0, "Positive scalar eps required")
  .ed_assert(is.character(mode) && !is.object(mode) && length(mode) == 1L && is.null(dim(mode)) &&
    !is.na(mode) && mode %in% c("auto", "stock", "bounded"), "Explicit workspace mode required")
  # Validate settings even for an empty registry, without loading a backend.
  PlanExactDelaunayWorkspace(3, mode, initial_madj, max_retries, FALSE)
  geometry_rows <- vector("list", nrow(frames))
  plans <- vector("list", nrow(frames))
  windows <- vector("list", nrow(frames))
  upper_edges <- numeric(nrow(frames))
  for (f in seq_len(nrow(frames))) {
    rows <- which(nf == f)
    .ed_assert(!anyDuplicated(nodes[[point_order]][rows]) &&
      !anyDuplicated(nodes[[orientation_rank]][rows]), "Duplicate declared order within frame")
    p <- rows[nodes[[geometry]][rows]]
    p <- p[order(nodes[[point_order]][p])]
    n <- length(p)
    .ed_assert(n >= 3L, "Frame geometry requires at least three points")
    xx <- nodes[[x]][p]
    yy <- nodes[[y]][p]
    .ed_assert(!anyDuplicated(data.frame(x = xx, y = yy)), "Duplicate geometry coordinates")
    dx <- xx - xx[1]
    dy <- yy - yy[1]
    area <- dx[2] * dy - dy[2] * dx
    .ed_assert(all(is.finite(area)) && any(area != 0), "Conservative noncollinear guard failed")
    geometry_rows[[f]] <- p
    windows[[f]] <- .ed_window(xx, yy)
    plans[[f]] <- PlanExactDelaunayWorkspace(n, mode, initial_madj, max_retries, FALSE)
    .ed_assert(!plans[[f]]$bounded_required, "Frame exceeds the integer workspace of deldir::deldir()")
    upper_edges[f] <- 3 * as.double(n) - 6
  }
  .ed_assert(sum(upper_edges) <= .Machine$integer.max,
    "Combined conservative edge bound exceeds integer capacity")
  .ed_assert(
    !length(caps) || sum(upper_edges) <= floor(.Machine$integer.max / length(caps)),
    "Conservative cap matrix bound exceeds integer capacity"
  )
  list(
    nodes = nodes, frames = frames, keys = keys, geometry_rows = geometry_rows,
    plans = plans, windows = windows, maximum_edges = sum(upper_edges), native_execution = FALSE
  )
}

#' Build Explicitly Ordered Delaunay Graphs
#'
#' Constructs each complete declared geometry before selecting edges whose two
#' endpoints are eligible. Uses `deldir::deldir()` with no fallback, coordinate
#' rounding, jitter or population inference.
#'
#' @param nodes Data frame of keys, coordinates, orders and memberships.
#' @param frames Data frame of unique complete group/frame keys and units.
#' @param groups Nonempty character vector of distinct grouping column names.
#' @param frame Character name of the coordinate-frame key in both tables.
#' @param id Character name of the node ID column. IDs are unique within frames.
#' @param x,y Character names of finite coordinate columns in `nodes`.
#' @param point_order Character name of unique positive whole within-frame
#'   ranks defining geometry input order, independently of table row order.
#' @param orientation_rank Character name of unique positive whole within-frame
#'   ranks defining undirected endpoint orientation, independently of input order.
#' @param geometry,eligible Character names of nonmissing logical memberships.
#'   Eligibility implies geometry membership. Nodes outside geometry remain in
#'   the node map; isolated eligible nodes are retained.
#' @param unit_column Character name of the units column in `frames`.
#' @param coordinate_unit One of `"nm"`, `"um"`, `"mm"`, `"cm"`, `"m"`.
#'   All frames must declare this unit; no conversion occurs.
#' @param edge_order Required string `"orientation_rank"`. Output edges sort by
#'   UTF-8 group/frame keys, then numeric endpoint orientation ranks.
#' @param window_policy Required string `"span_padding_v1"`. Bounds extend the
#'   coordinate ranges by `max(1e-6, max(x_span, y_span) * 1e-10)` on each side.
#' @param cap_policy Required string `"distance_leq"`. Named caps use inclusive
#'   comparisons with `sqrt(dx^2 + dy^2)`, without a tolerance.
#' @param backend_contract Deprecated and ignored. Construction uses the public
#'   `deldir::deldir()` interface, so there are no private functions or native
#'   routines to pin. Kept so that existing calls keep working.
#' @param eps Explicit positive finite scalar tolerance passed to the engine.
#' @param mode Explicit `"stock"`, `"bounded"` or `"auto"` workspace mode,
#'   validated with [PlanExactDelaunayWorkspace()] and recorded in the
#'   provenance. Every mode runs `deldir::deldir()`, which sizes its own
#'   workspace and enlarges it when needed; frames whose stock workspace would
#'   exceed the integer limit (`bounded_required`) are refused.
#' @param caps Named positive finite numeric thresholds in `coordinate_unit`.
#'   An empty numeric vector requests no cap columns.
#' @param initial_madj,max_retries Validated as in [PlanExactDelaunayWorkspace()];
#'   they no longer change the construction.
#'
#' @details
#' Supported columns are dimensionless, unclassed base character, integer/double
#' or logical vectors as appropriate. Names are allowed. Factors, `integer64`
#' and arbitrary classed columns are rejected without coercion. Data frames and
#' data.tables are supported containers. Keys must be nonmissing and nonblank.
#' Selected roles are distinct within each table. Node roles cannot be named
#' `source_row` or `geometry_index`; group/frame keys cannot collide with output
#' edge or frame-summary fields. Duplicate IDs across different frames are valid.
#'
#' Every frame is preflighted before construction begins. A declared frame needs
#' at least three distinct noncollinear geometry points; a declared empty frame
#' fails. A completely empty registry and empty node table return typed empty
#' outputs without loading or executing the backend. Integer workspace and
#' conservative combined edge/cap bounds are checked before allocation; they do
#' not certify available memory. A finite direct-determinant guard is deliberately
#' conservative for extreme or nearly collinear coordinates. Unsupported geometry
#' fails rather than being perturbed. Distances must be finite and positive.
#'
#' Complete edges are checked for whole in-range nonself indices, exact endpoint
#' coordinate reconciliation, duplicate unordered pairs, connectedness and planar
#' cardinality bounds before eligibility induction. These necessary invariants
#' alone are not an independent proof of Delaunay geometry. Co-circular choices
#' depend on the `deldir` version and explicit point order. Numeric orientation ranks
#' and UTF-8 output ordering do not infer a historical locale or ordering policy.
#'
#' `deldir` is optional: a missing installation fails clearly for nonempty
#' construction. Each frame calls `deldir::deldir(x, y, rw, eps, sort = TRUE,
#' round = FALSE)` on the geometry points in `point_order`. Warnings and
#' unexpected messages fail closed; messages announcing that `deldir` enlarged
#' its workspace are counted in the frame provenance (`workspace_growth`). No
#' incomplete tessellation is returned. The frame provenance records the
#' `deldir` version.
#'
#' @return A list with `schema_version = "0.1.0"`, `nodes` (including input
#'   `source_row` and ordered `geometry_index`), `full_edges`,
#'   `analysis_edge_rows`, `cap_flags`, `caps`, `frames` and `provenance`.
#'   `full_edges` contains keys, endpoint IDs/geometry indices/orientation ranks,
#'   coordinates, distance, `analysis_edge` and `edge_row`. Frame counts distinguish
#'   all nodes, geometry, eligible nodes, full edges and induced edges.
#'   `frame_construction` contains keyed per-frame engine/workspace receipts in
#'   input registry order; output tables sort independently. No input is modified.
#'
#' @examples
#' PlanExactDelaunayWorkspace(100, mode = "stock")$native_buffer_bytes
#' if (requireNamespace("deldir", quietly = TRUE)) {
#'   nodes <- data.frame(
#'     sample = "one", frame = "image", id = c("a", "b", "c", "d"),
#'     x = c(0, 4, 0, 3), y = c(0, 0, 3, 4), input = 1:4, orientation = 1:4,
#'     geometry = TRUE, eligible = c(TRUE, TRUE, TRUE, FALSE)
#'   )
#'   frames <- data.frame(sample = "one", frame = "image", unit = "um")
#'   graph <- BuildExactDelaunayEdges(nodes, frames, "sample", "frame", "id",
#'     "x", "y", "input", "orientation", "geometry", "eligible", "unit", "um",
#'     "orientation_rank", "span_padding_v1", "distance_leq",
#'     eps = 1e-9, mode = "stock", caps = c(short = 3, long = 5)
#'   )
#'   graph$full_edges
#' }
#' @export
BuildExactDelaunayEdges <- function(
  nodes, frames, groups, frame, id, x, y,
  point_order, orientation_rank, geometry, eligible, unit_column, coordinate_unit,
  edge_order, window_policy, cap_policy, backend_contract = NULL, eps, mode, caps = numeric(),
    initial_madj = 64L, max_retries = 32L
) {
  prepared <- .ed_prepare_registry(
    nodes, frames, groups, frame, id, x, y, point_order,
    orientation_rank, geometry, eligible, unit_column, coordinate_unit, edge_order,
      window_policy, cap_policy, eps, mode,
    caps, initial_madj, max_retries
  )
  nodes <- prepared$nodes
  frames <- prepared$frames
  keys <- prepared$keys
  parts <- vector("list", nrow(frames))
  engine <- vector("list", nrow(frames))
  for (f in seq_len(nrow(frames))) {
    p <- prepared$geometry_rows[[f]]
    built <- .ed_build_geometry(
      nodes[[x]][p], nodes[[y]][p], backend_contract,
      eps, mode, initial_madj, max_retries
    )
    .ed_assert(is.list(built) && is.data.frame(built$raw_edges) &&
      identical(as.double(built$n_points), as.double(length(p))),
        "Constructor frame result mismatch")
    raw <- built$raw_edges
    .ed_assert(!any(keys %in% names(raw)), "Constructor edge fields collide with frame keys")
    for (k in keys) raw[[k]] <- rep(frames[[k]][f], nrow(raw))
    parts[[f]] <- raw
    engine[[f]] <- list(frame = frames[f, keys, drop = FALSE], provenance = built$provenance)
  }
  if (length(parts)) {
    raw <- do.call(rbind, parts)
  } else {
    raw <- frames[FALSE, keys, drop = FALSE]
    for (k in c("ind1", "ind2", "x1", "y1", "x2", "y2")) raw[[k]] <- numeric()
  }
  answer <- .ed_validate_supplied_edges(
    nodes, raw, frames, groups, frame, id, x, y, point_order,
    orientation_rank, geometry, eligible, unit_column, coordinate_unit, edge_order, caps
  )
  answer$provenance <- list(
    geometry_source = "DELDIR_CONSTRUCTION",
    construction_performed = nrow(frames) > 0L, native_execution = nrow(frames) > 0L,
    coordinate_unit = coordinate_unit, point_order = "EXPLICIT_NUMERIC_ORDER",
    orientation = "EXPLICIT_NUMERIC_RANK", edge_order = edge_order,
    frame_order = "UTF8_RADIX_GROUP_FRAME_KEYS", window_policy = window_policy,
      cap_policy = cap_policy,
    historical_parity = "NOT_ESTABLISHED",
    empty_registry = if (nrow(frames) == 0L) "NO_BACKEND_LOADED_OR_EXECUTED" else "NOT_EMPTY"
  )
  # Each keyed entry identifies its input registry row; output tables sort independently.
  answer$frame_construction <- engine
  answer
}
