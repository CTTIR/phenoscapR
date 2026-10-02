# Validate native row indices and planned long-form output before search/allocation.
.radius_count_limits <- function(n_nodes, n_frames, n_queries, n_radii, n_sets) {
  sizes <- c(n_nodes, n_frames, n_queries, n_radii, n_sets)
  limit <- as.double(.Machine$integer.max)
  if (!is.numeric(sizes) || any(!is.finite(sizes)) || any(sizes < 0) ||
    any(sizes != floor(sizes)) || any(sizes > limit) ||
    n_queries > n_nodes || n_radii < 1 || n_sets < 1) {
    stop("Native integer index limit or invalid planned size", call. = FALSE)
  }
  # Successive integer quotients avoid an overflowing intermediate product.
  maximum_queries <- floor(floor(limit / n_sets) / n_radii)
  if (n_queries > maximum_queries) {
    stop("Planned radius-set output exceeds integer row limit", call. = FALSE)
  }
  invisible(TRUE)
}

.radius_native_keys <- function(native, library_root) {
  prefix <- paste0(sub("/+$", "", library_root), "/")
  if (!is.character(native) || anyNA(native) ||
    !all(startsWith(native, prefix))) {
    stop("Invalid native fingerprint paths", call. = FALSE)
  }
  keys <- substring(native, nchar(prefix) + 1L)
  if (any(!nzchar(keys)) || anyDuplicated(keys)) {
    stop("Duplicate or empty native fingerprint key", call. = FALSE)
  }
  keys
}

#' Count Reference Sets Within Explicit Euclidean Radii
#'
#' Counts reference neighbors and overlapping reference sets for each query ID
#' within an explicitly declared coordinate frame. Query batching always searches
#' the complete reference population of that frame. No population, coordinate
#' transformation, graph, tissue area or scientific threshold is inferred.
#'
#' @param nodes Data frame containing node keys, coordinates and memberships.
#' @param frames Data frame declaring unique group/frame keys and coordinate
#'   units, including desired empty frames.
#' @param groups Nonempty character vector naming distinct group columns shared
#'   by both tables. Include independent sample keys as appropriate.
#' @param frame Character name of the shared coordinate-frame column.
#' @param id Character name of the node ID column in `nodes`.
#' @param x,y Character names of finite numeric coordinate columns in `nodes`.
#' @param query,reference Character names of nonmissing logical query and
#'   reference memberships in `nodes`. Memberships may overlap.
#' @param sets Nonempty character vector naming distinct nonmissing logical
#'   reference-set columns in `nodes`. Sets may overlap. Membership outside
#'   `reference` does not expand the reference population.
#' @param unit_column Character name of the units column in `frames`.
#' @param radius_unit One of `"nm"`, `"um"`, `"mm"`, `"cm"`, or `"m"`. Every
#'   declared frame must use this unit; no unit conversion is performed.
#' @param radii Distinct positive finite numeric output radii in `radius_unit`.
#' @param search_radius Required finite numeric search envelope, at least every
#'   requested radius. This is part of the numerical contract, not a default.
#' @param chunk_size Positive integer number of queries per native search batch.
#'
#' @details
#' Keys and IDs must be dimensionless, nonmissing, nonblank character vectors.
#' IDs must be unique within the complete group/frame key, but may repeat across
#' independent frames. Factors and numeric IDs are not coerced. Selected roles
#' within each input table must be distinct. Unknown frames, duplicate keys,
#' missing memberships and malformed inputs raise errors. Extra node columns are
#' ignored; a tile column does not partition a frame unless selected as a key.
#'
#' Searches use [dbscan::frNN()] with explicit query mode, `search = "kdtree"`,
#' `approx = 0` and `sort = FALSE`, without a fallback. Returned distances are
#' filtered inclusively using `distance <= radius`. Self exclusion compares IDs
#' within the complete frame key. Distinct coincident IDs remain neighbors.
#'
#' Exact search mode does not imply arbitrary-precision real-number geometry.
#' Binary64 boundary decisions can depend on `search_radius`: the distance from
#' `(0, 0)` to `(3 + 2 * .Machine$double.eps, 4)` is excluded by a native search
#' at 5, but a search at 6 returns a distance rounded to 5, which passes the
#' output-radius filter at 5. Keep the search envelope fixed when requesting
#' different subsets of radii or comparing runs. No padding, recentering,
#' coordinate rounding or squared-distance replacement is applied.
#'
#' Squared output and search radii must be finite and at least
#' `.Machine$double.xmin`. Absolute coordinates must not exceed
#' `sqrt(.Machine$double.xmax) / 4`; frame spans must support finite squared
#' arithmetic. Unsupported extreme inputs and integer indexing/output sizes
#' raise errors. These conservative guards do not remove ordinary rounding.
#' Chunking bounds each native query batch, not dense-neighborhood memory within
#' a batch or total output size. This function does not authenticate input
#' coordinates or historical geometry and does not infer fractions or weights.
#'
#' @return A list with `schema_version = "1.0.0"` and:
#' \itemize{
#'   \item `frame_summary`: one row per declared frame, coordinate units,
#'   `n_nodes`, `n_queries`, `n_references`, and `status` (`NO_QUERIES`,
#'   `EMPTY_REFERENCE`, or `DEFINED`).
#'   \item `query_counts`: every query by requested radius, including zero
#'   neighbors, with `n_reference_neighbors` and `status` (`EMPTY_REFERENCE`
#'   or `DEFINED`). A nonempty reference universe containing only the query
#'   itself has status `DEFINED` and zero eligible neighbors.
#'   \item `set_counts`: every query by radius by set, with integer-valued double
#'   `count` and matching status. Overlapping sets need not partition neighbors.
#'   \item `backend`: installed version, search settings and radius/unit,
#'   DESCRIPTION, R-wrapper and native-library SHA-256 fingerprints. These
#'   identify the current runtime and do not authenticate a historical backend.
#' }
#' Keys and IDs are retained. Tables are sorted by keys, IDs, radii and set names
#' as applicable. Empty inputs return typed empty tables; inputs are not modified.
#'
#' @examples
#' nodes <- data.frame(
#'   sample = "sample-1", frame = "image-1", id = c("a", "b", "c"),
#'   x = c(0, 0, 3), y = c(0, 0, 4),
#'   query = c(TRUE, FALSE, FALSE), reference = TRUE,
#'   set_a = c(FALSE, TRUE, TRUE), set_b = c(FALSE, TRUE, FALSE)
#' )
#' frames <- data.frame(sample = "sample-1", frame = "image-1", unit = "um")
#' CountRadiusSets(nodes, frames, "sample", "frame", "id", "x", "y",
#'   "query", "reference", c("set_a", "set_b"), "unit", "um",
#'   radii = c(1, 5), search_radius = 5
#' )
#' @export
CountRadiusSets <- function(nodes, frames, groups, frame, id, x, y, query,
                            reference, sets, unit_column, radius_unit, radii,
                            search_radius, chunk_size = 1000L) {
  require_ok <- function(ok, message) if (!isTRUE(ok)) stop(message, call. = FALSE)
  names_ok <- function(z) {
    is.character(z) && is.null(dim(z)) && length(z) > 0L &&
      !anyNA(z) && all(nzchar(trimws(z))) && !anyDuplicated(z)
  }
  scalar <- function(z) names_ok(z) && length(z) == 1L
  require_ok(names_ok(groups) && names_ok(sets), "groups and sets need distinct names")
  require_ok(all(vapply(
    list(frame, id, x, y, query, reference, unit_column),
    scalar, logical(1)
  )), "Selected roles need scalar names")
  keys <- c(groups, frame)
  require_ok(names_ok(c(keys, id, x, y, query, reference, sets)) &&
    names_ok(c(keys, unit_column)), "Selected roles collide")
  outputs <- c(
    "radius", "n_reference_neighbors", "set", "count", "status",
    "n_nodes", "n_queries", "n_references", "coordinate_unit"
  )
  require_ok(!any(c(keys, id) %in% outputs), "Keys collide with output fields")
  table <- function(z, required) {
    require_ok(is.data.frame(z) && !anyDuplicated(names(z)) &&
      all(required %in% names(z)), "Invalid table schema")
    as.data.frame(z, stringsAsFactors = FALSE)
  }
  nodes <- table(nodes, c(keys, id, x, y, query, reference, sets))
  frames <- table(frames, c(keys, unit_column))
  text <- function(z, cols) {
    for (column in cols) {
      require_ok(
        is.character(z[[column]]) && is.null(dim(z[[column]])) &&
          !anyNA(z[[column]]) && all(nzchar(trimws(z[[column]]))),
        "Keys and units must be nonmissing character vectors"
      )
    }
  }
  text(nodes, c(keys, id))
  text(frames, c(keys, unit_column))
  require_ok(scalar(radius_unit) && radius_unit %in% c("nm", "um", "mm", "cm", "m") &&
    all(frames[[unit_column]] == radius_unit),
    "Coordinate and radius units differ or are unsupported")
  numeric_vector <- function(z) {
    is.numeric(z) && !is.complex(z) && is.null(dim(z)) &&
      all(is.finite(z))
  }
  require_ok(
    numeric_vector(nodes[[x]]) && numeric_vector(nodes[[y]]),
    "Coordinates must be finite real vectors"
  )
  for (column in c(query, reference, sets)) {
    require_ok(
      is.logical(nodes[[column]]) &&
        is.null(dim(nodes[[column]])) && !anyNA(nodes[[column]]),
      "Memberships must be logical without missingness"
    )
  }
  require_ok(numeric_vector(radii) && length(radii) > 0L && all(radii > 0) &&
    !anyDuplicated(radii), "Radii must be distinct positive finite values")
  require_ok(
    numeric_vector(chunk_size) && length(chunk_size) == 1L &&
      chunk_size >= 1 && chunk_size <= .Machine$integer.max && chunk_size == floor(chunk_size),
    "Invalid chunk size"
  )
  require_ok(numeric_vector(search_radius) && length(search_radius) == 1L &&
    search_radius >= max(radii), "search_radius must be finite and at least every requested radius")
  radii <- sort(as.double(radii))
  require_ok(
    all(is.finite(c(radii, search_radius)^2) &
      c(radii, search_radius)^2 >= .Machine$double.xmin),
    "Unsafe squared radius arithmetic"
  )
  # This conservative limit avoids native squared-coordinate and bound overflow.
  coordinate_limit <- sqrt(.Machine$double.xmax) / 4
  require_ok(all(abs(nodes[[x]]) <= coordinate_limit) &&
    all(abs(nodes[[y]]) <= coordinate_limit), "Unsafe coordinate magnitude")
  encode <- function(z, cols) {
    if (!nrow(z)) {
      return(character())
    }
    parts <- lapply(z[cols], function(v) {
      v <- enc2utf8(v)
      paste0(nchar(v, type = "bytes"), ":", v)
    })
    do.call(paste0, unname(parts))
  }
  .radius_count_limits(nrow(nodes), nrow(frames), sum(nodes[[query]]), length(radii), length(sets))
  fk <- encode(frames, keys)
  nk <- encode(nodes, c(keys, id))
  require_ok(!anyDuplicated(fk) && !anyDuplicated(nk), "Duplicate frame or node key")
  membership <- match(encode(nodes, keys), fk)
  require_ok(!anyNA(membership), "Unknown coordinate frame")
  require_ok(requireNamespace("dbscan", quietly = TRUE) &&
    requireNamespace("digest", quietly = TRUE), "Exact dbscan and digest dependencies required")
  needed <- c("x", "eps", "query", "sort", "search", "approx")
  require_ok(all(needed %in% names(formals(dbscan::frNN))), "Unsupported dbscan query API")
  checksum <- function(f) digest::digest(file = f, algo = "sha256")
  library_root <- system.file("libs", package = "dbscan")
  native <- list.files(library_root,
    recursive = TRUE,
    full.names = TRUE, pattern = "\\.(so|dll|dylib)$"
  )
  require_ok(length(native) > 0L, "Missing native dbscan fingerprint")
  native_keys <- .radius_native_keys(native, library_root)
  backend <- list(
    name = "dbscan::frNN", version = as.character(utils::packageVersion("dbscan")),
    search = "kdtree", approx = 0, search_radius = search_radius, radius_unit = radius_unit,
    description_sha256 = checksum(system.file("DESCRIPTION", package = "dbscan")),
    function_sha256 = digest::digest(paste(deparse(dbscan::frNN), collapse = "\n"),
      algo = "sha256", serialize = FALSE
    ),
    native_sha256 = stats::setNames(vapply(native, checksum, character(1)), native_keys),
    authority = "CURRENT_INSTALLED_BACKEND_NOT_HISTORICAL_AUTHENTICATION"
  )
  summary <- frames[keys]
  summary$coordinate_unit <- frames[[unit_column]]
  summary$n_nodes <- as.double(tabulate(membership, nbins = nrow(frames)))
  summary$n_queries <- as.double(tabulate(membership[nodes[[query]]], nbins = nrow(frames)))
  summary$n_references <- as.double(tabulate(membership[nodes[[reference]]], nbins = nrow(frames)))
  summary$status <- as.character(ifelse(summary$n_queries == 0, "NO_QUERIES",
    ifelse(summary$n_references == 0, "EMPTY_REFERENCE", "DEFINED")
  ))
  empty <- nodes[FALSE, c(keys, id), drop = FALSE]
  empty$radius <- numeric()
  empty$n_reference_neighbors <- double()
  empty$status <- character()
  queries <- list()
  set_results <- list()
  qi <- 0L
  si <- 0L
  partitions <- split(seq_len(nrow(nodes)), factor(membership, levels = seq_len(nrow(frames))))
  for (f in seq_len(nrow(frames))) {
    rows <- partitions[[f]]
    q <- rows[nodes[[query]][rows]]
    ref <- rows[nodes[[reference]][rows]]
    if (!length(q)) next
    coords <- cbind(nodes[[x]][rows], nodes[[y]][rows])
    spans <- apply(coords, 2L, function(v) max(v) - min(v))
    require_ok(all(is.finite(spans)) && is.finite(sum(spans^2)), "Unsafe distance arithmetic")
    for (start in seq.int(1L, length(q), by = as.integer(chunk_size))) {
      qq <- q[start:min(length(q), as.double(start) + chunk_size - 1)]
      if (length(ref)) {
        nn <- dbscan::frNN(cbind(nodes[[x]][ref], nodes[[y]][ref]),
          eps = search_radius,
          query = cbind(nodes[[x]][qq], nodes[[y]][qq]), sort = FALSE, search = "kdtree", approx = 0
        )
        require_ok(
          length(nn$id) == length(qq) && length(nn$dist) == length(qq),
          "Backend query cardinality differs"
        )
      } else {
        nn <- list(id = rep(list(integer()), length(qq)), dist = rep(list(numeric()), length(qq)))
      }
      for (j in seq_along(qq)) {
        found <- nn$id[[j]]
        distance <- nn$dist[[j]]
        require_ok(length(found) == length(distance) && !anyNA(found) &&
          all(found >= 1L & found <= length(ref)) && !anyDuplicated(found) &&
          all(is.finite(distance) & distance >= 0), "Invalid backend neighbor output")
        neighbor <- ref[found]
        keep <- nodes[[id]][neighbor] != nodes[[id]][qq[j]]
        neighbor <- neighbor[keep]
        distance <- distance[keep]
        for (radius in radii) {
          selected <- neighbor[distance <= radius]
          row <- nodes[qq[j], c(keys, id), drop = FALSE]
          row$radius <- radius
          row$n_reference_neighbors <- as.double(length(selected))
          row$status <- if (length(ref)) "DEFINED" else "EMPTY_REFERENCE"
          qi <- qi + 1L
          queries[[qi]] <- row
          sr <- row[rep(1L, length(sets)), c(keys, id, "radius"), drop = FALSE]
          sr$set <- sets
          sr$count <- vapply(sets,
            function(column) as.double(sum(nodes[[column]][selected])), double(1))
          sr$status <- row$status
          si <- si + 1L
          set_results[[si]] <- sr
        }
      }
    }
  }
  query_out <- if (length(queries)) do.call(rbind, queries) else empty
  empty_sets <- empty[c(keys, id, "radius")]
  empty_sets$set <- character()
  empty_sets$count <- double()
  empty_sets$status <- character()
  set_out <- if (length(set_results)) do.call(rbind, set_results) else empty_sets
  ordered <- function(z, fields) {
    sort_fields <- lapply(z[fields], function(column) {
      if (is.character(column)) enc2utf8(column) else column
    })
    z <- z[do.call(order, c(unname(sort_fields), list(method = "radix"))), , drop = FALSE]
    rownames(z) <- NULL
    z
  }
  list(
    schema_version = "1.0.0", frame_summary = ordered(summary, keys),
    query_counts = ordered(query_out, c(keys, id, "radius")),
    set_counts = ordered(set_out, c(keys, id, "radius", "set")), backend = backend
  )
}
