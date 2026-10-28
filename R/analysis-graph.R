# Delaunay neighbour-type counts with an inclusive edge-length cut.

# Undirected Delaunay edges (point indices, ind1 < ind2) from GEOS through sf.
.an_geos_edges <- function(x, y) {
  .an_assert(requireNamespace("sf", quietly = TRUE), "engine 'geos' requires the sf package")
  n <- length(x)
  geometry <- sf::st_sfc(sf::st_multipoint(cbind(x, y)))
  tri <- sf::st_triangulate(geometry, dTolerance = 0, bOnlyEdges = TRUE)
  cc <- sf::st_coordinates(tri)
  .an_assert(nrow(cc) > 0L && all(c("X", "Y", "L1") %in% colnames(cc)),
             "GEOS returned no edges")
  # GEOS returns input coordinates unchanged; map them back exactly.
  key <- complex(real = x, imaginary = y)
  id <- match(complex(real = cc[, "X"], imaginary = cc[, "Y"]), key)
  .an_assert(!anyNA(id), "GEOS edge vertex not found among the input points")
  line <- cc[, "L1"]
  .an_assert(all(tabulate(line) == 2L), "GEOS edges must have exactly two vertices")
  first <- !duplicated(line)
  a <- id[first][order(line[first])]
  b <- id[!first][order(line[!first])]
  .an_assert(all(a != b), "Self edge in triangulation")
  edges <- cbind(pmin(a, b), pmax(a, b))
  .an_assert(!anyDuplicated(edges), "Duplicate edge in triangulation")
  .an_assert(nrow(edges) <= 3 * n - 3, "Edge count exceeds the planar bound")
  edges[order(edges[, 1L], edges[, 2L]), , drop = FALSE]
}

# Undirected Delaunay edges from deldir::deldir() through the constructor of
# BuildExactDelaunayEdges (slow for large n).
.an_deldir_edges <- function(x, y, backend_contract, eps) {
  built <- .ed_build_geometry(x, y, backend_contract, eps, "auto")
  e <- built$raw_edges
  edges <- cbind(pmin(e$ind1, e$ind2), pmax(e$ind1, e$ind2))
  storage.mode(edges) <- "integer"
  .an_assert(!anyDuplicated(edges), "Duplicate edge in triangulation")
  edges[order(edges[, 1L], edges[, 2L]), , drop = FALSE]
}

#' Count Neighbour Types over a Delaunay Graph with an Edge-Length Cut
#'
#' Triangulates the cell centroids of one section (Delaunay), removes edges
#' longer than `max_edge`, and counts for every cell how many of its remaining
#' neighbours fall in each declared type group. This is the per-cell
#' neighbourhood composition input of cellular-neighbourhood analyses.
#'
#' Edge length is computed with the C library `hypot()` (via [Mod()]) on the
#' double coordinates and compared inclusively (`<= max_edge`), as
#' `numpy.hypot` does. In general position the Delaunay triangulation is
#' unique, so every correct engine gives the same edges; with four or more
#' co-circular points engines may choose different diagonals. Duplicate
#' coordinates are refused by default; `duplicates = "isolate"` keeps the
#' first occurrence as the graph vertex and gives later copies no neighbours
#' (as Qhull's coplanar-point handling does).
#'
#' Engines: `"geos"` (default) uses GEOS through \pkg{sf}
#' (`st_triangulate(..., bOnlyEdges = TRUE)`); input coordinates are mapped
#' back to cells exactly. `"deldir"` uses `deldir::deldir()` as
#' [BuildExactDelaunayEdges()] does; its run time grows roughly quadratically
#' with the number of cells, so it is meant for cross-checks on small sections.
#'
#' @param cells Cell table of one section.
#' @param x,y,type Column names of the coordinates and cell type.
#' @param levels Named list of type groups (group name to cell types) or a
#'   character vector (each type its own group). Every cell type must belong
#'   to exactly one group. The order defines the count columns.
#' @param max_edge Inclusive maximum edge length (same unit as `x`, `y`);
#'   `Inf` keeps all edges.
#' @param engine `"geos"` or `"deldir"`.
#' @param duplicates `"error"` or `"isolate"`.
#' @param backend_contract Deprecated and ignored (see
#'   [BuildExactDelaunayEdges()]).
#' @param eps Tolerance passed to the `"deldir"` engine.
#' @param index_base Base of the integer `type_index` column (`1` or `0`).
#' @return A data frame with one row per cell, in input order: `type_group`,
#'   `type_index`, `x`, `y`, `degree` and one integer count column per group.
#'   Attributes `edges` (kept undirected edges), `full_edges` (all Delaunay
#'   edges) and `engine`.
#' @examples
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   set.seed(1)
#'   cells <- data.frame(x = runif(60, 0, 100), y = runif(60, 0, 100),
#'                       type = sample(c("a", "b", "c"), 60, replace = TRUE))
#'   out <- NeighbourTypeCounts(cells, levels = list(A = "a", BC = c("b", "c")),
#'                              max_edge = 20)
#'   head(out)
#'   attr(out, "edges")
#' }
#' @export
NeighbourTypeCounts <- function(cells, x = "x", y = "y", type = "type", levels,
                                max_edge = Inf, engine = c("geos", "deldir"),
                                duplicates = c("error", "isolate"),
                                backend_contract = NULL, eps = 1e-9, index_base = 1L) {
  engine <- match.arg(engine)
  duplicates <- match.arg(duplicates)
  .an_assert(all(vapply(list(x, y, type), .an_name, logical(1))), "Invalid columns")
  .an_require(cells, c(x, y, type), "cells")
  .an_assert(is.numeric(max_edge) && length(max_edge) == 1L && !is.na(max_edge) &&
               max_edge > 0, "max_edge must be one positive number")
  .an_assert(index_base %in% c(0, 1), "index_base must be 0 or 1")
  groups <- .an_sets(levels, "levels")
  members <- unlist(groups, use.names = FALSE)
  .an_assert(!anyDuplicated(members), "A cell type belongs to several groups")
  .an_assert(!any(names(groups) %in% c("type_group", "type_index", "x", "y", "degree")),
             "Group names collide with output columns")
  map <- stats::setNames(rep(seq_along(groups), lengths(groups)), members)
  lab <- as.character(cells[[type]])
  .an_assert(!anyNA(lab) && all(lab %in% members), "Cell types outside the declared groups")
  t <- unname(map[lab])
  xx <- as.numeric(cells[[x]])
  yy <- as.numeric(cells[[y]])
  .an_assert(all(is.finite(xx) & is.finite(yy)), "Coordinates must be finite")
  n <- length(xx)
  k <- length(groups)
  .an_assert(n >= 3L, "At least three cells are required")
  key <- complex(real = xx, imaginary = yy)
  dup <- duplicated(key)
  .an_assert(duplicates == "isolate" || !any(dup), "Duplicate cell coordinates")
  vertices <- which(!dup)
  .an_assert(length(vertices) >= 3L, "At least three distinct points are required")
  edges <- if (engine == "geos") {
    .an_geos_edges(xx[vertices], yy[vertices])
  } else {
    .an_deldir_edges(xx[vertices], yy[vertices], backend_contract, eps)
  }
  edges <- matrix(vertices[edges], ncol = 2L)
  full <- nrow(edges)
  len <- Mod(complex(real = xx[edges[, 1L]] - xx[edges[, 2L]],
                     imaginary = yy[edges[, 1L]] - yy[edges[, 2L]]))
  edges <- edges[len <= max_edge, , drop = FALSE]
  i <- edges[, 1L]
  j <- edges[, 2L]
  bins <- tabulate((c(i, j) - 1) * k + c(t[j], t[i]), nbins = n * k)
  counts <- matrix(as.integer(bins), nrow = n, ncol = k, byrow = TRUE)
  out <- data.frame(type_group = names(groups)[t], type_index = as.integer(t - 1L + index_base),
                    x = xx, y = yy, degree = as.integer(rowSums(counts)),
                    stringsAsFactors = FALSE)
  counts <- as.data.frame(counts)
  names(counts) <- names(groups)
  out <- cbind(out, counts)
  attr(out, "edges") <- nrow(edges)
  attr(out, "full_edges") <- full
  attr(out, "engine") <- engine
  out
}
