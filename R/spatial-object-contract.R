# Shared validation for object-level neighbourhood and autocorrelation analyses.
.spatial_whole_scalar <- function(value, name, minimum = 1) {
  if (!typeof(value) %in% c("integer", "double") || is.object(value) ||
      length(value) != 1L || !is.null(dim(value)) || !is.finite(value) ||
      value < minimum || value != floor(value) || value > .Machine$integer.max) {
    stop(name, " must be one whole number >= ", minimum,
         " within the supported integer range.", call. = FALSE)
  }
  invisible(NULL)
}

.spatial_seed <- function(seed) {
  if (!is.null(seed)) {
    if (!typeof(seed) %in% c("integer", "double") || is.object(seed) ||
        length(seed) != 1L || !is.null(dim(seed)) || !is.finite(seed) ||
        seed != floor(seed) || abs(seed) > .Machine$integer.max) {
      stop("seed must be NULL or one supported signed integer.", call. = FALSE)
    }
  }
  invisible(NULL)
}

.spatial_object_inputs <- function(object) {
  methods::validObject(object)
  ids <- object@meta_data$sample_id
  if (!is.atomic(ids) || !is.null(dim(ids)) || length(ids) != NCells(object) ||
      anyNA(ids) || any(!nzchar(trimws(as.character(ids))))) {
    stop("sample_id must be a complete, nonblank vector with one value per cell.",
         call. = FALSE)
  }
  for (name in c("x", "y")) {
    value <- object@coords[[name]]
    if (!typeof(value) %in% c("integer", "double") || is.object(value) ||
        !is.null(dim(value)) || length(value) != NCells(object) ||
        any(!is.finite(value))) {
      stop("Coordinates must be finite real numeric vectors.", call. = FALSE)
    }
  }
  invisible(NULL)
}

# Project only named axes for the package's two-dimensional analyses.
# Extra coordinate metadata stays in the object and never enters distance math.
.spatial_xy <- function(object) {
  coords <- object@coords
  if (anyDuplicated(names(coords)) || !all(c("x", "y") %in% names(coords)) ||
      nrow(coords) != NCells(object)) {
    stop("Coordinates must contain unique x/y columns and one row per cell.",
         call. = FALSE)
  }
  for (axis in c("x", "y")) {
    value <- coords[[axis]]
    if (!typeof(value) %in% c("integer", "double") || is.object(value) ||
        !is.null(dim(value)) || length(value) != nrow(coords) ||
        any(!is.finite(value))) {
      stop("x and y must be finite real numeric vectors with one value per cell.",
           call. = FALSE)
    }
  }
  as.matrix(coords[, c("x", "y"), drop = FALSE])
}
