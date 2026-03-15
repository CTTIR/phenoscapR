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
  # Pairwise distances
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
  # Efficient cross-distance without building full (n+m) x (n+m) matrix
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

  # Observed neighbour counts
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

  # Expected under random mixing
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
