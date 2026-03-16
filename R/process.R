#' Quality Control Filter
#'
#' Removes cells that fail quality control criteria based on cell area
#' and/or total marker intensity.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param min_area Numeric or \code{NULL}. Minimum cell area.
#' @param max_area Numeric or \code{NULL}. Maximum cell area.
#' @param min_intensity Numeric. Minimum total marker intensity. Default
#'   \code{0}.
#' @param max_intensity Numeric or \code{NULL}. Maximum total marker
#'   intensity.
#'
#' @return A filtered \code{\link{AkoyaExperiment}} object.
#'
#' @examples
#' counts <- matrix(rnorm(100, 300, 50), nrow = 20,
#'                  dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK", "CD20")))
#' coords <- data.frame(x = runif(20), y = runif(20))
#' meta <- data.frame(cell_id = 1:20, sample_id = "s1",
#'                    cell_area = c(5, seq(50, 200, length.out = 18), 5000))
#' obj <- CreateAkoyaObject(counts, coords, meta)
#' obj <- QCFilter(obj, min_area = 10, max_area = 1000)
#' NCells(obj)
#'
#' @export
QCFilter <- function(object, min_area = NULL, max_area = NULL,
                      min_intensity = 0, max_intensity = NULL) {
  keep <- rep(TRUE, NCells(object))

  if ("cell_area" %in% names(object@meta_data)) {
    area <- object@meta_data$cell_area
    if (!is.null(min_area)) keep <- keep & area >= min_area
    if (!is.null(max_area)) keep <- keep & area <= max_area
  }

  if (NMarkers(object) > 0L) {
    total <- rowSums(object@counts)
    keep <- keep & total >= min_intensity
    if (!is.null(max_intensity)) keep <- keep & total <= max_intensity
  }

  n_removed <- sum(!keep)
  if (n_removed > 0L) {
    message("QCFilter: removed ", n_removed, " of ", NCells(object), " cells")
  }

  object[keep, ]
}

#' Normalise Marker Intensities
#'
#' Normalises marker intensity values and stores the result in the
#' \code{data} slot of the object. The raw counts remain unchanged.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param method Character. Normalisation method: \code{"zscore"} (default),
#'   \code{"minmax"}, or \code{"quantile"}.
#' @param markers Character vector or \code{NULL}. Markers to normalise. If
#'   \code{NULL}, all markers are normalised.
#'
#' @return An \code{\link{AkoyaExperiment}} with updated \code{data} slot.
#'
#' @examples
#' counts <- matrix(rnorm(100, 500, 100), nrow = 20,
#'                  dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK", "CD20")))
#' coords <- data.frame(x = runif(20), y = runif(20))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- NormaliseData(obj, method = "zscore")
#' head(GetData(obj))
#'
#' @export
#' @importFrom stats sd
NormaliseData <- function(object, method = c("zscore", "minmax", "quantile"),
                           markers = NULL) {
  method <- match.arg(method)
  mat <- object@counts

  cols <- if (!is.null(markers)) {
    intersect(markers, colnames(mat))
  } else {
    colnames(mat)
  }

  if (length(cols) == 0L) {
    warning("No marker columns found to normalise.", call. = FALSE)
    return(object)
  }

  norm <- mat
  for (col in cols) {
    norm[, col] <- .norm_vec(mat[, col], method)
  }

  object@data <- norm
  object
}

#' @noRd
.norm_vec <- function(x, method) {
  switch(method,
    zscore = {
      mu <- mean(x, na.rm = TRUE)
      s <- sd(x, na.rm = TRUE)
      if (is.na(s) || s == 0) return(x - mu)
      (x - mu) / s
    },
    minmax = {
      mn <- min(x, na.rm = TRUE)
      mx <- max(x, na.rm = TRUE)
      rng <- mx - mn
      if (rng == 0) return(rep(0, length(x)))
      (x - mn) / rng
    },
    quantile = {
      ranks <- rank(x, na.last = "keep", ties.method = "average")
      n <- sum(!is.na(x))
      if (n <= 1L) return(rep(0, length(x)))
      (ranks - 1) / (n - 1)
    }
  )
}

#' Phenotype Cells by Marker Thresholds
#'
#' Assigns phenotype labels to cells based on whether marker intensities
#' exceed given thresholds. Uses the normalised \code{data} slot.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param thresholds Named list. Marker names as names, numeric thresholds
#'   as values. Example: \code{list(CD3 = 0.5, CD8 = 0.3)}.
#' @param labels Named character vector or \code{NULL}. Maps auto-generated
#'   signature strings to custom labels. When \code{NULL}, phenotypes are
#'   labelled by concatenating positive markers (e.g. \code{"CD3+/CD8+"}).
#'
#' @return An \code{\link{AkoyaExperiment}} with a \code{phenotype} column
#'   added to \code{meta_data}.
#'
#' @examples
#' counts <- matrix(c(0.8, 0.1, 0.9, 0.1,
#'                    0.1, 0.8, 0.7, 0.1), ncol = 2,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(4), y = runif(4))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0.5, CD8 = 0.5))
#' Meta(obj)$phenotype
#'
#' @export
PhenotypeCells <- function(object, thresholds, labels = NULL) {
  markers <- names(thresholds)
  missing <- setdiff(markers, colnames(object@data))
  if (length(missing) > 0L) {
    stop("Markers not found: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }

  mat <- object@data[, markers, drop = FALSE]
  thresh <- unlist(thresholds[markers])

  # Positivity matrix
  pos <- sweep(mat, 2L, thresh, FUN = ">=")

  pheno <- apply(pos, 1L, function(row) {
    positive <- markers[row]
    if (length(positive) == 0L) return("Negative")
    paste0(positive, "+", collapse = "/")
  })

  if (!is.null(labels)) {
    matched <- labels[pheno]
    pheno <- ifelse(is.na(matched), pheno, matched)
  }

  object@meta_data$phenotype <- pheno
  object
}

#' Summarise Phenotype Proportions
#'
#' Computes phenotype counts and proportions per sample.
#'
#' @param object An \code{\link{AkoyaExperiment}} object with a
#'   \code{phenotype} column in its metadata.
#'
#' @return A data frame with columns \code{sample_id}, \code{phenotype},
#'   \code{count}, and \code{proportion}.
#'
#' @examples
#' counts <- matrix(rnorm(50), nrow = 10,
#'                  dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK", "CD20")))
#' coords <- data.frame(x = runif(10), y = runif(10))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0))
#' PhenotypeSummary(obj)
#'
#' @export
PhenotypeSummary <- function(object) {
  md <- object@meta_data
  if (!"phenotype" %in% names(md)) {
    stop("No 'phenotype' column. Run PhenotypeCells() first.", call. = FALSE)
  }

  counts <- as.data.frame(table(
    sample_id = md$sample_id,
    phenotype = md$phenotype
  ), stringsAsFactors = FALSE)
  names(counts)[3L] <- "count"

  # Compute proportions per sample
  totals <- tapply(counts$count, counts$sample_id, sum)
  counts$proportion <- counts$count / totals[counts$sample_id]

  counts[order(counts$sample_id, -counts$count), ]
}
