#' Show a SpatialCellData Object
#'
#' @param object A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#'
#' @export
#' @importFrom methods setMethod show
setMethod("show", "SpatialCellData", function(object) {
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

  cat("A SpatialCellData object\n")
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
  if (length(object@reductions) > 0L) {
    cat("  Reductions:", paste(names(object@reductions), collapse = ", "),
        "\n")
  }
  cat("  Project:", object@project, "\n")
})

# --- Accessors ---------------------------------------------------------------

#' Get the Number of Cells
#'
#' @param object A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @return Integer.
#' @export
#' @importFrom methods setGeneric setMethod
setGeneric("NCells", function(object) standardGeneric("NCells"))

#' @rdname NCells
#' @export
setMethod("NCells", "SpatialCellData", function(object) {
  nrow(object@counts)
})

#' Get the Number of Markers
#'
#' @param object A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @return Integer.
#' @export
setGeneric("NMarkers", function(object) standardGeneric("NMarkers"))

#' @rdname NMarkers
#' @export
setMethod("NMarkers", "SpatialCellData", function(object) {
  ncol(object@counts)
})

#' Get Marker Names
#'
#' @param object A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @return Character vector.
#' @export
setGeneric("Markers", function(object) standardGeneric("Markers"))

#' @rdname Markers
#' @export
setMethod("Markers", "SpatialCellData", function(object) {
  colnames(object@counts)
})

#' Get Spatial Coordinates
#'
#' @param object A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @return Data frame with columns \code{x} and \code{y}.
#' @export
setGeneric("Coords", function(object) standardGeneric("Coords"))

#' @rdname Coords
#' @export
setMethod("Coords", "SpatialCellData", function(object) {
  object@coords
})

#' Get or Set Cell Metadata
#'
#' @param object A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @return Data frame of cell metadata.
#' @export
setGeneric("Meta", function(object) standardGeneric("Meta"))

#' @rdname Meta
#' @export
setMethod("Meta", "SpatialCellData", function(object) {
  object@meta_data
})

#' Get Expression Data
#'
#' Retrieve raw counts or normalised data from a SpatialCellData object.
#'
#' @param object A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param slot Character. \code{"counts"} for raw data or \code{"data"}
#'   (default) for normalised data.
#' @return A numeric matrix (cells x markers).
#' @export
setGeneric("GetData", function(object, slot = "data") {
  standardGeneric("GetData")
})

#' @rdname GetData
#' @export
setMethod("GetData", "SpatialCellData", function(object, slot = "data") {
  slot <- match.arg(slot, c("data", "counts"))
  methods::slot(object, slot)
})

#' Get Active Cell Identities
#'
#' Returns the phenotype labels if set, otherwise sample identities.
#'
#' @param object A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @return A character vector.
#' @export
setGeneric("Idents", function(object) standardGeneric("Idents"))

#' @rdname Idents
#' @export
setMethod("Idents", "SpatialCellData", function(object) {
  md <- object@meta_data
  if ("phenotype" %in% names(md)) md$phenotype else md$sample_id
})

# --- Subsetting --------------------------------------------------------------

#' Subset a SpatialCellData Object
#'
#' @param x A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param i Cell indices (integer or logical).
#' @param j Marker indices (integer, logical, or character).
#' @param drop Ignored.
#' @return A subsetted \code{SpatialCellData} object.
#' @export
setMethod("[", signature(x = "SpatialCellData"), function(x, i, j, drop = FALSE) {
  if (!missing(i)) {
    x@counts    <- x@counts[i, , drop = FALSE]
    x@data      <- x@data[i, , drop = FALSE]
    x@coords    <- x@coords[i, , drop = FALSE]
    x@meta_data <- x@meta_data[i, , drop = FALSE]
    rownames(x@meta_data) <- NULL
    if (length(x@reductions) > 0L) {
      x@reductions <- lapply(x@reductions, function(e) e[i, , drop = FALSE])
    }
  }
  if (!missing(j)) {
    x@counts <- x@counts[, j, drop = FALSE]
    x@data   <- x@data[, j, drop = FALSE]
  }
  methods::validObject(x)
  x
})

#' Access Metadata Columns with [[
#'
#' @param x A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param i Column name (character).
#' @return The requested metadata column.
#' @export
setMethod("[[", signature(x = "SpatialCellData"), function(x, i) {
  x@meta_data[[i]]
})

#' Access Metadata Columns with $
#'
#' @param x A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param name Column name.
#' @return The requested metadata column.
#' @export
setMethod("$", signature(x = "SpatialCellData"), function(x, name) {
  x@meta_data[[name]]
})

#' Get Dimensions of a SpatialCellData Object
#'
#' @param x A \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @return Integer vector: number of cells, number of markers.
#' @export
setMethod("dim", "SpatialCellData", function(x) {
  dim(x@counts)
})
