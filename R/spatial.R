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

#' Indices and distances of the `k` nearest neighbours of each point
#'
#' Returns `list(idx = <n x k integer>, dist = <n x k numeric>)`, the self-match
#' dropped, so column 1 is each point's nearest *other* neighbour. kd-tree
#' (RANN) when available, exact chunked fallback otherwise.
#' @noRd
.knn_index <- function(coords, k) {
  n <- nrow(coords)
  k <- min(as.integer(k), n - 1L)
  if (n < 2L || k < 1L) {
    return(list(idx = matrix(integer(0), n, 0L),
                dist = matrix(numeric(0), n, 0L)))
  }

  if (requireNamespace("RANN", quietly = TRUE)) {
    res <- RANN::nn2(coords, coords, k = k + 1L)
    return(list(idx = res$nn.idx[, -1L, drop = FALSE],
                dist = res$nn.dists[, -1L, drop = FALSE]))
  }

  idx <- matrix(0L, n, k)
  dst <- matrix(0, n, k)
  block <- 2048L
  for (start in seq.int(1L, n, by = block)) {
    qi <- start:min(start + block - 1L, n)
    dx <- outer(coords[qi, 1L], coords[, 1L], "-")
    dy <- outer(coords[qi, 2L], coords[, 2L], "-")
    d2 <- dx * dx + dy * dy
    for (a in seq_along(qi)) {
      o <- order(d2[a, ])
      o <- o[o != qi[a]][seq_len(k)]
      idx[qi[a], ] <- o
      dst[qi[a], ] <- sqrt(d2[a, o])
    }
  }
  list(idx = idx, dist = dst)
}

#' Cumulative neighbour counts at a set of radii, memory-bounded
#'
#' For each radius in `r_eval`, the total number of (ordered) neighbour pairs at
#' distance <= r, summed over centres. When `b` (each point's distance to the
#' window edge) is supplied, a centre contributes to radius r only when
#' `b >= r` (the reduced-sample border rule).
#'
#' A (centre, neighbour) pair at distance d with centre-border cb contributes to
#' every radius r in `[d, cb]` (or `[d, Inf)` without border). Pairs are streamed
#' through the kd-tree in blocks and folded into a difference array over the
#' radius grid, so counting is both O(pairs) vectorised and memory-bounded.
#' `r_eval` must be sorted ascending.
#' @noRd
.radius_count_sweep <- function(coords, r_eval, b = NULL, weight_fun = NULL) {
  n <- nrow(coords)
  R <- length(r_eval)
  rmax <- r_eval[R]
  delta <- numeric(R + 1L)
  if (n < 2L) return(numeric(R))
  use_rann <- requireNamespace("RANN", quietly = TRUE)
  block <- if (use_rann) 4096L else 1024L

  # Seed the radius-search cap from the expected local density so we rarely
  # have to grow k and re-query (k grows only where the tissue is unusually
  # dense). area from the bounding box.
  area <- (max(coords[, 1L]) - min(coords[, 1L])) *
          (max(coords[, 2L]) - min(coords[, 2L]))
  lambda_hat <- if (area > 0) n / area else 1
  k_start <- min(n, max(64L,
    as.integer(ceiling(1.4 * lambda_hat * pi * rmax^2 + 16))))

  add_pairs <- function(dvec, cidx, jidx) {
    if (!length(dvec)) return(invisible())
    lo <- findInterval(dvec, r_eval, left.open = TRUE) + 1L   # first r >= d
    hi <- if (is.null(b)) rep.int(R, length(dvec)) else findInterval(b[cidx], r_eval)
    ok <- lo <= hi
    if (!any(ok)) return(invisible())
    if (is.null(weight_fun)) {
      delta <<- delta + tabulate(lo[ok], R + 1L) - tabulate(hi[ok] + 1L, R + 1L)
    } else {
      w <- weight_fun(cidx[ok], jidx[ok])
      delta <<- delta +
        .weighted_tab(lo[ok], w, R + 1L) - .weighted_tab(hi[ok] + 1L, w, R + 1L)
    }
    invisible()
  }

  for (start in seq.int(1L, n, by = block)) {
    qi <- start:min(start + block - 1L, n)
    if (use_rann) {
      k <- k_start
      repeat {
        res <- RANN::nn2(coords, coords[qi, , drop = FALSE], k = k,
                         searchtype = "radius", radius = rmax)
        if (!(k < n && any(res$nn.idx[, k] != 0L))) break
        k <- min(n, k * 4L)
      }
      gi <- qi[rep(seq_along(qi), times = ncol(res$nn.idx))]
      jj <- as.vector(res$nn.idx)
      dd <- as.vector(res$nn.dists)
      keep <- jj != 0L & jj != gi
      add_pairs(dd[keep], gi[keep], jj[keep])
    } else {
      dx <- outer(coords[qi, 1L], coords[, 1L], "-")
      dy <- outer(coords[qi, 2L], coords[, 2L], "-")
      d2 <- dx * dx + dy * dy
      gi <- qi[row(d2)]
      cj <- col(d2)
      keep <- d2 <= rmax * rmax & gi != cj
      add_pairs(sqrt(d2[keep]), gi[keep], cj[keep])
    }
  }
  cumsum(delta)[seq_len(R)]
}

#' Sum of weights grouped by integer bin (a weighted tabulate)
#' @noRd
.weighted_tab <- function(bin, w, nbins) {
  out <- numeric(nbins)
  s <- tapply(w, bin, sum)
  out[as.integer(names(s))] <- s
  out
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
#' Apply a single-sample statistic across every sample
#'
#' Maps `fn` over each sample's subset and returns a named, classed list. Used
#' by the single-window statistics when `by_sample = TRUE`.
#' @noRd
.by_sample_apply <- function(object, fn) {
  samples <- unique(object@meta_data$sample_id)
  res <- lapply(samples, function(s) {
    fn(object[object@meta_data$sample_id == s, ])
  })
  names(res) <- samples
  class(res) <- c("phenoscapR_by_sample", "list")
  res
}

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
#' @param method Character. \code{"analytic"} (default) compares observed
#'   neighbour counts to an expectation under random mixing;
#'   \code{"permutation"} builds the null by shuffling phenotype labels within
#'   each sample, adding \code{z_score} and \code{p_value} columns.
#' @param n_perm Integer. Number of label permutations when
#'   \code{method = "permutation"}. Default \code{100}.
#' @param seed Integer or \code{NULL}. Random seed for the permutation null.
#'
#' @return A data frame with columns \code{from}, \code{to}, \code{observed},
#'   \code{expected}, and \code{interaction_score}; the permutation method adds
#'   \code{z_score} and \code{p_value}.
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
InteractionMatrix <- function(object, radius, method = c("analytic",
                              "permutation"), n_perm = 100L, seed = NULL) {
  method <- match.arg(method)
  dt <- data.table::data.table(
    sample_id = object@meta_data$sample_id,
    cell_id   = object@meta_data$cell_id,
    x         = object@coords$x,
    y         = object@coords$y,
    phenotype = object@meta_data$phenotype
  )
  out <- if (method == "permutation") {
    .interaction_permutation(dt, radius, as.integer(n_perm), seed)
  } else {
    as.data.frame(interaction_matrix(dt, radius = radius))
  }
  .as_result(out, "phenoscapR_interaction")
}

#' Permutation-based interaction matrix
#'
#' Builds the null distribution of phenotype neighbour counts by shuffling
#' labels within each sample (geometry held fixed). Returns observed counts, the
#' permutation mean as the expectation, the interaction score, and z / p.
#' @noRd
.interaction_permutation <- function(dt, radius, n_perm, seed) {
  if (!is.null(seed)) set.seed(seed)
  phenotypes <- sort(unique(dt$phenotype))
  np <- length(phenotypes)
  sample_vec <- if ("sample_id" %in% names(dt)) dt$sample_id else
    rep("__all__", nrow(dt))

  # Precompute each sample's fixed neighbour edge list once.
  per <- lapply(unique(sample_vec), function(sid) {
    rows <- which(sample_vec == sid)
    if (length(rows) < 2L) return(NULL)
    nb <- .radius_neighbours(as.matrix(dt[rows, c("x", "y")]), radius)$idx
    list(ph = dt$phenotype[rows],
         centre = rep(seq_along(nb), lengths(nb)),
         flat = unlist(nb, use.names = FALSE))
  })
  per <- Filter(Negate(is.null), per)

  one_tab <- function(s) {
    unclass(table(
      factor(s$ph[s$centre], levels = phenotypes),
      factor(s$ph[s$flat], levels = phenotypes)))
  }
  tabulate_counts <- function(parts) Reduce(`+`, lapply(parts, one_tab))

  obs <- tabulate_counts(per)
  perms <- vapply(seq_len(n_perm), function(p) {
    as.vector(tabulate_counts(lapply(per, function(s) {
      s$ph <- sample(s$ph)
      s
    })))
  }, numeric(np * np))
  mean_exp <- rowMeans(perms)
  sd_exp <- apply(perms, 1L, stats::sd)
  obs_v <- as.vector(obs)
  z <- ifelse(sd_exp > 0, (obs_v - mean_exp) / sd_exp, 0)

  data.frame(
    from = rep(phenotypes, each = np),
    to = rep(phenotypes, np),
    observed = obs_v,
    expected = mean_exp,
    interaction_score = ifelse(mean_exp > 0 & obs_v > 0,
                               log2(obs_v / mean_exp), 0),
    z_score = z,
    p_value = 2 * stats::pnorm(-abs(z))
  )
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
  kn <- .knn_index(xy, k)                       # kd-tree, no O(n^2) matrix
  ii <- rep(seq_len(n), times = ncol(kn$idx))
  jj <- as.vector(kn$idx)
  ok <- jj != 0L
  m <- unique(cbind(pmin(ii[ok], jj[ok]), pmax(ii[ok], jj[ok])))
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
#' @param by_sample Logical. If \code{TRUE} and the object holds several samples,
#'   the statistic is computed per sample and returned as a named list. Default
#'   \code{FALSE}; otherwise a single sample is required.
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
                                    seed = NULL, by_sample = FALSE) {
  if (isTRUE(by_sample) && length(unique(object@meta_data$sample_id)) > 1L) {
    return(.by_sample_apply(object, function(o) {
      NeighbourhoodEnrichment(o, radius = radius, n_perm = n_perm, seed = seed)
    }))
  }
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
  .as_result(results, "phenoscapR_enrichment")
}

#' Ripley's K Function
#'
#' Computes Ripley's K function to assess spatial clustering or dispersion
#' at multiple scales.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param r_seq Numeric vector of radii, or \code{NULL} for automatic.
#' @param target Character or \code{NULL}. Restrict to a phenotype.
#' @param correction Character. Edge correction: \code{"none"} (default),
#'   \code{"border"} (reduced-sample), or \code{"translation"} (each pair
#'   weighted by the inverse window/translate overlap; rigorous for rectangular
#'   windows).
#' @param by_sample Logical. If \code{TRUE} and the object holds several samples,
#'   the statistic is computed per sample and returned as a named list (one
#'   entry per sample). Default \code{FALSE}; otherwise a single sample is
#'   required.
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
                     correction = c("none", "border", "translation"),
                     by_sample = FALSE) {
  correction <- match.arg(correction)
  if (isTRUE(by_sample) && length(unique(object@meta_data$sample_id)) > 1L) {
    return(.by_sample_apply(object, function(o) {
      RipleysK(o, r_seq = r_seq, target = target, correction = correction)
    }))
  }
  .assert_single_sample(object, "Ripley's K")
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

  # Cumulative neighbour counts per radius, computed in a memory-bounded sweep
  # (never materialises the full pairwise-distance set).
  r_sorted <- sort(r_seq)
  ord <- order(r_seq)

  if (correction == "border") {
    # Reduced-sample (border) estimator: only points at least r from the window
    # edge act as centres, removing the negative edge bias. b_i is each point's
    # distance to the bounding-box edge.
    b <- pmin(xy[, 1L] - x_range[1L], x_range[2L] - xy[, 1L],
              xy[, 2L] - y_range[1L], y_range[2L] - xy[, 2L])
    num <- .radius_count_sweep(xy, r_sorted, b = b)
    den <- vapply(r_sorted, function(r) sum(b >= r), numeric(1L))
    K_sorted <- ifelse(den > 0, num / (den * lambda), NA_real_)
  } else if (correction == "translation") {
    # Translation-corrected estimator: each pair is weighted by the inverse
    # overlap of the rectangular window with its translate by (dx, dy), which
    # exactly compensates for unobserved pairs near the edges.
    Wd <- diff(x_range)
    Hd <- diff(y_range)
    wfun <- function(i, j) {
      dxp <- abs(xy[i, 1L] - xy[j, 1L])
      dyp <- abs(xy[i, 2L] - xy[j, 2L])
      ov <- (Wd - dxp) * (Hd - dyp)
      w <- ifelse(ov > 0, 1 / ov, 0)
      w
    }
    cumw <- .radius_count_sweep(xy, r_sorted, weight_fun = wfun)
    K_sorted <- (area^2 / n^2) * cumw
  } else {
    num <- .radius_count_sweep(xy, r_sorted)
    K_sorted <- num / (n * lambda)
  }
  K <- K_sorted[order(ord)]   # restore the caller's radius order

  out <- data.frame(
    r = r_seq,
    K = K,
    L = sqrt(K / pi) - r_seq,
    expected = pi * r_seq^2
  )
  attr(out, "correction") <- correction
  .as_result(out, "phenoscapR_ripley")
}

#' Moran's I Spatial Autocorrelation
#'
#' Computes Moran's I statistic for a numeric variable.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param feature Character. Name of the marker or metadata column.
#' @param radius Numeric. Neighbourhood radius for spatial weights.
#' @param slot Character. \code{"data"} (default) or \code{"counts"}.
#' @param weights Character. Spatial weighting within the radius:
#'   \code{"binary"} (default; 1 for every neighbour), \code{"row"}
#'   (row-standardised, each cell's weights sum to 1), or \code{"idw"}
#'   (inverse-distance, \code{1 / d}).
#' @param n_perm Integer. Number of label permutations for the p-value. \code{0}
#'   (default) uses the analytic normal approximation, which is exact only for
#'   \code{"binary"} weights; any other weighting auto-enables a permutation
#'   test.
#' @param seed Integer or \code{NULL}. Random seed for the permutation test.
#' @param by_sample Logical. If \code{TRUE} and the object holds several samples,
#'   the statistic is computed per sample and returned as a named list. Default
#'   \code{FALSE}; otherwise a single sample is required.
#'
#' @return A list with \code{I}, \code{expected}, \code{variance},
#'   \code{z_score}, \code{p_value}, and \code{method} (\code{"analytic"} or
#'   \code{"permutation"}).
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
#' obj <- CreateSpatialObject(counts, coords)
#' MoransI(obj, feature = "CD3", radius = 30)
#' MoransI(obj, feature = "CD3", radius = 30, weights = "idw", n_perm = 199)
#'
#' @export
MoransI <- function(object, feature, radius, slot = "data",
                    weights = c("binary", "row", "idw"), n_perm = 0L,
                    seed = NULL, by_sample = FALSE) {
  weights <- match.arg(weights)
  if (isTRUE(by_sample) && length(unique(object@meta_data$sample_id)) > 1L) {
    return(.by_sample_apply(object, function(o) {
      MoransI(o, feature = feature, radius = radius, slot = slot,
              weights = weights, n_perm = n_perm, seed = seed)
    }))
  }
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

  # Neighbour lists avoid the n^2 weight matrix. Per-neighbour weights depend on
  # the chosen scheme; distances are needed only for inverse-distance weights.
  nbr <- .radius_neighbours(xy, radius)
  nb <- nbr$idx
  deg <- as.numeric(lengths(nb))
  row_weight <- function(i) {
    if (deg[i] > 0) rep(1 / deg[i], length(nb[[i]])) else numeric(0)
  }
  wlist <- switch(weights,
    binary = lapply(nb, function(j) rep(1, length(j))),
    row    = lapply(seq_along(nb), row_weight),
    idw    = lapply(nbr$dist, function(d) 1 / d)
  )
  S0 <- sum(unlist(wlist, use.names = FALSE))

  moran_stat <- function(dxv) {
    nw <- vapply(seq_along(nb), function(i) {
      if (deg[i] == 0) 0 else sum(wlist[[i]] * dxv[nb[[i]]])
    }, numeric(1L))
    (n / S0) * sum(dxv * nw) / sum(dxv^2)
  }

  I <- moran_stat(dx)
  EI <- -1 / (n - 1)

  use_perm <- n_perm > 0L || weights != "binary"
  if (use_perm) {
    nperm <- if (n_perm > 0L) as.integer(n_perm) else 999L
    if (!is.null(seed)) set.seed(seed)
    perm <- vapply(seq_len(nperm), function(p) {
      xp <- sample(x)
      moran_stat(xp - mean(xp))
    }, numeric(1L))
    psd <- stats::sd(perm)
    z <- (I - mean(perm)) / max(psd, .Machine$double.eps)
    p <- (sum(abs(perm - EI) >= abs(I - EI)) + 1) / (nperm + 1)
    res <- list(I = I, expected = EI, variance = psd^2,
                z_score = z, p_value = p, method = "permutation")
  } else {
    # Analytic variance under normality for symmetric binary weights:
    # S1 = 2 * S0, S2 = 4 * sum(deg^2).
    S1 <- 2 * S0
    S2 <- 4 * sum(deg^2)
    n2 <- n * n
    VI <- (n2 * S1 - n * S2 + 3 * S0^2) / (S0^2 * (n2 - 1)) - EI^2
    z <- (I - EI) / sqrt(max(VI, .Machine$double.eps))
    res <- list(I = I, expected = EI, variance = VI,
                z_score = z, p_value = 2 * stats::pnorm(-abs(z)),
                method = "analytic")
  }
  .as_result(res, "phenoscapR_moran")
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
#' @param by_sample Logical. If \code{TRUE} and the object holds several samples,
#'   the statistic is computed per sample and returned as a named list. Default
#'   \code{FALSE}; otherwise a single sample is required.
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
QuadratAnalysis <- function(object, nx = 5L, ny = 5L, target = NULL,
                            by_sample = FALSE) {
  if (isTRUE(by_sample) && length(unique(object@meta_data$sample_id)) > 1L) {
    return(.by_sample_apply(object, function(o) {
      QuadratAnalysis(o, nx = nx, ny = ny, target = target)
    }))
  }
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

  .as_result(
    list(counts = count_mat, chi_sq = chi_sq, p_value = p_val, VMR = vmr),
    "phenoscapR_quadrat")
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
#' @param by_sample Logical. If \code{TRUE} and the object holds several samples,
#'   the statistic is computed per sample and returned as a named list. Default
#'   \code{FALSE}; otherwise a single sample is required.
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
                            target = NULL, by_sample = FALSE) {
  if (isTRUE(by_sample) && length(unique(object@meta_data$sample_id)) > 1L) {
    return(.by_sample_apply(object, function(o) {
      PairCorrelation(o, r_seq = r_seq, dr = dr, target = target)
    }))
  }
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

  # Ring counts come from differences of cumulative neighbour counts at the
  # ring edges, computed in a memory-bounded sweep (no full distance set).
  lower <- r_seq - dr / 2
  upper <- r_seq + dr / 2
  edges <- sort(unique(c(lower, upper)))
  edges <- edges[edges > 0]
  cum <- .radius_count_sweep(xy, edges)
  cumc <- function(r) if (r <= 0) 0 else cum[match(r, edges)]

  g <- vapply(seq_along(r_seq), function(i) {
    ring <- cumc(upper[i]) - cumc(lower[i])
    ring / (n * lambda * 2 * pi * r_seq[i] * dr)
  }, numeric(1L))

  .as_result(data.frame(r = r_seq, g = g), "phenoscapR_pcf")
}

#' Cross Nearest Neighbour Distance
#'
#' Computes the nearest neighbour distance from each cell of one phenotype
#' to cells of another phenotype.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param from Character. Source phenotype.
#' @param to Character. Target phenotype.
#' @param by_sample Logical. If \code{TRUE} and the object holds several samples,
#'   the statistic is computed per sample and returned as a named list. Default
#'   \code{FALSE}; otherwise a single sample is required.
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
CrossNNDistance <- function(object, from, to, by_sample = FALSE) {
  if (isTRUE(by_sample) && length(unique(object@meta_data$sample_id)) > 1L) {
    return(.by_sample_apply(object, function(o) {
      CrossNNDistance(o, from = from, to = to)
    }))
  }
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
  d <- .knn_mean_dist(from_xy, to_xy, k = 1L, drop_self = FALSE)
  attr(d, "from") <- from
  attr(d, "to") <- to
  .as_result(d, "phenoscapR_crossnn")
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
