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
