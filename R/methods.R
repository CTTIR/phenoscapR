#' Show an AkoyaExperiment
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#'
#' @export
#' @importFrom methods setMethod show
setMethod("show", "AkoyaExperiment", function(object) {
  n_cells <- NCells(object)
  n_markers <- NMarkers(object)
  markers <- if (n_markers > 0L) {
    mk <- Markers(object)
    if (length(mk) > 6L) {
      paste(c(mk[1:5], paste0("... (", length(mk), " total)")),
            collapse = ", ")
    } else {
      paste(mk, collapse = ", ")
    }
  } else {
    "none"
  }
  samples <- unique(object@meta_data$sample_id)
  n_samples <- length(samples)
  has_pheno <- "phenotype" %in% names(object@meta_data)
  has_norm <- !identical(object@counts, object@data)

  cat("An AkoyaExperiment object\n")
  cat(" ", n_cells, "cells across", n_samples,
      if (n_samples == 1L) "sample\n" else "samples\n")
  cat("  Markers:", markers, "\n")
  cat("  Normalised:", has_norm, "\n")
  if (has_pheno) {
    phenos <- unique(object@meta_data$phenotype)
    cat("  Phenotypes:", length(phenos), "\n")
  }
  if (length(object@spatial) > 0L) {
    cat("  Spatial results:", paste(names(object@spatial), collapse = ", "),
        "\n")
  }
  cat("  Project:", object@project, "\n")
})

# --- Accessors ---------------------------------------------------------------

#' Get the Number of Cells
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @return Integer.
#' @export
#' @importFrom methods setGeneric setMethod
setGeneric("NCells", function(object) standardGeneric("NCells"))

#' @rdname NCells
#' @export
setMethod("NCells", "AkoyaExperiment", function(object) {
  nrow(object@counts)
})

#' Get the Number of Markers
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @return Integer.
#' @export
setGeneric("NMarkers", function(object) standardGeneric("NMarkers"))

#' @rdname NMarkers
#' @export
setMethod("NMarkers", "AkoyaExperiment", function(object) {
  ncol(object@counts)
})

#' Get Marker Names
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @return Character vector.
#' @export
setGeneric("Markers", function(object) standardGeneric("Markers"))

#' @rdname Markers
#' @export
setMethod("Markers", "AkoyaExperiment", function(object) {
  colnames(object@counts)
})

#' Get Spatial Coordinates
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @return Data frame with columns \code{x} and \code{y}.
#' @export
setGeneric("Coords", function(object) standardGeneric("Coords"))

#' @rdname Coords
#' @export
setMethod("Coords", "AkoyaExperiment", function(object) {
  object@coords
})

#' Get or Set Cell Metadata
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @return Data frame of cell metadata.
#' @export
setGeneric("Meta", function(object) standardGeneric("Meta"))

#' @rdname Meta
#' @export
setMethod("Meta", "AkoyaExperiment", function(object) {
  object@meta_data
})

#' Get Expression Data
#'
#' Retrieve raw counts or normalised data from an AkoyaExperiment.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param slot Character. \code{"counts"} for raw data or \code{"data"}
#'   (default) for normalised data.
#' @return A numeric matrix (cells x markers).
#' @export
setGeneric("GetData", function(object, slot = "data")
  standardGeneric("GetData"))

#' @rdname GetData
#' @export
setMethod("GetData", "AkoyaExperiment", function(object, slot = "data") {
  slot <- match.arg(slot, c("data", "counts"))
  methods::slot(object, slot)
})

#' Get Active Cell Identities
#'
#' Returns the phenotype labels if set, otherwise sample identities.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @return A character vector.
#' @export
setGeneric("Idents", function(object) standardGeneric("Idents"))

#' @rdname Idents
#' @export
setMethod("Idents", "AkoyaExperiment", function(object) {
  md <- object@meta_data
  if ("phenotype" %in% names(md)) md$phenotype else md$sample_id
})

# --- Subsetting --------------------------------------------------------------

#' Subset an AkoyaExperiment
#'
#' @param x An \code{\link{AkoyaExperiment}} object.
#' @param i Cell indices (integer or logical).
#' @param j Marker indices (integer, logical, or character).
#' @param drop Ignored.
#' @return A subsetted \code{AkoyaExperiment}.
#' @export
setMethod("[", signature(x = "AkoyaExperiment"), function(x, i, j, drop = FALSE) {
  if (!missing(i)) {
    x@counts    <- x@counts[i, , drop = FALSE]
    x@data      <- x@data[i, , drop = FALSE]
    x@coords    <- x@coords[i, , drop = FALSE]
    x@meta_data <- x@meta_data[i, , drop = FALSE]
    rownames(x@meta_data) <- NULL
  }
  if (!missing(j)) {
    x@counts <- x@counts[, j, drop = FALSE]
    x@data   <- x@data[, j, drop = FALSE]
  }
  methods::validObject(x)
  x
})

#' Access metadata columns with [[
#'
#' @param x An \code{\link{AkoyaExperiment}} object.
#' @param i Column name (character).
#' @return The requested metadata column.
#' @export
setMethod("[[", signature(x = "AkoyaExperiment"), function(x, i) {
  x@meta_data[[i]]
})

#' Access metadata columns with $
#'
#' @param x An \code{\link{AkoyaExperiment}} object.
#' @param name Column name.
#' @return The requested metadata column.
#' @export
setMethod("$", signature(x = "AkoyaExperiment"), function(x, name) {
  x@meta_data[[name]]
})

#' Get dimensions of an AkoyaExperiment
#'
#' @param x An \code{\link{AkoyaExperiment}} object.
#' @return Integer vector: number of cells, number of markers.
#' @export
setMethod("dim", "AkoyaExperiment", function(x) {
  dim(x@counts)
})
