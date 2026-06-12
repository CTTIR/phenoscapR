# ============================================================================
# neighbourhoods.R -- Cellular neighbourhoods (niches) and spatial domains
# ----------------------------------------------------------------------------
# Higher-order spatial structure: group cells by the *composition* of their
# local neighbourhood (cellular neighbourhoods / niches), or by spatially
# smoothed expression (spatial domains). Both are sample-aware (neighbours are
# never drawn across tissues) and clustered globally so labels are comparable
# across samples. Base R only.
# ============================================================================

#' Cellular Neighbourhoods (Niches)
#'
#' Assigns each cell to a cellular neighbourhood ("niche") by clustering cells
#' on the phenotype composition of their local spatial neighbourhood. This is
#' the windowed-neighbourhood approach popularised for multiplexed imaging:
#' for every cell the phenotype frequencies among its \code{k} nearest
#' neighbours form a composition vector, and those vectors are clustered.
#'
#' @param object A \code{\link{SpatialCellData-class}} object with a phenotype
#'   column.
#' @param n_neighbourhoods Integer. Number of neighbourhoods to find. Default
#'   \code{8}.
#' @param k Integer. Neighbourhood size (nearest neighbours per cell). Default
#'   \code{20}.
#' @param phenotype_col Character. Metadata column of phenotype labels. Default
#'   \code{"phenotype"}.
#' @param seed Integer or \code{NULL}. Random seed for k-means.
#'
#' @return The object with a \code{neighbourhood} column in \code{meta_data};
#'   the neighbourhood-by-phenotype composition matrix is stored in
#'   \code{object@spatial$neighbourhood_composition}.
#'
#' @examples
#' data(phenoscapR_example)
#' obj <- phenoscapR_example
#' obj@meta_data$phenotype <- obj@meta_data$phenotype_true
#' obj <- CellularNeighbourhoods(obj, n_neighbourhoods = 5, k = 15, seed = 1)
#' table(obj$neighbourhood)
#'
#' @export
CellularNeighbourhoods <- function(object, n_neighbourhoods = 8L, k = 20L,
                                   phenotype_col = "phenotype", seed = NULL) {
  if (!phenotype_col %in% names(object@meta_data)) {
    stop("Phenotype column '", phenotype_col, "' not found. Run ",
         "PhenotypeCells() first.", call. = FALSE)
  }
  pheno <- as.character(object@meta_data[[phenotype_col]])
  phenos <- sort(unique(pheno))
  comp <- matrix(0, nrow = NCells(object), ncol = length(phenos),
                 dimnames = list(NULL, phenos))

  samples <- unique(object@meta_data$sample_id)
  for (s in samples) {
    rows <- which(object@meta_data$sample_id == s)
    if (length(rows) < 2L) next
    kk <- min(k, length(rows) - 1L)
    kn <- .knn_index(as.matrix(object@coords[rows, , drop = FALSE]), kk)
    nbr_labels <- matrix(pheno[rows][kn$idx], nrow = length(rows))
    for (p in phenos) {
      comp[rows, p] <- rowMeans(nbr_labels == p)
    }
  }

  if (!is.null(seed)) set.seed(seed)
  km <- stats::kmeans(comp, centers = n_neighbourhoods, nstart = 10L)
  object@meta_data$neighbourhood <- paste0("CN", km$cluster)
  centres <- km$centers
  rownames(centres) <- paste0("CN", seq_len(nrow(centres)))
  object@spatial$neighbourhood_composition <- centres
  object
}

#' Spatial Domains
#'
#' Partitions the tissue into spatial domains (regions of coherent marker
#' expression) by clustering cells on their spatially smoothed expression:
#' each cell's profile is averaged with its \code{k} nearest neighbours before
#' clustering, so neighbouring cells tend to share a domain.
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @param n_domains Integer. Number of domains. Default \code{6}.
#' @param k Integer. Number of neighbours to smooth over. Default \code{20}.
#' @param slot Character. \code{"data"} (default) or \code{"counts"}.
#' @param markers Character vector or \code{NULL}. Markers to use; \code{NULL}
#'   uses all.
#' @param seed Integer or \code{NULL}. Random seed for k-means.
#'
#' @return The object with a \code{domain} column in \code{meta_data}.
#'
#' @examples
#' data(phenoscapR_example)
#' obj <- NormaliseData(phenoscapR_example, "zscore")
#' obj <- SpatialDomains(obj, n_domains = 4, k = 15, seed = 1)
#' table(obj$domain)
#'
#' @export
SpatialDomains <- function(object, n_domains = 6L, k = 20L, slot = "data",
                           markers = NULL, seed = NULL) {
  mat <- methods::slot(object, match.arg(slot, c("data", "counts")))
  if (!is.null(markers)) {
    mat <- mat[, intersect(markers, colnames(mat)), drop = FALSE]
  }
  smoothed <- matrix(0, nrow = nrow(mat), ncol = ncol(mat),
                     dimnames = dimnames(mat))

  for (s in unique(object@meta_data$sample_id)) {
    rows <- which(object@meta_data$sample_id == s)
    E <- mat[rows, , drop = FALSE]
    if (length(rows) < 2L) {
      smoothed[rows, ] <- E
      next
    }
    kk <- min(k, length(rows) - 1L)
    kn <- .knn_index(as.matrix(object@coords[rows, , drop = FALSE]), kk)
    acc <- E
    for (j in seq_len(ncol(kn$idx))) {
      acc <- acc + E[kn$idx[, j], , drop = FALSE]
    }
    smoothed[rows, ] <- acc / (kk + 1L)
  }

  if (!is.null(seed)) set.seed(seed)
  km <- stats::kmeans(smoothed, centers = n_domains, nstart = 10L)
  object@meta_data$domain <- paste0("D", km$cluster)
  object
}
