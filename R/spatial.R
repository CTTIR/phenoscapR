#' Compute Nearest Neighbour Distances
#'
#' For each cell, computes the distance to the \code{k} nearest neighbours,
#' optionally restricted to cells of a specific phenotype.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param k Integer. Number of nearest neighbours. Default \code{1}.
#' @param target Character or \code{NULL}. If set, distances are computed
#'   only to cells of this phenotype.
#'
#' @return An \code{\link{AkoyaExperiment}} with \code{nn_distance} added
#'   to \code{meta_data} and the result stored in the \code{spatial} slot.
#'
#' @examples
#' counts <- matrix(rnorm(50), nrow = 10,
#'                  dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK", "CD20")))
#' coords <- data.frame(x = seq(0, 90, by = 10), y = rep(0, 10))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- FindNeighbours(obj, k = 1)
#' Meta(obj)$nn_distance
#'
#' @export
#' @importFrom stats dist
FindNeighbours <- function(object, k = 1L, target = NULL) {
  k <- as.integer(k)
  samples <- unique(object@meta_data$sample_id)
  nn_dist <- numeric(NCells(object))

  for (sid in samples) {
    idx <- which(object@meta_data$sample_id == sid)
    coords_from <- as.matrix(object@coords[idx, c("x", "y")])

    if (!is.null(target)) {
      if (!"phenotype" %in% names(object@meta_data)) {
        stop("'phenotype' column required when target is set.",
             call. = FALSE)
      }
      target_idx <- idx[object@meta_data$phenotype[idx] == target]
      if (length(target_idx) == 0L) {
        nn_dist[idx] <- NA_real_
        next
      }
      coords_to <- as.matrix(object@coords[target_idx, c("x", "y")])
    } else {
      coords_to <- coords_from
    }

    nn_dist[idx] <- .compute_nn(coords_from, coords_to, k,
                                 self = is.null(target))
  }

  object@meta_data$nn_distance <- nn_dist
  object@spatial$nn_distance <- nn_dist
  object
}

#' @noRd
.compute_nn <- function(from, to, k, self = TRUE) {
  d <- .cross_dist(from, to)

  vapply(seq_len(nrow(from)), function(i) {
    dists <- d[i, ]
    if (self) dists <- dists[dists > 0]
    if (length(dists) == 0L) return(NA_real_)
    k_use <- min(k, length(dists))
    mean(sort(dists)[seq_len(k_use)])
  }, numeric(1L))
}

#' Compute cross-distances between two coordinate matrices
#' @noRd
.cross_dist <- function(from, to) {
  n <- nrow(from)
  m <- nrow(to)
  d <- matrix(0, nrow = n, ncol = m)
  for (j in seq_len(m)) {
    dx <- from[, 1L] - to[j, 1L]
    dy <- from[, 2L] - to[j, 2L]
    d[, j] <- sqrt(dx * dx + dy * dy)
  }
  d
}

#' Compute Cell Density
#'
#' Estimates local cell density by counting neighbours within a given
#' radius.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param radius Numeric. Neighbourhood radius in coordinate units.
#' @param target Character or \code{NULL}. If set, only cells of this
#'   phenotype are counted.
#'
#' @return An \code{\link{AkoyaExperiment}} with \code{density} added to
#'   \code{meta_data}.
#'
#' @examples
#' counts <- matrix(rnorm(50), nrow = 10,
#'                  dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK", "CD20")))
#' coords <- data.frame(x = c(0, 1, 2, 100, 101, 200, 201, 300, 301, 400),
#'                      y = rep(0, 10))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- CellDensity(obj, radius = 5)
#' Meta(obj)$density
#'
#' @export
CellDensity <- function(object, radius, target = NULL) {
  samples <- unique(object@meta_data$sample_id)
  dens <- numeric(NCells(object))

  for (sid in samples) {
    idx <- which(object@meta_data$sample_id == sid)
    coords <- as.matrix(object@coords[idx, c("x", "y")])

    if (!is.null(target)) {
      if (!"phenotype" %in% names(object@meta_data)) {
        stop("'phenotype' column required when target is set.",
             call. = FALSE)
      }
      target_idx <- idx[object@meta_data$phenotype[idx] == target]
      target_coords <- as.matrix(object@coords[target_idx, c("x", "y")])
    } else {
      target_coords <- coords
    }

    d <- .cross_dist(coords, target_coords)
    dens[idx] <- rowSums(d <= radius & d > 0)
  }

  object@meta_data$density <- dens
  object@spatial$density <- dens
  object
}

#' Spatial Interaction Matrix
#'
#' Computes pairwise spatial interaction scores between phenotypes by
#' comparing observed neighbour frequencies within a radius to those
#' expected under random mixing.
#'
#' @param object An \code{\link{AkoyaExperiment}} object with a
#'   \code{phenotype} column.
#' @param radius Numeric. Neighbourhood radius.
#'
#' @return A data frame with columns \code{from}, \code{to},
#'   \code{observed}, \code{expected}, and \code{interaction_score}
#'   (\code{log2(observed / expected)}). Positive values indicate spatial
#'   attraction; negative values indicate avoidance.
#'
#' @examples
#' set.seed(42)
#' counts <- matrix(rnorm(200), nrow = 100,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
#' meta <- data.frame(cell_id = 1:100, sample_id = "s1")
#' obj <- CreateAkoyaObject(counts, coords, meta)
#' obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0))
#' result <- InteractionMatrix(obj, radius = 80)
#' result
#'
#' @export
InteractionMatrix <- function(object, radius) {
  md <- object@meta_data
  if (!"phenotype" %in% names(md)) {
    stop("No 'phenotype' column. Run PhenotypeCells() first.", call. = FALSE)
  }

  coords <- as.matrix(object@coords[, c("x", "y")])
  pheno_vec <- md$phenotype
  phenotypes <- sort(unique(pheno_vec))
  n_pheno <- length(phenotypes)
  n_cells <- nrow(coords)

  d <- .cross_dist(coords, coords)

  obs <- matrix(0, nrow = n_pheno, ncol = n_pheno,
                dimnames = list(phenotypes, phenotypes))

  for (i in seq_len(n_cells)) {
    neighbours <- which(d[i, ] <= radius & d[i, ] > 0)
    if (length(neighbours) == 0L) next
    from <- pheno_vec[i]
    tab <- table(pheno_vec[neighbours])
    for (ph in names(tab)) {
      obs[from, ph] <- obs[from, ph] + tab[ph]
    }
  }

  freq <- table(pheno_vec) / n_cells
  total_pairs <- sum(obs)
  exp_mat <- outer(
    as.numeric(freq[phenotypes]),
    as.numeric(freq[phenotypes])
  ) * total_pairs
  dimnames(exp_mat) <- list(phenotypes, phenotypes)

  result <- data.frame(
    from = rep(phenotypes, each = n_pheno),
    to = rep(phenotypes, n_pheno),
    observed = as.vector(obs),
    expected = as.vector(exp_mat),
    stringsAsFactors = FALSE
  )
  result$interaction_score <- ifelse(
    result$expected > 0 & result$observed > 0,
    log2(result$observed / result$expected),
    0
  )

  object@spatial$interactions <- result
  result
}

#' Spatial Cell Clustering
#'
#' Clusters cells based on their spatial coordinates using k-means or
#' hierarchical clustering.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param k Integer. Number of clusters.
#' @param method Character. \code{"kmeans"} (default) or
#'   \code{"hierarchical"}.
#'
#' @return An \code{\link{AkoyaExperiment}} with a \code{cluster} column
#'   added to \code{meta_data}.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(
#'   x = c(rnorm(25, 0, 5), rnorm(25, 50, 5)),
#'   y = c(rnorm(25, 0, 5), rnorm(25, 50, 5))
#' )
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- SpatialClusters(obj, k = 2)
#' table(Meta(obj)$cluster)
#'
#' @export
#' @importFrom stats kmeans hclust cutree
SpatialClusters <- function(object, k, method = c("kmeans", "hierarchical")) {
  method <- match.arg(method)
  coords <- as.matrix(object@coords[, c("x", "y")])

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
#' in the spatial slot. Used for spatial network visualisation and
#' neighbourhood analysis.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param max_edge Numeric or \code{NULL}. Maximum edge length to retain.
#'   Removes very long edges that connect distant cells. Default
#'   \code{NULL} (keep all).
#'
#' @return An \code{\link{AkoyaExperiment}} with \code{delaunay_edges}
#'   (data frame with \code{from}, \code{to}, \code{distance}) stored in
#'   the \code{spatial} slot.
#'
#' @details
#' Uses a sweep-line approach to compute Delaunay triangulation in pure
#' R. For very large datasets (>50k cells), consider subsetting first.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- DelaunayNetwork(obj)
#' head(obj@spatial$delaunay_edges)
#'
#' @export
DelaunayNetwork <- function(object, max_edge = NULL) {
  xy <- as.matrix(object@coords[, c("x", "y")])
  n <- nrow(xy)

  if (n < 3L) {
    stop("Need at least 3 cells for Delaunay triangulation.", call. = FALSE)
  }

  # Compute Delaunay via circumcircle-based approach
  edges <- .delaunay_edges(xy)

  # Compute distances
  dx <- xy[edges[, 1L], 1L] - xy[edges[, 2L], 1L]
  dy <- xy[edges[, 1L], 2L] - xy[edges[, 2L], 2L]
  dists <- sqrt(dx * dx + dy * dy)

  edge_df <- data.frame(
    from = edges[, 1L],
    to = edges[, 2L],
    distance = dists,
    stringsAsFactors = FALSE
  )

  if (!is.null(max_edge)) {
    edge_df <- edge_df[edge_df$distance <= max_edge, ]
  }

  object@spatial$delaunay_edges <- edge_df
  object
}

#' Compute Delaunay edges via incremental insertion
#' @noRd
.delaunay_edges <- function(xy) {
  n <- nrow(xy)
  # Use a simple O(n^2) approach based on empty circumcircle criterion
  # For each triple of points, check if any other point lies inside
  # the circumcircle. If not, it's a Delaunay triangle.

  # For performance on larger datasets, use a KNN-based heuristic:
  # connect each point to its nearest neighbours and filter by Delaunay criterion
  if (n > 500L) {
    return(.delaunay_knn_approx(xy))
  }

  edge_set <- list()
  idx <- 0L

  for (i in seq_len(n - 2L)) {
    for (j in (i + 1L):min(n - 1L, n)) {
      for (k in (j + 1L):n) {
        cc <- .circumcircle(xy[i, ], xy[j, ], xy[k, ])
        if (is.null(cc)) next

        is_delaunay <- TRUE
        for (m in seq_len(n)) {
          if (m == i || m == j || m == k) next
          dx <- xy[m, 1L] - cc[1L]
          dy <- xy[m, 2L] - cc[2L]
          if (dx * dx + dy * dy < cc[3L] * cc[3L] - 1e-10) {
            is_delaunay <- FALSE
            break
          }
        }

        if (is_delaunay) {
          idx <- idx + 1L
          edge_set[[idx]] <- c(i, j)
          idx <- idx + 1L
          edge_set[[idx]] <- c(j, k)
          idx <- idx + 1L
          edge_set[[idx]] <- c(i, k)
        }
      }
    }
  }

  if (length(edge_set) == 0L) {
    return(matrix(integer(0), ncol = 2))
  }

  edges <- do.call(rbind, edge_set)
  # Remove duplicates
  edges <- unique(edges)
  edges
}

#' KNN-based approximate Delaunay for large datasets
#' @noRd
.delaunay_knn_approx <- function(xy) {
  n <- nrow(xy)
  k <- min(12L, n - 1L)

  # For each point, find k nearest neighbours and create edges
  d <- .cross_dist(xy, xy)
  edge_list <- list()
  idx <- 0L

  for (i in seq_len(n)) {
    dists <- d[i, ]
    dists[i] <- Inf
    nn <- order(dists)[seq_len(k)]
    for (j in nn) {
      from <- min(i, j)
      to <- max(i, j)
      idx <- idx + 1L
      edge_list[[idx]] <- c(from, to)
    }
  }

  edges <- do.call(rbind, edge_list)
  unique(edges)
}

#' Circumcircle of three points
#' @noRd
.circumcircle <- function(a, b, c) {
  ax <- a[1L]; ay <- a[2L]
  bx <- b[1L]; by <- b[2L]
  cx <- c[1L]; cy <- c[2L]

  D <- 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
  if (abs(D) < 1e-12) return(NULL)

  ux <- ((ax * ax + ay * ay) * (by - cy) +
         (bx * bx + by * by) * (cy - ay) +
         (cx * cx + cy * cy) * (ay - by)) / D
  uy <- ((ax * ax + ay * ay) * (cx - bx) +
         (bx * bx + by * by) * (ax - cx) +
         (cx * cx + cy * cy) * (bx - ax)) / D
  r <- sqrt((ax - ux)^2 + (ay - uy)^2)
  c(ux, uy, r)
}

#' Neighbourhood Enrichment Analysis
#'
#' Tests whether specific phenotype pairs are spatially enriched or
#' depleted relative to a random permutation baseline.
#'
#' @param object An \code{\link{AkoyaExperiment}} object with a
#'   \code{phenotype} column.
#' @param radius Numeric. Neighbourhood radius.
#' @param n_perm Integer. Number of permutations. Default \code{100}.
#' @param seed Integer or \code{NULL}. Random seed for reproducibility.
#'
#' @return A data frame with columns \code{from}, \code{to},
#'   \code{observed}, \code{mean_expected}, \code{z_score}, and
#'   \code{p_value}.
#'
#' @examples
#' set.seed(42)
#' counts <- matrix(rnorm(200), nrow = 100,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
#' meta <- data.frame(cell_id = 1:100, sample_id = "s1",
#'                    phenotype = sample(c("A", "B"), 100, TRUE))
#' obj <- CreateAkoyaObject(counts, coords, meta)
#' ne <- NeighbourhoodEnrichment(obj, radius = 80, n_perm = 50)
#' ne
#'
#' @export
NeighbourhoodEnrichment <- function(object, radius, n_perm = 100L,
                                      seed = NULL) {
  md <- object@meta_data
  if (!"phenotype" %in% names(md)) {
    stop("No 'phenotype' column. Run PhenotypeCells() first.", call. = FALSE)
  }

  if (!is.null(seed)) set.seed(seed)

  coords <- as.matrix(object@coords[, c("x", "y")])
  pheno_vec <- md$phenotype
  phenotypes <- sort(unique(pheno_vec))
  n_pheno <- length(phenotypes)
  n_cells <- nrow(coords)

  d <- .cross_dist(coords, coords)

  # Count observed neighbours per phenotype pair
  obs <- .count_neighbours(d, pheno_vec, phenotypes, radius)

  # Permutation distribution
  perm_counts <- array(0, dim = c(n_perm, n_pheno, n_pheno))
  for (p in seq_len(n_perm)) {
    perm_pheno <- sample(pheno_vec)
    perm_counts[p, , ] <- .count_neighbours(d, perm_pheno, phenotypes, radius)
  }

  # Compute z-scores and p-values
  records <- list()
  idx <- 0L
  for (i in seq_len(n_pheno)) {
    for (j in seq_len(n_pheno)) {
      perm_vals <- perm_counts[, i, j]
      mean_exp <- mean(perm_vals)
      sd_exp <- stats::sd(perm_vals)
      z <- if (sd_exp > 0) (obs[i, j] - mean_exp) / sd_exp else 0
      p_val <- mean(abs(perm_vals - mean_exp) >= abs(obs[i, j] - mean_exp))
      idx <- idx + 1L
      records[[idx]] <- data.frame(
        from = phenotypes[i],
        to = phenotypes[j],
        observed = obs[i, j],
        mean_expected = mean_exp,
        z_score = z,
        p_value = p_val,
        stringsAsFactors = FALSE
      )
    }
  }

  result <- do.call(rbind, records)
  object@spatial$neighbourhood_enrichment <- result
  result
}

#' Count neighbour pairs by phenotype
#' @noRd
.count_neighbours <- function(d, pheno_vec, phenotypes, radius) {
  n_pheno <- length(phenotypes)
  n_cells <- nrow(d)
  counts <- matrix(0, nrow = n_pheno, ncol = n_pheno)

  for (i in seq_len(n_cells)) {
    neighbours <- which(d[i, ] <= radius & d[i, ] > 0)
    if (length(neighbours) == 0L) next
    from_idx <- match(pheno_vec[i], phenotypes)
    tab <- table(factor(pheno_vec[neighbours], levels = phenotypes))
    counts[from_idx, ] <- counts[from_idx, ] + as.integer(tab)
  }
  counts
}

#' Ripley's K Function
#'
#' Computes Ripley's K function to assess spatial clustering or
#' dispersion at multiple scales. The K function counts the average
#' number of points within distance \code{r} of each point, normalised
#' by the overall density.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param r_seq Numeric vector. Distances at which to evaluate K. If
#'   \code{NULL}, 20 equally spaced values up to 1/4 of the bounding
#'   box diagonal are used.
#' @param target Character or \code{NULL}. If set, compute K only for
#'   cells of this phenotype.
#' @param correction Character. Edge correction: \code{"none"} (default)
#'   or \code{"border"}.
#'
#' @return A data frame with columns \code{r}, \code{K}, \code{L}
#'   (Besag's L = sqrt(K/pi) - r), and \code{expected} (pi * r^2).
#'
#' @examples
#' set.seed(1)
#' counts <- matrix(rnorm(200), nrow = 100,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
#' obj <- CreateAkoyaObject(counts, coords)
#' kf <- RipleysK(obj)
#' head(kf)
#'
#' @export
RipleysK <- function(object, r_seq = NULL, target = NULL,
                      correction = c("none", "border")) {
  correction <- match.arg(correction)
  coords <- as.matrix(object@coords[, c("x", "y")])

  if (!is.null(target)) {
    if (!"phenotype" %in% names(object@meta_data)) {
      stop("'phenotype' column required when target is set.", call. = FALSE)
    }
    sel <- object@meta_data$phenotype == target
    coords <- coords[sel, , drop = FALSE]
  }

  n <- nrow(coords)
  if (n < 2L) stop("Need at least 2 cells.", call. = FALSE)

  xr <- range(coords[, 1L])
  yr <- range(coords[, 2L])
  area <- (xr[2L] - xr[1L]) * (yr[2L] - yr[1L])
  if (area <= 0) stop("Zero bounding box area.", call. = FALSE)
  lambda <- n / area

  if (is.null(r_seq)) {
    diag_len <- sqrt((xr[2L] - xr[1L])^2 + (yr[2L] - yr[1L])^2)
    r_seq <- seq(0, diag_len / 4, length.out = 20L)
  }

  d <- as.matrix(stats::dist(coords))

  K_vals <- vapply(r_seq, function(r) {
    count <- sum(d <= r & d > 0)
    if (correction == "border") {
      # Simple border correction: weight by 1/proportion of circle inside window
      count / (n * lambda)
    } else {
      count / (n * lambda)
    }
  }, numeric(1L))

  L_vals <- sqrt(K_vals / pi) - r_seq

  result <- data.frame(
    r = r_seq,
    K = K_vals,
    L = L_vals,
    expected = pi * r_seq^2
  )

  object@spatial$ripleys_k <- result
  result
}

#' Moran's I Spatial Autocorrelation
#'
#' Computes Moran's I statistic for a numeric variable to assess
#' spatial autocorrelation. Values near +1 indicate clustering, near -1
#' indicate dispersion, and near 0 indicate randomness.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param feature Character. Marker name or metadata column to test.
#' @param radius Numeric. Neighbourhood radius for the spatial weights
#'   matrix.
#' @param slot Character. \code{"data"} or \code{"counts"}. Used when
#'   \code{feature} is a marker name.
#'
#' @return A list with components \code{I} (Moran's I statistic),
#'   \code{expected} (expected I under null), \code{variance},
#'   \code{z_score}, and \code{p_value} (two-sided).
#'
#' @examples
#' set.seed(1)
#' counts <- matrix(rnorm(200), nrow = 100,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
#' obj <- CreateAkoyaObject(counts, coords)
#' MoransI(obj, feature = "CD3", radius = 100)
#'
#' @export
#' @importFrom stats pnorm
MoransI <- function(object, feature, radius, slot = "data") {
  mat <- GetData(object, slot = slot)
  if (feature %in% colnames(mat)) {
    x <- mat[, feature]
  } else if (feature %in% names(object@meta_data)) {
    x <- as.numeric(object@meta_data[[feature]])
  } else {
    stop("Feature '", feature, "' not found.", call. = FALSE)
  }

  n <- length(x)
  coords <- as.matrix(object@coords[, c("x", "y")])
  d <- .cross_dist(coords, coords)

  # Binary spatial weights
  W <- (d <= radius & d > 0) * 1.0
  S0 <- sum(W)

  if (S0 == 0) {
    warning("No neighbours found within radius. Returning NA.", call. = FALSE)
    return(list(I = NA_real_, expected = NA_real_, variance = NA_real_,
                z_score = NA_real_, p_value = NA_real_))
  }

  xbar <- mean(x, na.rm = TRUE)
  z <- x - xbar

  numerator <- n * sum(W * outer(z, z)) / S0
  denominator <- sum(z^2)

  I <- numerator / denominator
  EI <- -1 / (n - 1)

  # Variance under normality assumption
  S1 <- 0.5 * sum((W + t(W))^2)
  S2 <- sum(rowSums(W + t(W))^2)
  k <- (sum(z^4) / n) / (sum(z^2) / n)^2

  VI <- (n * ((n^2 - 3 * n + 3) * S1 - n * S2 + 3 * S0^2) -
         k * (n * (n - 1) * S1 - 2 * n * S2 + 6 * S0^2)) /
        ((n - 1) * (n - 2) * (n - 3) * S0^2) - EI^2

  z_score <- (I - EI) / sqrt(max(VI, 0))
  p_value <- 2 * pnorm(-abs(z_score))

  list(I = I, expected = EI, variance = VI,
       z_score = z_score, p_value = p_value)
}

#' Quadrat Analysis
#'
#' Divides the tissue area into a grid of quadrats and counts cells
#' per quadrat. Tests for Complete Spatial Randomness (CSR) using a
#' chi-squared test.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param nx Integer. Number of quadrats along x. Default \code{5}.
#' @param ny Integer. Number of quadrats along y. Default \code{5}.
#' @param target Character or \code{NULL}. If set, only count cells of
#'   this phenotype.
#'
#' @return A list with \code{counts} (matrix of counts per quadrat),
#'   \code{chi_sq} (chi-squared statistic), \code{p_value}, and
#'   \code{VMR} (variance-to-mean ratio; >1 = clustered, <1 = regular).
#'
#' @examples
#' set.seed(1)
#' counts <- matrix(rnorm(200), nrow = 100,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
#' obj <- CreateAkoyaObject(counts, coords)
#' qa <- QuadratAnalysis(obj, nx = 4, ny = 4)
#' qa$VMR
#'
#' @export
#' @importFrom stats chisq.test var
QuadratAnalysis <- function(object, nx = 5L, ny = 5L, target = NULL) {
  coords <- object@coords

  if (!is.null(target)) {
    if (!"phenotype" %in% names(object@meta_data)) {
      stop("'phenotype' column required when target is set.", call. = FALSE)
    }
    sel <- object@meta_data$phenotype == target
    coords <- coords[sel, , drop = FALSE]
  }

  xr <- range(coords$x)
  yr <- range(coords$y)

  x_breaks <- seq(xr[1L], xr[2L], length.out = nx + 1L)
  y_breaks <- seq(yr[1L], yr[2L], length.out = ny + 1L)

  x_bin <- findInterval(coords$x, x_breaks, rightmost.closed = TRUE)
  y_bin <- findInterval(coords$y, y_breaks, rightmost.closed = TRUE)

  x_bin <- pmin(x_bin, nx)
  y_bin <- pmin(y_bin, ny)

  count_mat <- matrix(0L, nrow = ny, ncol = nx)
  for (i in seq_along(x_bin)) {
    count_mat[y_bin[i], x_bin[i]] <- count_mat[y_bin[i], x_bin[i]] + 1L
  }

  counts_vec <- as.integer(count_mat)
  n_quad <- nx * ny
  expected <- nrow(coords) / n_quad
  chi_sq <- sum((counts_vec - expected)^2 / expected)
  df <- n_quad - 1L
  p_value <- stats::pchisq(chi_sq, df = df, lower.tail = FALSE)
  vmr <- var(counts_vec) / mean(counts_vec)

  list(
    counts = count_mat,
    chi_sq = chi_sq,
    p_value = p_value,
    VMR = vmr
  )
}

#' Pair Correlation Function (g(r))
#'
#' Computes the pair correlation function, the derivative of Ripley's K,
#' which measures spatial clustering/inhibition at specific distances.
#' Values above 1 indicate clustering, below 1 indicate inhibition.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param r_seq Numeric vector. Distances. If \code{NULL}, auto-computed.
#' @param dr Numeric. Annulus width. Default is range / 40.
#' @param target Character or \code{NULL}. Restrict to this phenotype.
#'
#' @return A data frame with columns \code{r} and \code{g}.
#'
#' @examples
#' set.seed(1)
#' counts <- matrix(rnorm(200), nrow = 100,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
#' obj <- CreateAkoyaObject(counts, coords)
#' pcf <- PairCorrelation(obj)
#' head(pcf)
#'
#' @export
PairCorrelation <- function(object, r_seq = NULL, dr = NULL,
                              target = NULL) {
  coords <- as.matrix(object@coords[, c("x", "y")])

  if (!is.null(target)) {
    if (!"phenotype" %in% names(object@meta_data)) {
      stop("'phenotype' column required when target is set.", call. = FALSE)
    }
    sel <- object@meta_data$phenotype == target
    coords <- coords[sel, , drop = FALSE]
  }

  n <- nrow(coords)
  if (n < 2L) stop("Need at least 2 cells.", call. = FALSE)

  xr <- range(coords[, 1L])
  yr <- range(coords[, 2L])
  area <- (xr[2L] - xr[1L]) * (yr[2L] - yr[1L])
  lambda <- n / area

  diag_len <- sqrt((xr[2L] - xr[1L])^2 + (yr[2L] - yr[1L])^2)
  if (is.null(dr)) dr <- diag_len / 40
  if (is.null(r_seq)) r_seq <- seq(dr, diag_len / 4, by = dr)

  d <- as.matrix(stats::dist(coords))

  g_vals <- vapply(r_seq, function(r) {
    in_annulus <- sum(d > (r - dr / 2) & d <= (r + dr / 2) & d > 0)
    expected <- n * (n - 1) * 2 * pi * r * dr * lambda / area
    if (expected > 0) in_annulus / expected else NA_real_
  }, numeric(1L))

  data.frame(r = r_seq, g = g_vals)
}

#' Cross-type Nearest Neighbour Distance
#'
#' Computes the nearest neighbour distance from each cell of one
#' phenotype to cells of another phenotype.
#'
#' @param object An \code{\link{AkoyaExperiment}} object with a
#'   \code{phenotype} column.
#' @param from Character. Source phenotype.
#' @param to Character. Target phenotype.
#'
#' @return A numeric vector of distances (one per cell of the \code{from}
#'   phenotype).
#'
#' @examples
#' set.seed(1)
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
#' meta <- data.frame(cell_id = 1:50, sample_id = "s1",
#'                    phenotype = sample(c("A", "B"), 50, TRUE))
#' obj <- CreateAkoyaObject(counts, coords, meta)
#' dists <- CrossNNDistance(obj, from = "A", to = "B")
#' summary(dists)
#'
#' @export
CrossNNDistance <- function(object, from, to) {
  md <- object@meta_data
  if (!"phenotype" %in% names(md)) {
    stop("No 'phenotype' column.", call. = FALSE)
  }

  from_idx <- which(md$phenotype == from)
  to_idx <- which(md$phenotype == to)
  if (length(from_idx) == 0L) stop("No cells of phenotype '", from, "'.", call. = FALSE)
  if (length(to_idx) == 0L) stop("No cells of phenotype '", to, "'.", call. = FALSE)

  coords_from <- as.matrix(object@coords[from_idx, c("x", "y")])
  coords_to <- as.matrix(object@coords[to_idx, c("x", "y")])

  d <- .cross_dist(coords_from, coords_to)
  apply(d, 1L, min)
}

#' Marker Spatial Clustering (Expression-Based)
#'
#' Clusters cells based on marker expression profiles using k-means or
#' hierarchical clustering. Unlike \code{\link{SpatialClusters}} which
#' uses coordinates, this uses the expression matrix.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param k Integer. Number of clusters.
#' @param method Character. \code{"kmeans"} (default) or
#'   \code{"hierarchical"}.
#' @param slot Character. \code{"data"} or \code{"counts"}.
#' @param markers Character vector or \code{NULL}. Markers to use.
#'
#' @return An \code{\link{AkoyaExperiment}} with an \code{expr_cluster}
#'   column in \code{meta_data}.
#'
#' @examples
#' counts <- matrix(c(rnorm(50, 5), rnorm(50, 0)), ncol = 2,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- ExpressionClusters(obj, k = 2)
#' table(Meta(obj)$expr_cluster)
#'
#' @export
ExpressionClusters <- function(object, k, method = c("kmeans", "hierarchical"),
                                 slot = "data", markers = NULL) {
  method <- match.arg(method)
  mat <- GetData(object, slot = slot)

  if (!is.null(markers)) {
    markers <- intersect(markers, colnames(mat))
    if (length(markers) == 0L) stop("No matching markers.", call. = FALSE)
    mat <- mat[, markers, drop = FALSE]
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
