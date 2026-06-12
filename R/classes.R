#' The SpatialCellData Class
#'
#' Central S4 class for storing and analysing single-cell spatial biology data.
#' Inspired by the Seurat object design, it holds raw and normalised marker
#' intensities, spatial coordinates, cell-level metadata, and results from
#' spatial analyses in a single container.
#'
#' @slot counts Numeric matrix of raw marker intensities (cells x markers).
#' @slot data Numeric matrix of normalised marker intensities
#'   (cells x markers). Identical to \code{counts} until
#'   \code{\link{NormaliseData}} is called.
#' @slot coords Data frame with columns \code{x} and \code{y} holding
#'   spatial coordinates for each cell.
#' @slot meta_data Data frame of per-cell metadata. Always contains
#'   \code{cell_id} and \code{sample_id}. Additional columns such as
#'   \code{cell_area}, \code{phenotype}, or \code{cluster} are added by
#'   analysis functions.
#' @slot project Character string. Project or experiment name.
#' @slot spatial List for storing spatial analysis results (nearest-neighbour
#'   distances, density values, interaction matrices).
#'
#' @export
#' @importFrom methods setClass new validObject is
setClass("SpatialCellData",
  slots = list(
    counts    = "matrix",
    data      = "matrix",
    coords    = "data.frame",
    meta_data = "data.frame",
    project   = "character",
    spatial   = "list"
  ),
  prototype = list(
    counts    = matrix(numeric(0), nrow = 0, ncol = 0),
    data      = matrix(numeric(0), nrow = 0, ncol = 0),
    coords    = data.frame(x = numeric(0), y = numeric(0)),
    meta_data = data.frame(cell_id = character(0), sample_id = character(0)),
    project   = "SpatialProject",
    spatial   = list()
  )
)

#' Validity check for SpatialCellData
#' @noRd
#' @importFrom methods setValidity
setValidity("SpatialCellData", function(object) {
  errors <- character()
  n <- nrow(object@counts)

  if (n > 0L) {
    if (nrow(object@data) != n) {
      errors <- c(errors, "nrow(data) must equal nrow(counts)")
    }
    if (nrow(object@coords) != n) {
      errors <- c(errors, "nrow(coords) must equal nrow(counts)")
    }
    if (nrow(object@meta_data) != n) {
      errors <- c(errors, "nrow(meta_data) must equal nrow(counts)")
    }
    mk <- colnames(object@counts)
    if (!is.null(mk) && anyDuplicated(mk) > 0L) {
      dups <- unique(mk[duplicated(mk)])
      errors <- c(errors, paste0("marker names must be unique; duplicated: ",
                                 paste(dups, collapse = ", ")))
    }
    if (!all(c("x", "y") %in% names(object@coords))) {
      errors <- c(errors, "coords must contain columns 'x' and 'y'")
    } else if (!all(is.finite(object@coords$x)) ||
               !all(is.finite(object@coords$y))) {
      errors <- c(errors,
                  "coords 'x' and 'y' must be finite (no NA, NaN, or Inf)")
    }
  }

  if (length(errors) == 0L) TRUE else errors
})
