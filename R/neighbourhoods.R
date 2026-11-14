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
#' @details Sample identifiers and phenotype labels must be complete, nonblank
#'   vectors. Counts and k must be positive whole numbers; malformed inputs are
#'   rejected before clustering or changing the random state. Cells in singleton
#'   samples have no neighbour composition: they retain their row and receive
#'   an `NA` neighbourhood label, and are excluded from clustering. Centres are
#'   cell-weighted means of defined composition vectors, not equal-sample means.
#'   The requested number of centres cannot exceed the distinct defined vectors.
#'   With no defined vectors (including empty input), no clustering or random
#'   draws occur and the centre matrix has zero rows.
#'
#' @return The object with a \code{neighbourhood} column in \code{meta_data};
#'   the neighbourhood-by-phenotype composition matrix is stored in
#'   \code{object@spatial$neighbourhood_composition}. Availability is recorded
#'   in `object@spatial$neighbourhood_availability`: `per_cell` retains cell/sample
#'   IDs, input `row_index` and status (`defined` or `no_neighbors`); `by_sample`
#'   reports `n_total`, `n_defined` and `n_unavailable`. The `weighting` field
#'   records `cell`. Existing metadata other than the neighbourhood label is
#'   preserved.
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
  .spatial_object_inputs(object)
  .spatial_whole_scalar(k, "k")
  .spatial_whole_scalar(n_neighbourhoods, "n_neighbourhoods")
  .spatial_seed(seed)
  if (!is.character(phenotype_col) || length(phenotype_col) != 1L ||
      !is.null(dim(phenotype_col)) || is.na(phenotype_col)) {
    stop("phenotype_col must be one nonmissing column name.", call. = FALSE)
  }
  if (!phenotype_col %in% names(object@meta_data)) {
    stop("Phenotype column '", phenotype_col, "' not found. Run ",
         "PhenotypeCells() first.", call. = FALSE)
  }
  labels <- object@meta_data[[phenotype_col]]
  if (!is.atomic(labels) || !is.null(dim(labels)) ||
      length(labels) != NCells(object) || anyNA(labels) ||
      any(!nzchar(trimws(as.character(labels))))) {
    stop("Phenotypes must be a complete, nonblank vector with one value per cell.",
         call. = FALSE)
  }
  pheno <- as.character(labels)
  phenos <- sort(unique(pheno))
  comp <- matrix(NA_real_, nrow = NCells(object), ncol = length(phenos),
                 dimnames = list(NULL, phenos))

  available <- rep(FALSE, NCells(object))
  samples <- unique(object@meta_data$sample_id)
  for (s in samples) {
    rows <- which(object@meta_data$sample_id == s)
    if (length(rows) < 2L) next
    available[rows] <- TRUE
    kk <- min(k, length(rows) - 1L)
    kn <- .knn_index(as.matrix(object@coords[rows, , drop = FALSE]), kk)
    nbr_labels <- matrix(pheno[rows][kn$idx], nrow = length(rows))
    for (p in phenos) {
      comp[rows, p] <- rowMeans(nbr_labels == p)
    }
  }

  assignments <- rep(NA_character_, NCells(object))
  centres <- matrix(numeric(), nrow = 0L, ncol = length(phenos),
                    dimnames = list(character(), phenos))
  if (any(available)) {
    defined <- comp[available, , drop = FALSE]
    if (n_neighbourhoods > nrow(unique(defined))) {
      stop("n_neighbourhoods exceeds the number of distinct defined composition vectors.",
           call. = FALSE)
    }
    if (!is.null(seed)) set.seed(seed)
    km <- stats::kmeans(defined, centers = n_neighbourhoods, nstart = 10L)
    assignments[available] <- paste0("CN", km$cluster)
    centres <- km$centers
    rownames(centres) <- paste0("CN", seq_len(nrow(centres)))
  }
  availability <- object@meta_data[, c("cell_id", "sample_id"), drop = FALSE]
  availability$row_index <- seq_len(NCells(object))
  availability$status <- rep("no_neighbors", NCells(object))
  availability$status[available] <- "defined"
  n_total <- tabulate(match(object@meta_data$sample_id, samples), nbins = length(samples))
  n_defined <- n_total
  n_defined[n_total < 2L] <- 0L
  summary <- data.frame(sample_id = samples, n_total = n_total,
                        n_defined = n_defined, n_unavailable = n_total - n_defined)
  object <- .clear_frozen_spatial_label(object, "neighbourhood")
  object@meta_data$neighbourhood <- assignments
  object@spatial$neighbourhood_composition <- centres
  object@spatial$neighbourhood_availability <- list(
    per_cell = availability, by_sample = summary, weighting = "cell")
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
#' @details Sample identifiers must be complete, nonblank vectors. Counts and
#'   k must be positive whole numbers, validated before smoothing or RNG use.
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
  .spatial_object_inputs(object)
  .spatial_whole_scalar(k, "k")
  .spatial_whole_scalar(n_domains, "n_domains")
  .spatial_seed(seed)
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
  object <- .clear_frozen_spatial_label(object, "domain")
  object@meta_data$domain <- paste0("D", km$cluster)
  object
}
