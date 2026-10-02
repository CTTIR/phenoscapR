# Pure preflight and supplied-edge validation; no native graph construction.
.ed_assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}
.ed_number <- function(x) {
  is.numeric(x) && !is.object(x) && !is.complex(x) && is.null(dim(x)) && all(is.finite(x))
}
.ed_whole <- function(x, lower = 0, upper = .Machine$integer.max) {
  .ed_number(x) && length(x) == 1L && x >= lower && x <= upper && x == floor(x)
}
.ed_names <- function(x) {
  is.character(x) && !is.object(x) && is.null(dim(x)) && length(x) > 0L &&
    !anyNA(x) && all(nzchar(trimws(x))) && !anyDuplicated(x)
}
.ed_text <- function(x) {
  is.character(x) && !is.object(x) && is.null(dim(x)) && !anyNA(x) && all(nzchar(trimws(x)))
}
.ed_keys <- function(x, columns) {
  .ed_assert(
    all(vapply(x[columns], .ed_text, logical(1))),
    "Keys must be dimensionless nonblank character vectors without missingness"
  )
  if (!nrow(x)) {
    return(character())
  }
  parts <- lapply(x[columns], function(z) {
    z <- enc2utf8(z)
    paste0(nchar(z, type = "bytes"), ":", z)
  })
  do.call(paste0, unname(parts))
}
.ed_lengths <- function(n, madj, segments) {
  c(
    x = n + 8, y = n + 8, rw = 4, nn = 1, ntot = 1,
    nadj = (madj + 1) * (n + 8), madj = 1, eps = 1,
    delsgs = 6 * segments, ndel = 1, delsum = 4 * n,
    dirsgs = 10 * segments, ndir = 1, dirsum = 3 * n,
    incAdj = 1, incSeg = 1
  )
}

#' Preflight Integer Workspace Bounds for Exact Delaunay Construction
#'
#' Computes buffer lengths and routing without loading a backend, constructing
#' a graph or allocating the planned native vectors.
#' @param n_points Whole scalar point count, at least three.
#' @param mode `"auto"`, `"stock"` or `"bounded"` workspace route.
#' @param initial_madj Whole bounded adjacency capacity, at least 20. The request
#'   is clipped to the largest safe capacity; no unsafe integer coercion occurs.
#' @param max_retries Nonnegative whole adjacency-growth retry ceiling.
#' @param retain_tessellation Logical scalar. `TRUE` is rejected for a bounded
#'   plan, which is edge-only and cannot retain an incomplete tessellation.
#' @details All values must be dimensionless unclassed base vectors. Every native
#'   argument length is checked against signed integer capacity, with one complete
#'   spare adjacency row. The byte estimate includes native buffers only, not R
#'   objects, copies or runtime overhead, and is not an available-memory check.
#'   Successful arithmetic preflight does not qualify a large native execution.
#' @return A list containing requested/selected route, stock and selected
#'   adjacency capacity, segment capacity, named native lengths, integer headroom,
#'   retry ceiling and `native_buffer_bytes`. `native_execution` is always `FALSE`.
#' @examples
#' PlanExactDelaunayWorkspace(100)
#' # Pure arithmetic at the stock spare-row boundary; no large allocation:
#' PlanExactDelaunayWorkspace(799800)$bounded_required
#' @seealso [BuildExactDelaunayEdges()]
#' @export
PlanExactDelaunayWorkspace <- function(n_points, mode = c("auto", "stock", "bounded"),
                                       initial_madj = 64L, max_retries = 32L,
                                       retain_tessellation = FALSE) {
  mode <- match.arg(mode)
  .ed_assert(.ed_whole(n_points, 3), "Invalid two-dimensional point count")
  .ed_assert(.ed_whole(initial_madj, 20), "Invalid initial adjacency capacity")
  .ed_assert(.ed_whole(max_retries), "Invalid retry ceiling")
  .ed_assert(
    is.logical(retain_tessellation) && !is.object(retain_tessellation) &&
      is.null(dim(retain_tessellation)) &&
      length(retain_tessellation) == 1L && !is.na(retain_tessellation),
    "Invalid tessellation retention flag"
  )
  n <- as.double(n_points)
  limit <- as.double(.Machine$integer.max)
  stock_madj <- max(20, ceiling(3 * sqrt(n + 4)))
  stock_length <- (stock_madj + 1) * (n + 8)
  bounded_required <- stock_length > limit - (n + 8)
  .ed_assert(
    mode != "stock" || !bounded_required,
    "Stock workspace lacks a complete spare adjacency row"
  )
  bounded <- mode == "bounded" || (mode == "auto" && bounded_required)
  .ed_assert(
    !bounded || !retain_tessellation,
    "Bounded execution cannot retain an incomplete tessellation"
  )
  max_madj <- floor(limit / (n + 8)) - 2
  .ed_assert(max_madj >= 20, "No safe adjacency capacity remains")
  madj <- if (bounded) min(as.double(initial_madj), max_madj) else stock_madj
  segments <- if (bounded) max(20, 3 * n + 16) else madj * (madj + 1) / 2
  lengths <- .ed_lengths(n, madj, segments)
  .ed_assert(all(is.finite(lengths) & lengths >= 0 & lengths == floor(lengths) &
    lengths <= limit), "Native vector length exceeds integer interface capacity")
  headroom <- floor((limit - lengths[["nadj"]]) / (n + 8))
  .ed_assert(headroom >= 1, "Adjacency workspace lacks one-row headroom")
  widths <- rep(4, length(lengths))
  names(widths) <- names(lengths)
  widths[c("x", "y", "rw", "eps", "delsgs", "delsum", "dirsgs", "dirsum")] <- 8
  list(
    schema_version = "0.1.0", n_points = n, requested_mode = mode,
    execution_path = if (bounded) "BOUNDED_REGISTERED_MASTER" else "STOCK_WRAPPER",
    bounded_required = bounded_required, bounded_planned = bounded,
    stock_madj = stock_madj, stock_adjacency_length = stock_length,
    initial_madj_requested = as.double(initial_madj), initial_madj_used = madj,
    max_madj = max_madj, max_retries = as.double(max_retries),
    segment_capacity = segments, native_lengths = lengths,
    adjacency_headroom_rows = headroom,
    native_buffer_bytes = sum(lengths * widths),
    native_execution = FALSE,
    memory_limit_claim = "BUFFER_SUM_ONLY_EXCLUDES_COPIES_AND_RUNTIME_OVERHEAD"
  )
}

.ed_next_workspace <- function(n_points, madj, retries, max_retries,
                               inc_adj, inc_seg) {
  .ed_assert(
    .ed_whole(madj, 20) && .ed_whole(retries) &&
      .ed_whole(max_retries) && retries <= max_retries,
    "Invalid current workspace or retry state"
  )
  .ed_assert(
    .ed_whole(inc_adj, 0, 1) && .ed_whole(inc_seg, 0, 1),
    "Invalid native retry flags"
  )
  plan <- PlanExactDelaunayWorkspace(n_points, "bounded", madj, max_retries)
  .ed_assert(madj <= plan$max_madj, "Current adjacency capacity exceeds safe maximum")
  .ed_assert(inc_seg == 0, "Segment capacity exhausted; incomplete graph refused")
  if (inc_adj == 0) {
    return(list(
      status = "NO_GROWTH_REQUESTED",
      madj = as.double(madj), retries = as.double(retries), native_execution = FALSE
    ))
  }
  .ed_assert(retries < max_retries, "Adjacency retry ceiling reached")
  next_madj <- min(plan$max_madj, max(as.double(madj) + 1, ceiling(1.2 * madj)))
  .ed_assert(next_madj > madj, "No larger safe adjacency capacity remains")
  next_plan <- PlanExactDelaunayWorkspace(n_points, "bounded", next_madj, max_retries)
  list(
    status = "GROWTH_PLANNED", madj = next_madj, retries = as.double(retries) + 1,
    workspace = next_plan, native_execution = FALSE
  )
}

.ed_validate_supplied_edges <- function(nodes, raw_edges, frames, groups, frame,
                                        id, x, y, point_order, orientation_rank,
                                        geometry, eligible, unit_column,
                                        coordinate_unit, edge_order, caps = numeric()) {
  .ed_assert(.ed_names(groups), "Invalid group names")
  roles <- list(frame, id, x, y, point_order, orientation_rank, geometry, eligible, unit_column)
  .ed_assert(
    all(vapply(roles, function(z) .ed_names(z) && length(z) == 1L, logical(1))),
    "Selected roles must be scalar column names"
  )
  keys <- c(groups, frame)
  selected <- c(keys, id, x, y, point_order, orientation_rank, geometry, eligible)
  .ed_assert(.ed_names(selected) && .ed_names(c(keys, unit_column)), "Selected roles collide")
  edge_fields <- c("ind1", "ind2", "x1", "y1", "x2", "y2")
  outputs <- c(
    edge_fields, "from_id", "to_id", "from_geometry_index", "to_geometry_index",
    "from_orientation_rank", "to_orientation_rank", "distance", "analysis_edge", "edge_row",
    "geometry_index", "source_row", "n_nodes", "n_geometry", "n_eligible", "n_full_edges",
    "n_analysis_edges", "status"
  )
  .ed_assert(
    !any(keys %in% outputs) && !any(c(
      id, x, y, point_order,
      orientation_rank, geometry, eligible
    ) %in% c("geometry_index", "source_row")),
    "Keys or roles collide with output fields"
  )
  table <- function(z, cols) {
    .ed_assert(
      is.data.frame(z) && !anyDuplicated(names(z)) && all(cols %in% names(z)),
      "Invalid table schema"
    )
    as.data.frame(z, stringsAsFactors = FALSE)
  }
  nodes <- table(nodes, selected)
  raw_edges <- table(raw_edges, c(keys, edge_fields))
  frames <- table(frames, c(keys, unit_column))
  .ed_assert(
    all(c(nrow(nodes), nrow(raw_edges), nrow(frames)) <= .Machine$integer.max),
    "Table row counts exceed supported integer index capacity"
  )
  fk <- .ed_keys(frames, keys)
  nk <- .ed_keys(nodes, c(keys, id))
  .ed_assert(!anyDuplicated(fk) && !anyDuplicated(nk), "Duplicate frame or node ID")
  nf <- match(.ed_keys(nodes, keys), fk)
  ef <- match(.ed_keys(raw_edges, keys), fk)
  .ed_assert(!anyNA(nf) && !anyNA(ef), "Unknown declared frame")
  .ed_assert(.ed_names(coordinate_unit) && length(coordinate_unit) == 1L &&
    coordinate_unit %in% c("nm", "um", "mm", "cm", "m") && .ed_text(frames[[unit_column]]) &&
    all(frames[[unit_column]] == coordinate_unit), "Declared coordinate units differ")
  .ed_assert(identical(edge_order, "orientation_rank"),
    "Explicit edge_order must be orientation_rank")
  .ed_assert(.ed_number(nodes[[x]]) && .ed_number(nodes[[y]]),
    "Coordinates must be finite real vectors")
  for (column in c(point_order, orientation_rank)) {
    z <- nodes[[column]]
    .ed_assert(
      .ed_number(z) && all(z >= 1 & z <= .Machine$integer.max & z == floor(z)),
      "Orders must be positive whole vectors within integer capacity"
    )
  }
  for (column in c(geometry, eligible)) {
    .ed_assert(is.logical(nodes[[column]]) && !is.object(nodes[[column]]) &&
      is.null(dim(nodes[[column]])) && !anyNA(nodes[[column]]),
        "Memberships must be nonmissing logical vectors")
  }
  .ed_assert(all(!nodes[[eligible]] | nodes[[geometry]]), "Eligible nodes must belong to geometry")
  .ed_assert(
    all(vapply(raw_edges[edge_fields], .ed_number, logical(1))),
    "Raw indices and endpoint coordinates must be finite real vectors"
  )
  .ed_assert(
    .ed_number(caps) && all(caps > 0) &&
      (!length(caps) || (.ed_names(names(caps)) && length(names(caps)) == length(caps))),
    "Caps must be an explicitly named positive finite vector"
  )
  node_map <- nodes[selected]
  node_map$source_row <- as.double(seq_len(nrow(nodes)))
  node_map$geometry_index <- rep(NA_real_, nrow(nodes))
  summary <- frames[keys]
  for (name in c("n_nodes", "n_geometry", "n_eligible", "n_full_edges",
    "n_analysis_edges")) summary[[name]] <- numeric(nrow(frames))
  summary$status <- rep("FULL_GRAPH_VALIDATED", nrow(frames))
  parts <- vector("list", nrow(frames))
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
    # Fail closed if direct determinant arithmetic cannot establish 2D geometry.
    dx <- xx - xx[1]
    dy <- yy - yy[1]
    area2 <- dx[2] * dy - dy[2] * dx
    .ed_assert(
      all(is.finite(area2)) && any(area2 != 0),
      "Noncollinear geometry not established with safe direct arithmetic"
    )
    node_map$geometry_index[p] <- as.double(seq_len(n))
    raw <- raw_edges[ef == f, , drop = FALSE]
    a <- raw$ind1
    b <- raw$ind2
    .ed_assert(all(a == floor(a) & b == floor(b) & a >= 1 & b >= 1 &
      a <= n & b <= n & a != b), "Invalid whole nonself endpoint indices")
    a <- as.integer(a)
    b <- as.integer(b)
    m <- nrow(raw)
    .ed_assert(m >= n - 1 && m <= 3 * as.double(n) - 6, "Full graph edge cardinality is invalid")
    .ed_assert(!anyDuplicated(paste(pmin(a, b), pmax(a, b), sep = ":")),
      "Duplicate unordered full edge")
    .ed_assert(
      all(raw$x1 == xx[a] & raw$y1 == yy[a] & raw$x2 == xx[b] & raw$y2 == yy[b]),
      "Raw coordinates do not match exact declared point indices"
    )
    parent <- seq_len(n)
    height <- integer(n)
    find_root <- function(i) {
      while (parent[i] != i) i <- parent[i]
      i
    }
    for (j in seq_len(m)) {
      ra <- find_root(a[j])
      rb <- find_root(b[j])
      if (ra != rb) {
        if (height[ra] < height[rb]) {
          parent[ra] <- rb
        } else {
          parent[rb] <- ra
          if (height[ra] == height[rb]) height[ra] <- height[ra] + 1L
        }
      }
    }
    .ed_assert(
      length(unique(vapply(seq_len(n), find_root, integer(1)))) == 1L,
      "Full graph is disconnected"
    )
    left <- p[a]
    right <- p[b]
    swap <- nodes[[orientation_rank]][left] > nodes[[orientation_rank]][right]
    from <- ifelse(swap, right, left)
    to <- ifelse(swap, left, right)
    distance <- sqrt((nodes[[x]][from] - nodes[[x]][to])^2 +
      (nodes[[y]][from] - nodes[[y]][to])^2)
    .ed_assert(all(is.finite(distance) & distance > 0), "Edge lengths are nonpositive or nonfinite")
    out <- raw[keys]
    out$from_id <- nodes[[id]][from]
    out$to_id <- nodes[[id]][to]
    out$from_geometry_index <- node_map$geometry_index[from]
    out$to_geometry_index <- node_map$geometry_index[to]
    out$from_orientation_rank <- nodes[[orientation_rank]][from]
    out$to_orientation_rank <- nodes[[orientation_rank]][to]
    out$x1 <- nodes[[x]][from]
    out$y1 <- nodes[[y]][from]
    out$x2 <- nodes[[x]][to]
    out$y2 <- nodes[[y]][to]
    out$distance <- distance
    out$analysis_edge <- nodes[[eligible]][from] & nodes[[eligible]][to]
    parts[[f]] <- out
    summary[f, c("n_nodes", "n_geometry", "n_eligible", "n_full_edges", "n_analysis_edges")] <-
      list(length(rows), n, sum(nodes[[eligible]][rows]), m, sum(out$analysis_edge))
  }
  if (length(parts)) {
    edges <- do.call(rbind, parts)
  } else {
    edges <- raw_edges[FALSE, keys, drop = FALSE]
    edges$from_id <- edges$to_id <- character()
    for (field in c(
      "from_geometry_index", "to_geometry_index", "from_orientation_rank",
      "to_orientation_rank", "x1", "y1", "x2", "y2", "distance"
    )) {
      edges[[field]] <- numeric()
    }
    edges$analysis_edge <- logical()
  }
  ordered <- function(z, fields) {
    v <- lapply(z[fields], function(x) if (is.character(x)) enc2utf8(x) else x)
    z <- z[do.call(order, c(unname(v), list(method = "radix"))), , drop = FALSE]
    rownames(z) <- NULL
    z
  }
  edges <- ordered(edges, c(keys, "from_orientation_rank", "to_orientation_rank"))
  edges$edge_row <- as.double(seq_len(nrow(edges)))
  .ed_assert(
    !length(caps) || nrow(edges) <= floor(.Machine$integer.max / length(caps)),
    "Cap-flag matrix exceeds integer capacity"
  )
  flags <- matrix(FALSE, nrow(edges), length(caps), dimnames = list(NULL, names(caps)))
  for (j in seq_along(caps)) flags[, j] <- edges$distance <= caps[j]
  list(
    schema_version = "0.1.0", nodes = ordered(node_map, c(keys, point_order)),
    full_edges = edges, analysis_edge_rows = which(edges$analysis_edge),
    cap_flags = flags, caps = caps, frames = ordered(summary, keys),
    provenance = list(
      geometry_source = "SUPPLIED_EDGES_VALIDATED_NOT_CONSTRUCTED",
      construction_performed = FALSE, native_execution = FALSE,
      coordinate_unit = coordinate_unit, point_order = "EXPLICIT_NUMERIC_ORDER",
      orientation = "EXPLICIT_NUMERIC_RANK", edge_order = edge_order,
      geometry_authentication = "NOT_ESTABLISHED_BY_VALIDATION"
    )
  )
}

.ed_window <- function(x, y) {
  .ed_assert(.ed_number(x) && .ed_number(y) && length(x) == length(y) &&
    length(x) >= 3L, "Window requires at least three finite coordinate pairs")
  xr <- range(x)
  yr <- range(y)
  span <- max(diff(xr), diff(yr))
  .ed_assert(is.finite(span), "Coordinate span cannot be represented safely")
  padding <- max(1e-6, span * 1e-10)
  bounds <- c(xr[1] - padding, xr[2] + padding, yr[1] - padding, yr[2] + padding)
  .ed_assert(
    all(is.finite(bounds)) && bounds[1] < bounds[2] && bounds[3] < bounds[4] &&
      all(x >= bounds[1] & x <= bounds[2] & y >= bounds[3] & y <= bounds[4]),
    "Padded window cannot be represented safely"
  )
  list(
    bounds = unname(bounds), padding = padding, span = span,
    policy = "MAX_1E_MINUS6_OR_SPAN_TIMES_1E_MINUS10", transformed = FALSE
  )
}
