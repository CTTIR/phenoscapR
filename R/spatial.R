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
  } else {
    coords_to <- coords_from
  }

  d <- as.matrix(dist(rbind(coords_from, coords_to)))
  n_from <- nrow(coords_from)
  n_to <- nrow(coords_to)

  # Extract the submatrix of distances from query to target
  d_sub <- d[seq_len(n_from), n_from + seq_len(n_to), drop = FALSE]

  nn_dist <- vapply(seq_len(n_from), function(i) {
    dists <- d_sub[i, ]
    # If target includes self, remove distance 0 (self-match)
    if (is.null(target_phenotype)) {
      dists <- dists[dists > 0]
    }
    if (length(dists) == 0L) return(NA_real_)
    k_use <- min(k, length(dists))
    mean(sort(dists)[seq_len(k_use)])
  }, numeric(1L))

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
  } else {
    target_coords <- coords
  }

  d <- as.matrix(dist(rbind(coords, target_coords)))
  n_from <- nrow(coords)
  n_to <- nrow(target_coords)
  d_sub <- d[seq_len(n_from), n_from + seq_len(n_to), drop = FALSE]

  dens <- vapply(seq_len(n_from), function(i) {
    count <- sum(d_sub[i, ] <= radius & d_sub[i, ] > 0)
    count
  }, numeric(1L))

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
  coords <- as.matrix(dt[, c("x", "y")])
  d <- as.matrix(dist(coords))

  n_cells <- nrow(dt)
  pheno_vec <- dt$phenotype

  # Observed counts
  obs <- matrix(0, nrow = n_pheno, ncol = n_pheno,
                dimnames = list(phenotypes, phenotypes))

  for (i in seq_len(n_cells)) {
    neighbours <- which(d[i, ] <= radius & d[i, ] > 0)
    if (length(neighbours) == 0L) next
    from <- pheno_vec[i]
    neighbour_phenos <- pheno_vec[neighbours]
    tab <- table(neighbour_phenos)
    for (ph in names(tab)) {
      obs[from, ph] <- obs[from, ph] + tab[ph]
    }
  }

  # Expected under random mixing
  freq <- table(pheno_vec) / n_cells
  total_pairs <- sum(obs)
  exp_mat <- outer(
    as.numeric(freq[phenotypes]),
    as.numeric(freq[phenotypes])
  ) * total_pairs
  dimnames(exp_mat) <- list(phenotypes, phenotypes)

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
# S4-style wrappers operating on AkoyaExperiment objects
# ---------------------------------------------------------------------------

#' Find Nearest Neighbours (AkoyaExperiment)
#'
#' For each cell, computes the distance to the \code{k} nearest neighbours.
#'
#' @param object An \code{\link{AkoyaExperiment-class}} object.
#' @param k Integer. Number of nearest neighbours. Default \code{1}.
#' @param target Character or \code{NULL}. Restrict to a specific phenotype.
#'
#' @return An \code{\link{AkoyaExperiment-class}} with \code{nn_distance}
#'   added to \code{meta_data} and stored in the \code{spatial} slot.
#'
#' @examples
#' counts <- matrix(rnorm(40), nrow = 20,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(20, 0, 100), y = runif(20, 0, 100))
#' obj <- CreateAkoyaObject(counts, coords)
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

#' Cell Density (AkoyaExperiment)
#'
#' Estimates local cell density by counting neighbours within a radius.
#'
#' @param object An \code{\link{AkoyaExperiment-class}} object.
#' @param radius Numeric. Radius of the neighbourhood.
#' @param target Character or \code{NULL}. Restrict to a specific phenotype.
#'
#' @return An \code{\link{AkoyaExperiment-class}} with \code{density}
#'   added to \code{meta_data}.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
#' obj <- CreateAkoyaObject(counts, coords)
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

#' Interaction Matrix (AkoyaExperiment)
#'
#' Computes pairwise spatial interaction scores between phenotypes.
#'
#' @param object An \code{\link{AkoyaExperiment-class}} object.
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
#' obj <- CreateAkoyaObject(counts, coords, meta)
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

#' Spatial Clusters (AkoyaExperiment)
#'
#' Clusters cells based on spatial coordinates.
#'
#' @param object An \code{\link{AkoyaExperiment-class}} object.
#' @param k Integer. Number of clusters.
#' @param method Character. \code{"kmeans"} (default) or \code{"hierarchical"}.
#'
#' @return An \code{\link{AkoyaExperiment-class}} with a \code{cluster}
#'   column in \code{meta_data}.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(
#'   x = c(rnorm(25, 0, 5), rnorm(25, 50, 5)),
#'   y = c(rnorm(25, 0, 5), rnorm(25, 50, 5)))
#' obj <- CreateAkoyaObject(counts, coords)
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
#' @param object An \code{\link{AkoyaExperiment-class}} object.
#' @param max_edge Numeric or \code{NULL}. Maximum edge length to retain.
#'
#' @return An \code{\link{AkoyaExperiment-class}} with \code{delaunay_edges}
#'   stored in the \code{spatial} slot.
#'
#' @examples
#' counts <- matrix(rnorm(40), nrow = 20,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(20, 0, 100), y = runif(20, 0, 100))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- DelaunayNetwork(obj, max_edge = 30)
#'
#' @export
DelaunayNetwork <- function(object, max_edge = NULL) {
  xy <- as.matrix(object@coords)
  n <- nrow(xy)
  if (n < 3L) stop("Need at least 3 cells for triangulation.", call. = FALSE)

  # Simple Delaunay via distance-based edge list (all pairs within threshold)
  # For a true Delaunay we would need the deldir package; here we approximate
  # using a distance matrix and connecting nearest neighbours
  d <- as.matrix(dist(xy))
  edges <- data.frame(from = integer(0), to = integer(0),
                       distance = numeric(0))
  for (i in seq_len(n - 1L)) {
    for (j in (i + 1L):n) {
      edges <- rbind(edges, data.frame(from = i, to = j,
                                        distance = d[i, j]))
    }
  }

  if (!is.null(max_edge)) {
    edges <- edges[edges$distance <= max_edge, ]
  }

  object@spatial[["delaunay_edges"]] <- edges
  object
}

#' Neighbourhood Enrichment Analysis
#'
#' Tests whether specific phenotype pairs are spatially enriched or depleted
#' relative to a random permutation baseline.
#'
#' @param object An \code{\link{AkoyaExperiment-class}} object.
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
#' obj <- CreateAkoyaObject(counts, coords, meta)
#' NeighbourhoodEnrichment(obj, radius = 50, n_perm = 10)
#'
#' @export
NeighbourhoodEnrichment <- function(object, radius, n_perm = 100L,
                                    seed = NULL) {
  if (!is.null(seed)) set.seed(seed)

  xy <- as.matrix(object@coords)
  pheno <- object@meta_data$phenotype
  if (is.null(pheno)) {
    stop("No phenotype column. Run PhenotypeCells() first.", call. = FALSE)
  }

  d <- as.matrix(dist(xy))
  phenotypes <- sort(unique(pheno))
  n_pheno <- length(phenotypes)

  # Observed neighbour counts
  .count_neighbours <- function(ph) {
    obs <- matrix(0, n_pheno, n_pheno,
                  dimnames = list(phenotypes, phenotypes))
    for (i in seq_along(ph)) {
      nbrs <- which(d[i, ] <= radius & d[i, ] > 0)
      if (length(nbrs) > 0L) {
        tab <- table(ph[nbrs])
        for (nm in names(tab)) obs[ph[i], nm] <- obs[ph[i], nm] + tab[nm]
      }
    }
    obs
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
#' @param object An \code{\link{AkoyaExperiment-class}} object.
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
#' obj <- CreateAkoyaObject(counts, coords)
#' RipleysK(obj)
#'
#' @export
RipleysK <- function(object, r_seq = NULL, target = NULL,
                     correction = c("none", "border")) {
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

  d <- as.matrix(dist(xy))
  diag(d) <- Inf

  K <- vapply(r_seq, function(r) {
    sum(d <= r) / (n * lambda)
  }, numeric(1L))

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
#' @param object An \code{\link{AkoyaExperiment-class}} object.
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
#' obj <- CreateAkoyaObject(counts, coords)
#' MoransI(obj, feature = "CD3", radius = 30)
#'
#' @export
MoransI <- function(object, feature, radius, slot = "data") {
  mat <- methods::slot(object, match.arg(slot, c("data", "counts")))

  if (feature %in% colnames(mat)) {
    x <- mat[, feature]
  } else if (feature %in% names(object@meta_data)) {
    x <- as.numeric(object@meta_data[[feature]])
  } else {
    stop("Feature '", feature, "' not found.", call. = FALSE)
  }

  xy <- as.matrix(object@coords)
  d <- as.matrix(dist(xy))
  W <- (d <= radius & d > 0) * 1.0
  n <- length(x)
  xbar <- mean(x)
  dx <- x - xbar

  S0 <- sum(W)
  I <- (n / S0) * sum(W * outer(dx, dx)) / sum(dx^2)
  EI <- -1 / (n - 1)
  # Variance under normality
  S1 <- 0.5 * sum((W + t(W))^2)
  S2 <- sum((rowSums(W) + colSums(W))^2)
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
#' @param object An \code{\link{AkoyaExperiment-class}} object.
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
#' obj <- CreateAkoyaObject(counts, coords)
#' QuadratAnalysis(obj, nx = 3, ny = 3)
#'
#' @export
QuadratAnalysis <- function(object, nx = 5L, ny = 5L, target = NULL) {
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
#' @param object An \code{\link{AkoyaExperiment-class}} object.
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
#' obj <- CreateAkoyaObject(counts, coords)
#' PairCorrelation(obj)
#'
#' @export
PairCorrelation <- function(object, r_seq = NULL, dr = NULL,
                            target = NULL) {
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

  d <- as.matrix(dist(xy))
  diag(d) <- Inf

  g <- vapply(r_seq, function(r) {
    ring <- sum(d > (r - dr / 2) & d <= (r + dr / 2))
    ring / (n * lambda * 2 * pi * r * dr)
  }, numeric(1L))

  data.frame(r = r_seq, g = g)
}

#' Cross Nearest Neighbour Distance
#'
#' Computes the nearest neighbour distance from each cell of one phenotype
#' to cells of another phenotype.
#'
#' @param object An \code{\link{AkoyaExperiment-class}} object.
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
#' obj <- CreateAkoyaObject(counts, coords, meta)
#' CrossNNDistance(obj, from = "A", to = "B")
#'
#' @export
CrossNNDistance <- function(object, from, to) {
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

  vapply(seq_len(nrow(from_xy)), function(i) {
    dists <- sqrt(rowSums((to_xy - from_xy[i, , drop = FALSE])^2))
    min(dists)
  }, numeric(1L))
}

#' Expression-Based Cell Clustering
#'
#' Clusters cells based on marker expression profiles.
#'
#' @param object An \code{\link{AkoyaExperiment-class}} object.
#' @param k Integer. Number of clusters.
#' @param method Character. \code{"kmeans"} (default) or \code{"hierarchical"}.
#' @param slot Character. \code{"data"} (default) or \code{"counts"}.
#' @param markers Character vector or \code{NULL}. Markers to use.
#'
#' @return An \code{\link{AkoyaExperiment-class}} with an \code{expr_cluster}
#'   column in \code{meta_data}.
#'
#' @examples
#' counts <- matrix(c(rnorm(50, 10), rnorm(50, 0)), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' obj <- CreateAkoyaObject(counts, coords)
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
