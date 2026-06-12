# ===========================================================================
# Internal spatial-search engine
# ---------------------------------------------------------------------------
# Every radius- and k-nearest-neighbour query in the package routes through
# these helpers. They use a kd-tree (RANN) when it is installed and fall back
# to an exact, memory-bounded base-R computation otherwise. The fallback is
# chunked so it never materialises the full O(n^2) distance matrix, which would
# exhaust memory on realistic (10^5-10^6 cell) tissues.
# ===========================================================================

#' Fixed-radius neighbour search (symmetric)
#'
#' For each point, the indices of and distances to all *other* points within
#' `radius`. Returns `list(idx = <list of integer>, dist = <list of numeric>)`,
#' self-matches removed.
#' @noRd
.radius_neighbours <- function(coords, radius) {
  n <- nrow(coords)
  if (n < 2L) return(list(idx = vector("list", n), dist = vector("list", n)))

  if (requireNamespace("RANN", quietly = TRUE)) {
    k <- min(n, 64L)
    repeat {
      res <- RANN::nn2(coords, coords, k = k,
                       searchtype = "radius", radius = radius)
      # A row is saturated (possibly truncated) if its last slot is filled.
      if (!(k < n && any(res$nn.idx[, k] != 0L))) break
      k <- min(n, k * 4L)
    }
    idx <- res$nn.idx
    dst <- res$nn.dists
    out_idx <- vector("list", n)
    out_dst <- vector("list", n)
    for (i in seq_len(n)) {
      keep <- idx[i, ] != 0L & idx[i, ] != i
      out_idx[[i]] <- idx[i, keep]
      out_dst[[i]] <- dst[i, keep]
    }
    return(list(idx = out_idx, dist = out_dst))
  }

  .radius_neighbours_bruteforce(coords, radius)
}

#' Exact, memory-bounded fallback for [.radius_neighbours]
#' @noRd
.radius_neighbours_bruteforce <- function(coords, radius) {
  n <- nrow(coords)
  out_idx <- vector("list", n)
  out_dst <- vector("list", n)
  block <- 2048L
  r2 <- radius * radius
  cx <- coords[, 1L]
  cy <- coords[, 2L]
  for (start in seq.int(1L, n, by = block)) {
    end <- min(start + block - 1L, n)
    qi <- start:end
    dx <- outer(cx[qi], cx, "-")
    dy <- outer(cy[qi], cy, "-")
    d2 <- dx * dx + dy * dy
    for (a in seq_along(qi)) {
      i <- qi[a]
      within <- which(d2[a, ] <= r2)
      within <- within[within != i]
      out_idx[[i]] <- within
      out_dst[[i]] <- sqrt(d2[a, within])
    }
  }
  list(idx = out_idx, dist = out_dst)
}

#' Count points of `data` within `radius` of each `query` point
#'
#' Cross-set fixed-radius count, excluding exact (zero-distance) coincidences
#' so a query point never counts its own copy in `data`.
#' @noRd
.cross_radius_count <- function(query, data, radius) {
  nq <- nrow(query)
  nd <- nrow(data)
  if (nd == 0L || nq == 0L) return(integer(nq))

  if (requireNamespace("RANN", quietly = TRUE)) {
    k <- min(nd, 64L)
    repeat {
      res <- RANN::nn2(data, query, k = k,
                       searchtype = "radius", radius = radius)
      if (!(k < nd && any(res$nn.idx[, k] != 0L))) break
      k <- min(nd, k * 4L)
    }
    return(as.integer(rowSums(res$nn.idx != 0L & res$nn.dists > 0)))
  }

  out <- integer(nq)
  block <- 2048L
  r2 <- radius * radius
  for (start in seq.int(1L, nq, by = block)) {
    end <- min(start + block - 1L, nq)
    qi <- start:end
    dx <- outer(query[qi, 1L], data[, 1L], "-")
    dy <- outer(query[qi, 2L], data[, 2L], "-")
    d2 <- dx * dx + dy * dy
    out[qi] <- rowSums(d2 <= r2 & d2 > 0)
  }
  out
}

#' Mean distance to the `k` nearest points of `data` for each `query`
#'
#' When `drop_self` is `TRUE`, the closest match (the query point's own copy in
#' `data`, at distance 0) is discarded before averaging.
#' @noRd
.knn_mean_dist <- function(query, data, k, drop_self) {
  nq <- nrow(query)
  nd <- nrow(data)
  if (nq == 0L) return(numeric(0))
  if (nd == 0L) return(rep(NA_real_, nq))

  kk <- if (drop_self) k + 1L else k
  kk <- min(kk, nd)

  if (requireNamespace("RANN", quietly = TRUE)) {
    d <- RANN::nn2(data, query, k = kk)$nn.dists
  } else {
    d <- matrix(NA_real_, nq, kk)
    block <- 2048L
    for (start in seq.int(1L, nq, by = block)) {
      end <- min(start + block - 1L, nq)
      qi <- start:end
      dx <- outer(query[qi, 1L], data[, 1L], "-")
      dy <- outer(query[qi, 2L], data[, 2L], "-")
      dd <- sqrt(dx * dx + dy * dy)
      d[qi, ] <- t(apply(dd, 1L, function(r) sort(r)[seq_len(kk)]))
    }
  }

  cols <- if (drop_self) seq.int(2L, kk) else seq_len(kk)
  if (length(cols) == 0L) return(rep(NA_real_, nq))
  rowMeans(d[, cols, drop = FALSE])
}

#' Compute Nearest Neighbour Distances
#'
#' For each cell, computes the distance to the nearest neighbouring cell,
#' optionally restricted to specific phenotypes.
#'
#' @param dt A `data.table` with columns `x` and `y`.
#' @param target_phenotype Character string or `NULL`. If provided, distances
#'   are computed only to cells of this phenotype. Requires a `phenotype`
#'   column.
#' @param k Integer. Number of nearest neighbours to consider. Default `1`.
#'
#' @return The input `data.table` with an added `nn_distance` column
#'   (mean distance to the `k` nearest neighbours).
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:20,
#'   x = runif(20, 0, 100), y = runif(20, 0, 100)
#' )
#' result <- nearest_neighbours(dt, k = 3)
#' head(result[, .(cell_id, nn_distance)])
#'
#' @export
nearest_neighbours <- function(dt, target_phenotype = NULL, k = 1L) {
  dt <- data.table::copy(dt)
  k <- as.integer(k)

  samples <- unique(dt$sample_id)
  result_list <- lapply(samples, function(sid) {
    sub <- dt[dt$sample_id == sid, ]
    .nn_for_sample(sub, target_phenotype, k)
  })

  data.table::rbindlist(result_list)
}

#' Nearest neighbour computation for a single sample
#' @noRd
.nn_for_sample <- function(dt, target_phenotype, k) {
  coords_from <- as.matrix(dt[, c("x", "y")])

  if (!is.null(target_phenotype)) {
    if (!"phenotype" %in% names(dt)) {
      stop("'phenotype' column required when target_phenotype is set.",
           call. = FALSE)
    }
    target_idx <- which(dt$phenotype == target_phenotype)
    if (length(target_idx) == 0L) {
      dt[, nn_distance := NA_real_]
      return(dt)
    }
    coords_to <- coords_from[target_idx, , drop = FALSE]
    nn_dist <- .knn_mean_dist(coords_from, coords_to, k, drop_self = FALSE)
  } else {
    nn_dist <- .knn_mean_dist(coords_from, coords_from, k, drop_self = TRUE)
  }

  dt[, nn_distance := nn_dist]
  dt
}

#' Compute Cell Density
#'
#' Estimates the local cell density around each cell using a circular
#' neighbourhood of a given radius.
#'
#' @param dt A `data.table` with columns `x` and `y`.
#' @param radius Numeric. Radius of the neighbourhood (in coordinate units).
#' @param target_phenotype Character string or `NULL`. If provided, only
#'   cells of this phenotype are counted in the neighbourhood.
#'
#' @return The input `data.table` with an added `density` column representing
#'   the number of neighbours within the specified radius.
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:50,
#'   x = runif(50, 0, 100), y = runif(50, 0, 100)
#' )
#' result <- cell_density(dt, radius = 20)
#' head(result[, .(cell_id, density)])
#'
#' @export
cell_density <- function(dt, radius, target_phenotype = NULL) {
  dt <- data.table::copy(dt)

  samples <- unique(dt$sample_id)
  result_list <- lapply(samples, function(sid) {
    sub <- dt[dt$sample_id == sid, ]
    .density_for_sample(sub, radius, target_phenotype)
  })

  data.table::rbindlist(result_list)
}

#' Cell density for a single sample
#' @noRd
.density_for_sample <- function(dt, radius, target_phenotype) {
  coords <- as.matrix(dt[, c("x", "y")])

  if (!is.null(target_phenotype)) {
    if (!"phenotype" %in% names(dt)) {
      stop("'phenotype' column required when target_phenotype is set.",
           call. = FALSE)
    }
    target_idx <- which(dt$phenotype == target_phenotype)
    target_coords <- coords[target_idx, , drop = FALSE]
    dens <- .cross_radius_count(coords, target_coords, radius)
  } else {
    dens <- lengths(.radius_neighbours(coords, radius)$idx)
  }

  dt[, density := dens]
  dt
}

#' Spatial Interaction Matrix
#'
#' Computes a pairwise interaction matrix between phenotypes based on
#' observed versus expected neighbour frequencies within a given radius.
#'
#' @param dt A `data.table` with columns `x`, `y`, `phenotype`, and
#'   `sample_id`.
#' @param radius Numeric. Radius for defining spatial neighbourhoods.
#'
#' @return A `data.table` in long format with columns `from`, `to`,
#'   `observed`, `expected`, and `interaction_score`
#'   (log2 observed/expected). Positive values indicate spatial attraction;
#'   negative values indicate avoidance.
#'
#' @examples
#' set.seed(42)
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:100,
#'   x = runif(100, 0, 500), y = runif(100, 0, 500),
#'   phenotype = sample(c("CD3+", "CD8+", "Tumour"), 100, replace = TRUE)
#' )
#' interactions <- interaction_matrix(dt, radius = 50)
#' interactions
#'
#' @export
interaction_matrix <- function(dt, radius) {
  if (!"phenotype" %in% names(dt)) {
    stop("Column 'phenotype' not found.", call. = FALSE)
  }

  phenotypes <- sort(unique(dt$phenotype))
  n_pheno <- length(phenotypes)

  # Sample identity governs which cells can be neighbours: distances are never
  # computed across samples (different tissues), so observed and expected
  # counts are accumulated within each sample and then summed.
  samples <- if ("sample_id" %in% names(dt)) {
    unique(dt$sample_id)
  } else {
    rep("__all__", 1L)
  }
  sample_vec <- if ("sample_id" %in% names(dt)) dt$sample_id else "__all__"

  obs <- matrix(0, nrow = n_pheno, ncol = n_pheno,
                dimnames = list(phenotypes, phenotypes))
  exp_mat <- matrix(0, nrow = n_pheno, ncol = n_pheno,
                    dimnames = list(phenotypes, phenotypes))

  for (sid in samples) {
    rows <- which(sample_vec == sid)
    if (length(rows) < 2L) next
    coords <- as.matrix(dt[rows, c("x", "y")])
    pheno_vec <- dt$phenotype[rows]
    nbr <- .radius_neighbours(coords, radius)$idx

    # Vectorised neighbour tabulation: expand every (centre, neighbour) pair
    # into aligned from/to phenotype vectors and cross-tabulate once.
    lens <- lengths(nbr)
    from_ph <- rep(pheno_vec, lens)
    to_ph   <- pheno_vec[unlist(nbr, use.names = FALSE)]
    obs_s <- unclass(table(
      factor(from_ph, levels = phenotypes),
      factor(to_ph,   levels = phenotypes)
    ))
    storage.mode(obs_s) <- "double"
    obs <- obs + obs_s

    # Expected under random mixing within this sample.
    freq <- table(factor(pheno_vec, levels = phenotypes)) / length(rows)
    total_pairs_s <- sum(obs_s)
    exp_mat <- exp_mat +
      outer(as.numeric(freq), as.numeric(freq)) * total_pairs_s
  }

  # Build long-format result
  result <- data.table::data.table(
    from = rep(phenotypes, each = n_pheno),
    to = rep(phenotypes, n_pheno),
    observed = as.vector(obs),
    expected = as.vector(exp_mat)
  )
  result[, interaction_score := ifelse(
    expected > 0 & observed > 0,
    log2(observed / expected),
    0
  )]

  result
}

#' Spatial Cell Clustering
#'
#' Clusters cells based on their spatial coordinates using k-means or
#' hierarchical clustering.
#'
#' @param dt A `data.table` with columns `x` and `y`.
#' @param k Integer. Number of clusters.
#' @param method Character string. Clustering method: `"kmeans"` (default) or
#'   `"hierarchical"`.
#'
#' @return The input `data.table` with an added `cluster` column.
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:50,
#'   x = c(rnorm(25, 0, 5), rnorm(25, 50, 5)),
#'   y = c(rnorm(25, 0, 5), rnorm(25, 50, 5))
#' )
#' result <- spatial_clusters(dt, k = 2)
#' table(result$cluster)
#'
#' @export
spatial_clusters <- function(dt, k, method = c("kmeans", "hierarchical")) {
  method <- match.arg(method)
  dt <- data.table::copy(dt)

  coords <- as.matrix(dt[, c("x", "y")])

  cluster_ids <- switch(method,
    kmeans = {
      km <- kmeans(coords, centers = k, nstart = 10L)
      km$cluster
    },
    hierarchical = {
      hc <- hclust(dist(coords), method = "ward.D2")
      cutree(hc, k = k)
    }
  )

  dt[, cluster := as.character(cluster_ids)]
  dt
}

# ---------------------------------------------------------------------------
# S4-style wrappers operating on SpatialCellData objects
# ---------------------------------------------------------------------------

#' Assert an object holds a single sample
#'
#' Several spatial statistics (Ripley's K, Moran's I, quadrat analysis, the
#' pair correlation function, neighbourhood enrichment, cross nearest-neighbour
#' distance) are defined for a single point pattern in one observation window.
#' Pooling cells from several tissues would compute distances across samples and
#' produce meaningless results, so we refuse multi-sample objects.
#' @noRd
.assert_single_sample <- function(object, what = "This analysis") {
  samples <- unique(object@meta_data$sample_id)
  if (length(samples) > 1L) {
    stop(what, " operates on a single sample, but ", length(samples),
         " samples were found (", paste(utils::head(samples, 3L),
                                        collapse = ", "),
         if (length(samples) > 3L) ", ..." else "",
         "). Subset to one sample first, e.g. ",
         "object[object$sample_id == \"", samples[1L], "\", ].",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Find Nearest Neighbours (SpatialCellData)
#'
#' For each cell, computes the distance to the \code{k} nearest neighbours.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param k Integer. Number of nearest neighbours. Default \code{1}.
#' @param target Character or \code{NULL}. Restrict to a specific phenotype.
#'
#' @return An \code{\link{SpatialCellData-class}} with \code{nn_distance}
#'   added to \code{meta_data} and stored in the \code{spatial} slot.
#'
#' @examples
#' counts <- matrix(rnorm(40), nrow = 20,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(20, 0, 100), y = runif(20, 0, 100))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- FindNeighbours(obj, k = 3)
#'
#' @export
FindNeighbours <- function(object, k = 1L, target = NULL) {
  dt <- data.table::data.table(
    sample_id = object@meta_data$sample_id,
    cell_id   = object@meta_data$cell_id,
    x         = object@coords$x,
    y         = object@coords$y
  )
  if (!is.null(target) && "phenotype" %in% names(object@meta_data)) {
    dt$phenotype <- object@meta_data$phenotype
  }

  result <- nearest_neighbours(dt, target_phenotype = target, k = k)
  object@meta_data$nn_distance <- result$nn_distance
  object@spatial[["nn_distances"]] <- result$nn_distance
  object
}

#' Cell Density (SpatialCellData)
#'
#' Estimates local cell density by counting neighbours within a radius.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param radius Numeric. Radius of the neighbourhood.
#' @param target Character or \code{NULL}. Restrict to a specific phenotype.
#'
#' @return An \code{\link{SpatialCellData-class}} with \code{density}
#'   added to \code{meta_data}.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- CellDensity(obj, radius = 20)
#'
#' @export
CellDensity <- function(object, radius, target = NULL) {
  dt <- data.table::data.table(
    sample_id = object@meta_data$sample_id,
    cell_id   = object@meta_data$cell_id,
    x         = object@coords$x,
    y         = object@coords$y
  )
  if (!is.null(target) && "phenotype" %in% names(object@meta_data)) {
    dt$phenotype <- object@meta_data$phenotype
  }

  result <- cell_density(dt, radius = radius, target_phenotype = target)
  object@meta_data$density <- result$density
  object
}

#' Interaction Matrix (SpatialCellData)
#'
#' Computes pairwise spatial interaction scores between phenotypes.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param radius Numeric. Radius for defining spatial neighbourhoods.
#'
#' @return A data frame with columns \code{from}, \code{to}, \code{observed},
#'   \code{expected}, and \code{interaction_score}.
#'
#' @examples
#' set.seed(42)
#' counts <- matrix(rnorm(200), nrow = 100,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
#' meta <- data.frame(cell_id = 1:100, sample_id = "s1",
#'   phenotype = sample(c("CD3+", "CD8+", "Tumour"), 100, replace = TRUE))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' InteractionMatrix(obj, radius = 50)
#'
#' @export
InteractionMatrix <- function(object, radius) {
  dt <- data.table::data.table(
    sample_id = object@meta_data$sample_id,
    cell_id   = object@meta_data$cell_id,
    x         = object@coords$x,
    y         = object@coords$y,
    phenotype = object@meta_data$phenotype
  )
  as.data.frame(interaction_matrix(dt, radius = radius))
}

#' Spatial Clusters (SpatialCellData)
#'
#' Clusters cells based on spatial coordinates.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param k Integer. Number of clusters.
#' @param method Character. \code{"kmeans"} (default) or \code{"hierarchical"}.
#'
#' @return An \code{\link{SpatialCellData-class}} with a \code{cluster}
#'   column in \code{meta_data}.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(
#'   x = c(rnorm(25, 0, 5), rnorm(25, 50, 5)),
#'   y = c(rnorm(25, 0, 5), rnorm(25, 50, 5)))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- SpatialClusters(obj, k = 2)
#' table(Meta(obj)$cluster)
#'
#' @export
SpatialClusters <- function(object, k, method = c("kmeans", "hierarchical")) {
  method <- match.arg(method)
  coords <- as.matrix(object@coords)

  cluster_ids <- switch(method,
    kmeans = {
      km <- kmeans(coords, centers = k, nstart = 10L)
      km$cluster
    },
    hierarchical = {
      hc <- hclust(dist(coords), method = "ward.D2")
      cutree(hc, k = k)
    }
  )

  object@meta_data$cluster <- as.character(cluster_ids)
  object
}

#' Delaunay Triangulation Network
#'
#' Computes a Delaunay triangulation of cell positions and stores edges
#' in the \code{spatial} slot.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param max_edge Numeric or \code{NULL}. Maximum edge length to retain.
#'
#' @return An \code{\link{SpatialCellData-class}} with \code{delaunay_edges}
#'   stored in the \code{spatial} slot.
#'
#' @examples
#' counts <- matrix(rnorm(40), nrow = 20,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(20, 0, 100), y = runif(20, 0, 100))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- DelaunayNetwork(obj, max_edge = 30)
#'
#' @export
DelaunayNetwork <- function(object, max_edge = NULL) {
  xy <- as.matrix(object@coords)
  n <- nrow(xy)
  if (n < 3L) stop("Need at least 3 cells for triangulation.", call. = FALSE)

  edges <- .delaunay_edges(xy)
  edges$distance <- sqrt((xy[edges$from, 1L] - xy[edges$to, 1L])^2 +
                         (xy[edges$from, 2L] - xy[edges$to, 2L])^2)

  if (!is.null(max_edge)) {
    edges <- edges[edges$distance <= max_edge, , drop = FALSE]
    rownames(edges) <- NULL
  }

  object@spatial[["delaunay_edges"]] <- edges
  object
}

#' Delaunay edge list for a set of 2-D points
#'
#' Uses the \pkg{deldir} package for a true Delaunay triangulation when it is
#' available. Otherwise falls back to a k-nearest-neighbour graph, which
#' approximates the local connectivity of a triangulation, and warns once.
#' @return A data frame with integer columns \code{from} and \code{to} (one row
#'   per undirected edge, \code{from < to}).
#' @noRd
.delaunay_edges <- function(xy) {
  if (requireNamespace("deldir", quietly = TRUE)) {
    dd <- deldir::deldir(xy[, 1L], xy[, 2L], suppressMsge = TRUE)
    segs <- dd$delsgs
    from <- pmin(segs$ind1, segs$ind2)
    to   <- pmax(segs$ind1, segs$ind2)
    return(data.frame(from = as.integer(from), to = as.integer(to)))
  }

  warning("Package 'deldir' is not installed; falling back to a ",
          "k-nearest-neighbour graph, which only approximates a Delaunay ",
          "triangulation. Install 'deldir' for exact results.", call. = FALSE)
  n <- nrow(xy)
  k <- min(6L, n - 1L)
  d <- as.matrix(dist(xy))
  diag(d) <- Inf
  pairs <- lapply(seq_len(n), function(i) {
    nbrs <- order(d[i, ])[seq_len(k)]
    cbind(pmin(i, nbrs), pmax(i, nbrs))
  })
  m <- unique(do.call(rbind, pairs))
  data.frame(from = as.integer(m[, 1L]), to = as.integer(m[, 2L]))
}

#' Neighbourhood Enrichment Analysis
#'
#' Tests whether specific phenotype pairs are spatially enriched or depleted
#' relative to a random permutation baseline.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param radius Numeric. Neighbourhood radius.
#' @param n_perm Integer. Number of permutations. Default \code{100}.
#' @param seed Integer or \code{NULL}. Random seed.
#'
#' @return A data frame with columns \code{from}, \code{to}, \code{observed},
#'   \code{mean_expected}, \code{z_score}, and \code{p_value}.
#'
#' @examples
#' set.seed(1)
#' counts <- matrix(rnorm(200), nrow = 100,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
#' meta <- data.frame(cell_id = 1:100, sample_id = "s1",
#'   phenotype = sample(c("A", "B"), 100, replace = TRUE))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' NeighbourhoodEnrichment(obj, radius = 50, n_perm = 10)
#'
#' @export
NeighbourhoodEnrichment <- function(object, radius, n_perm = 100L,
                                    seed = NULL) {
  .assert_single_sample(object, "Neighbourhood enrichment")
  if (!is.null(seed)) set.seed(seed)

  xy <- as.matrix(object@coords)
  pheno <- object@meta_data$phenotype
  if (is.null(pheno)) {
    stop("No phenotype column. Run PhenotypeCells() first.", call. = FALSE)
  }

  phenotypes <- sort(unique(pheno))
  n_pheno <- length(phenotypes)

  # The neighbourhood graph is fixed; only the labels are permuted. Compute the
  # graph once, then each permutation is a cheap re-tabulation of labels over
  # the precomputed (centre, neighbour) edge list.
  nbr <- .radius_neighbours(xy, radius)$idx
  lens <- lengths(nbr)
  flat <- unlist(nbr, use.names = FALSE)
  centre_rep <- rep(seq_along(nbr), lens)

  .count_neighbours <- function(ph) {
    unclass(table(
      factor(ph[centre_rep], levels = phenotypes),
      factor(ph[flat],       levels = phenotypes)
    ))
  }

  obs_mat <- .count_neighbours(pheno)

  # Permutations
  perm_array <- array(0, dim = c(n_pheno, n_pheno, n_perm))
  for (p in seq_len(n_perm)) {
    perm_array[, , p] <- .count_neighbours(sample(pheno))
  }

  # Build results
  results <- expand.grid(from = phenotypes, to = phenotypes,
                         stringsAsFactors = FALSE)
  results$observed <- as.vector(obs_mat)
  results$mean_expected <- apply(perm_array, c(1, 2), mean) |> as.vector()
  perm_sd <- apply(perm_array, c(1, 2), sd) |> as.vector()
  results$z_score <- ifelse(perm_sd > 0,
    (results$observed - results$mean_expected) / perm_sd, 0)
  results$p_value <- 2 * stats::pnorm(-abs(results$z_score))
  results
}

#' Ripley's K Function
#'
#' Computes Ripley's K function to assess spatial clustering or dispersion
#' at multiple scales.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param r_seq Numeric vector of radii, or \code{NULL} for automatic.
#' @param target Character or \code{NULL}. Restrict to a phenotype.
#' @param correction Character. \code{"none"} (default) or \code{"border"}.
#'
#' @return A data frame with columns \code{r}, \code{K}, \code{L}, and
#'   \code{expected}.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 200), y = runif(50, 0, 200))
#' obj <- CreateSpatialObject(counts, coords)
#' RipleysK(obj)
#'
#' @export
RipleysK <- function(object, r_seq = NULL, target = NULL,
                     correction = c("none", "border")) {
  .assert_single_sample(object, "Ripley's K")
  correction <- match.arg(correction)
  xy <- as.matrix(object@coords)

  if (!is.null(target)) {
    idx <- which(object@meta_data$phenotype == target)
    xy <- xy[idx, , drop = FALSE]
  }

  n <- nrow(xy)
  x_range <- range(xy[, 1])
  y_range <- range(xy[, 2])
  area <- diff(x_range) * diff(y_range)
  lambda <- n / area

  if (is.null(r_seq)) {
    max_r <- min(diff(x_range), diff(y_range)) / 4
    r_seq <- seq(0, max_r, length.out = 50)
  }

  # Per-point neighbour distances out to the largest radius of interest.
  nb <- .radius_neighbours(xy, max(r_seq))$dist
  all_d <- unlist(nb, use.names = FALSE)

  if (correction == "border") {
    # Reduced-sample (border) estimator: only points at least r from the
    # window edge act as centres, which removes the negative edge bias of the
    # naive estimator. b_i is each point's distance to the bounding-box edge.
    b <- pmin(xy[, 1L] - x_range[1L], x_range[2L] - xy[, 1L],
              xy[, 2L] - y_range[1L], y_range[2L] - xy[, 2L])
    # Pair each neighbour distance with its centre's border distance, then count
    # in a fully vectorised sweep over r (a centre contributes only once it is
    # at least r from the edge).
    centre_b <- rep(b, lengths(nb))
    K <- vapply(r_seq, function(r) {
      den <- sum(b >= r)
      if (den == 0L) return(NA_real_)
      sum(all_d <= r & centre_b >= r) / (den * lambda)
    }, numeric(1L))
  } else {
    K <- vapply(r_seq, function(r) {
      sum(all_d <= r) / (n * lambda)
    }, numeric(1L))
  }

  data.frame(
    r = r_seq,
    K = K,
    L = sqrt(K / pi) - r_seq,
    expected = pi * r_seq^2
  )
}

#' Moran's I Spatial Autocorrelation
#'
#' Computes Moran's I statistic for a numeric variable.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param feature Character. Name of the marker or metadata column.
#' @param radius Numeric. Neighbourhood radius for spatial weights.
#' @param slot Character. \code{"data"} (default) or \code{"counts"}.
#'
#' @return A list with \code{I}, \code{expected}, \code{variance},
#'   \code{z_score}, and \code{p_value}.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
#' obj <- CreateSpatialObject(counts, coords)
#' MoransI(obj, feature = "CD3", radius = 30)
#'
#' @export
MoransI <- function(object, feature, radius, slot = "data") {
  .assert_single_sample(object, "Moran's I")
  mat <- methods::slot(object, match.arg(slot, c("data", "counts")))

  if (feature %in% colnames(mat)) {
    x <- mat[, feature]
  } else if (feature %in% names(object@meta_data)) {
    x <- as.numeric(object@meta_data[[feature]])
  } else {
    stop("Feature '", feature, "' not found.", call. = FALSE)
  }

  xy <- as.matrix(object@coords)
  n <- as.numeric(length(x))   # double throughout: n^2 overflows integer at ~46k
  xbar <- mean(x)
  dx <- x - xbar

  # Binary, symmetric spatial weights W_ij = 1(0 < d_ij <= radius). Working from
  # the neighbour lists avoids the n^2 weight matrix; for symmetric binary
  # weights the weight sums reduce to closed forms in the degrees.
  nb <- .radius_neighbours(xy, radius)$idx
  deg <- as.numeric(lengths(nb))
  S0 <- sum(deg)
  neigh_sum <- vapply(seq_along(nb), function(i) {
    if (deg[i] == 0) 0 else sum(dx[nb[[i]]])
  }, numeric(1L))

  I <- (n / S0) * sum(dx * neigh_sum) / sum(dx^2)
  EI <- -1 / (n - 1)
  # Variance under normality. With W symmetric and binary,
  # S1 = 0.5 * sum((W + t(W))^2) = 2 * S0 and
  # S2 = sum_i (rowsum_i + colsum_i)^2 = 4 * sum_i deg_i^2.
  S1 <- 2 * S0
  S2 <- 4 * sum(deg^2)
  n2 <- n * n
  VI <- (n2 * S1 - n * S2 + 3 * S0^2) / (S0^2 * (n2 - 1)) - EI^2

  z <- (I - EI) / sqrt(max(VI, .Machine$double.eps))
  list(I = I, expected = EI, variance = VI,
       z_score = z, p_value = 2 * stats::pnorm(-abs(z)))
}

#' Quadrat Analysis
#'
#' Divides the tissue area into a grid and counts cells per quadrat.
#' Tests for Complete Spatial Randomness using a chi-squared test.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param nx Integer. Number of columns in the grid. Default \code{5}.
#' @param ny Integer. Number of rows in the grid. Default \code{5}.
#' @param target Character or \code{NULL}. Restrict to a phenotype.
#'
#' @return A list with \code{counts}, \code{chi_sq}, \code{p_value}, and
#'   \code{VMR} (variance-to-mean ratio).
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
#' obj <- CreateSpatialObject(counts, coords)
#' QuadratAnalysis(obj, nx = 3, ny = 3)
#'
#' @export
QuadratAnalysis <- function(object, nx = 5L, ny = 5L, target = NULL) {
  .assert_single_sample(object, "Quadrat analysis")
  xy <- as.matrix(object@coords)

  if (!is.null(target)) {
    idx <- which(object@meta_data$phenotype == target)
    xy <- xy[idx, , drop = FALSE]
  }

  x_breaks <- seq(min(xy[, 1]), max(xy[, 1]), length.out = nx + 1L)
  y_breaks <- seq(min(xy[, 2]), max(xy[, 2]), length.out = ny + 1L)

  x_bin <- findInterval(xy[, 1], x_breaks, all.inside = TRUE)
  y_bin <- findInterval(xy[, 2], y_breaks, all.inside = TRUE)

  count_mat <- matrix(0L, nrow = ny, ncol = nx)
  for (i in seq_len(nrow(xy))) {
    count_mat[y_bin[i], x_bin[i]] <- count_mat[y_bin[i], x_bin[i]] + 1L
  }

  counts_vec <- as.vector(count_mat)
  expected <- mean(counts_vec)
  chi_sq <- sum((counts_vec - expected)^2 / expected)
  df <- length(counts_vec) - 1L
  p_val <- stats::pchisq(chi_sq, df = df, lower.tail = FALSE)
  vmr <- stats::var(counts_vec) / expected

  list(counts = count_mat, chi_sq = chi_sq, p_value = p_val, VMR = vmr)
}

#' Pair Correlation Function
#'
#' Computes the pair correlation function g(r), the derivative of
#' Ripley's K, measuring clustering/inhibition at specific distances.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param r_seq Numeric vector of radii, or \code{NULL} for automatic.
#' @param dr Numeric or \code{NULL}. Ring width. Default is derived from
#'   \code{r_seq}.
#' @param target Character or \code{NULL}. Restrict to a phenotype.
#'
#' @return A data frame with columns \code{r} and \code{g}.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 200), y = runif(50, 0, 200))
#' obj <- CreateSpatialObject(counts, coords)
#' PairCorrelation(obj)
#'
#' @export
PairCorrelation <- function(object, r_seq = NULL, dr = NULL,
                            target = NULL) {
  .assert_single_sample(object, "The pair correlation function")
  xy <- as.matrix(object@coords)

  if (!is.null(target)) {
    idx <- which(object@meta_data$phenotype == target)
    xy <- xy[idx, , drop = FALSE]
  }

  n <- nrow(xy)
  x_range <- range(xy[, 1])
  y_range <- range(xy[, 2])
  area <- diff(x_range) * diff(y_range)
  lambda <- n / area

  if (is.null(r_seq)) {
    max_r <- min(diff(x_range), diff(y_range)) / 4
    r_seq <- seq(1, max_r, length.out = 50)
  }
  if (is.null(dr)) {
    dr <- if (length(r_seq) > 1) r_seq[2] - r_seq[1] else 1
  }

  # All ordered pairwise distances out to the largest ring edge.
  all_d <- unlist(.radius_neighbours(xy, max(r_seq) + dr / 2)$dist,
                  use.names = FALSE)

  g <- vapply(r_seq, function(r) {
    ring <- sum(all_d > (r - dr / 2) & all_d <= (r + dr / 2))
    ring / (n * lambda * 2 * pi * r * dr)
  }, numeric(1L))

  data.frame(r = r_seq, g = g)
}

#' Cross Nearest Neighbour Distance
#'
#' Computes the nearest neighbour distance from each cell of one phenotype
#' to cells of another phenotype.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param from Character. Source phenotype.
#' @param to Character. Target phenotype.
#'
#' @return A numeric vector of distances (one per cell of the \code{from}
#'   phenotype).
#'
#' @examples
#' counts <- matrix(rnorm(60), nrow = 30,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(30, 0, 100), y = runif(30, 0, 100))
#' meta <- data.frame(cell_id = 1:30, sample_id = "s1",
#'   phenotype = rep(c("A", "B", "C"), each = 10))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' CrossNNDistance(obj, from = "A", to = "B")
#'
#' @export
CrossNNDistance <- function(object, from, to) {
  .assert_single_sample(object, "Cross nearest-neighbour distance")
  xy <- as.matrix(object@coords)
  pheno <- object@meta_data$phenotype

  from_idx <- which(pheno == from)
  to_idx <- which(pheno == to)

  if (length(from_idx) == 0L) stop("No cells with phenotype '", from, "'.",
                                    call. = FALSE)
  if (length(to_idx) == 0L) stop("No cells with phenotype '", to, "'.",
                                  call. = FALSE)

  from_xy <- xy[from_idx, , drop = FALSE]
  to_xy   <- xy[to_idx, , drop = FALSE]

  # Nearest target cell for each source cell. `from` and `to` are different
  # phenotypes, hence disjoint, so no self-match to drop.
  .knn_mean_dist(from_xy, to_xy, k = 1L, drop_self = FALSE)
}

#' Expression-Based Cell Clustering
#'
#' Clusters cells based on marker expression profiles.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param k Integer. Number of clusters.
#' @param method Character. \code{"kmeans"} (default) or \code{"hierarchical"}.
#' @param slot Character. \code{"data"} (default) or \code{"counts"}.
#' @param markers Character vector or \code{NULL}. Markers to use.
#'
#' @return An \code{\link{SpatialCellData-class}} with an \code{expr_cluster}
#'   column in \code{meta_data}.
#'
#' @examples
#' counts <- matrix(c(rnorm(50, 10), rnorm(50, 0)), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- ExpressionClusters(obj, k = 2)
#' table(Meta(obj)$expr_cluster)
#'
#' @export
ExpressionClusters <- function(object, k,
                               method = c("kmeans", "hierarchical"),
                               slot = "data", markers = NULL) {
  method <- match.arg(method)
  mat <- methods::slot(object, match.arg(slot, c("data", "counts")))

  if (!is.null(markers)) {
    mat <- mat[, intersect(markers, colnames(mat)), drop = FALSE]
  }

  cluster_ids <- switch(method,
    kmeans = {
      km <- kmeans(mat, centers = k, nstart = 10L)
      km$cluster
    },
    hierarchical = {
      hc <- hclust(dist(mat), method = "ward.D2")
      cutree(hc, k = k)
    }
  )

  object@meta_data$expr_cluster <- as.character(cluster_ids)
  object
}
