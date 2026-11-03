#' The SpatialCellData Class
#'
#' Central S4 class for storing and analysing single-cell spatial biology data.
#' Inspired by the Seurat object design, it holds raw and normalised marker
#' intensities, spatial coordinates, cell-level metadata, and results from
#' spatial analyses in a single container.
#'
#' @details Raw and normalized matrices must have identical dimensions and
#'   row/marker names. They contain real numeric values; `NA` and `NaN` are
#'   allowed, infinity is not. Coordinates are finite real numeric vectors, and
#'   coordinate/metadata row counts must agree even for empty objects.
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
#' @slot reductions Named list of dimensionality-reduction embeddings. Each
#'   element is a numeric matrix with one row per cell (e.g. \code{"pca"},
#'   \code{"umap"}, \code{"tsne"}, \code{"song"}), as produced by
#'   \code{\link{RunPCA}}, \code{\link{RunUMAP}}, \code{\link{RunTSNE}}, or
#'   \code{\link{RunSONG}}.
#'
#' @export
#' @importFrom methods setClass new validObject is
setClass("SpatialCellData",
  slots = list(
    counts     = "matrix",
    data       = "matrix",
    coords     = "data.frame",
    meta_data  = "data.frame",
    project    = "character",
    spatial    = "list",
    reductions = "list"
  ),
  prototype = list(
    counts     = matrix(numeric(0), nrow = 0, ncol = 0),
    data       = matrix(numeric(0), nrow = 0, ncol = 0),
    coords     = data.frame(x = numeric(0), y = numeric(0)),
    meta_data  = data.frame(cell_id = character(0), sample_id = character(0)),
    project    = "SpatialProject",
    spatial    = list(),
    reductions = list()
  )
)

#' Validity check for SpatialCellData
#' @noRd
#' @importFrom methods setValidity
setValidity("SpatialCellData", function(object) {
  errors <- character()
  n <- nrow(object@counts)

  for (name in c("counts", "data")) {
    values <- methods::slot(object, name)
    if (!typeof(values) %in% c("integer", "double")) {
      errors <- c(errors, paste0(name, " must be a real numeric matrix"))
    } else if (any(is.infinite(values))) {
      errors <- c(errors, paste0(name, " must not contain infinite values; NA/NaN are allowed"))
    }
  }
  if (!identical(dim(object@data), dim(object@counts))) {
    errors <- c(errors, "dimensions of data must equal dimensions of counts")
  }
  if (!identical(dimnames(object@data), dimnames(object@counts))) {
    errors <- c(errors, "data row and marker names must match counts in the same order")
  }
  if (nrow(object@coords) != n) {
    errors <- c(errors, "nrow(coords) must equal nrow(counts)")
  }
  if (nrow(object@meta_data) != n) {
    errors <- c(errors, "nrow(meta_data) must equal nrow(counts)")
  }
  mk <- colnames(object@counts)
  if (!is.null(mk) && (anyNA(mk) || any(!nzchar(mk)))) {
    errors <- c(errors, "marker names must not be missing or empty")
  }
  if (!is.null(mk) && anyDuplicated(mk) > 0L) {
    dups <- unique(mk[duplicated(mk)])
    errors <- c(errors, paste0("marker names must be unique; duplicated: ",
                               paste(dups, collapse = ", ")))
  }
  if (anyDuplicated(names(object@coords)) ||
      !all(c("x", "y") %in% names(object@coords))) {
    errors <- c(errors, "coords must contain unique columns including 'x' and 'y'")
  } else if (!typeof(object@coords$x) %in% c("integer", "double") ||
             !typeof(object@coords$y) %in% c("integer", "double") ||
             is.object(object@coords$x) || is.object(object@coords$y) ||
             !all(is.finite(object@coords$x)) || !all(is.finite(object@coords$y))) {
    errors <- c(errors, "coords 'x' and 'y' must be real numeric and finite (no NA, NaN, or Inf)")
  }
  if (anyDuplicated(names(object@meta_data)) ||
      !all(c("cell_id", "sample_id") %in% names(object@meta_data))) {
    errors <- c(errors, "meta_data must contain unique columns including cell_id and sample_id")
  }

  if (length(errors) == 0L) TRUE else errors
})
