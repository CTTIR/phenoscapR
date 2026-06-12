# ============================================================================
# interop.R -- Conversion to/from SpatialExperiment and Seurat
# ----------------------------------------------------------------------------
# Bridges to the wider single-cell ecosystem. The target packages are optional
# (Suggests); each converter checks for them and gives an actionable message
# when absent.
# ============================================================================

#' Convert a SpatialCellData to a Seurat Object
#'
#' Builds a \pkg{Seurat} object with raw counts, normalised data, cell metadata,
#' and the spatial coordinates stored both in metadata (\code{x}, \code{y}) and
#' as a \code{"spatial"} dimensional reduction.
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @return A \code{Seurat} object.
#' @examples
#' \donttest{
#' if (requireNamespace("Seurat", quietly = TRUE)) {
#'   data(phenoscapR_example)
#'   se <- as_Seurat(phenoscapR_example)
#' }
#' }
#' @export
as_Seurat <- function(object) {
  if (!requireNamespace("Seurat", quietly = TRUE)) {
    stop("as_Seurat() requires the 'Seurat' package. Install it with ",
         "install.packages(\"Seurat\").", call. = FALSE)
  }
  cells <- as.character(object@meta_data$cell_id)
  counts <- t(object@counts)
  colnames(counts) <- cells
  rownames(counts) <- Markers(object)

  meta <- object@meta_data
  rownames(meta) <- cells
  meta$x <- object@coords$x
  meta$y <- object@coords$y

  se <- suppressWarnings(
    Seurat::CreateSeuratObject(counts = counts, meta.data = meta))
  data_mat <- t(object@data)
  colnames(data_mat) <- cells
  rownames(data_mat) <- Markers(object)
  se <- suppressWarnings(
    Seurat::SetAssayData(se, layer = "data", new.data = data_mat))

  emb <- as.matrix(object@coords)
  rownames(emb) <- cells
  colnames(emb) <- c("spatial_1", "spatial_2")
  se[["spatial"]] <- Seurat::CreateDimReducObject(
    embeddings = emb, key = "spatial_", assay = Seurat::DefaultAssay(se))
  se
}

#' Convert a SpatialCellData to a SpatialExperiment Object
#'
#' Builds a \pkg{SpatialExperiment} with \code{counts} and \code{logcounts}
#' assays (markers x cells), the metadata as \code{colData}, and the
#' coordinates as \code{spatialCoords}.
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @return A \code{SpatialExperiment} object.
#' @examples
#' \donttest{
#' if (requireNamespace("SpatialExperiment", quietly = TRUE)) {
#'   data(phenoscapR_example)
#'   spe <- as_SpatialExperiment(phenoscapR_example)
#' }
#' }
#' @export
as_SpatialExperiment <- function(object) {
  if (!requireNamespace("SpatialExperiment", quietly = TRUE)) {
    stop("as_SpatialExperiment() requires the 'SpatialExperiment' package ",
         "(Bioconductor). Install it with ",
         "BiocManager::install(\"SpatialExperiment\").", call. = FALSE)
  }
  SpatialExperiment::SpatialExperiment(
    assays = list(counts = t(object@counts), logcounts = t(object@data)),
    colData = S4Vectors::DataFrame(object@meta_data),
    spatialCoords = as.matrix(object@coords)
  )
}

#' Convert a Seurat or SpatialExperiment Object to SpatialCellData
#'
#' Imports an object from the wider ecosystem. Coordinates are taken from
#' \code{spatialCoords} (SpatialExperiment) or from \code{x}/\code{y} metadata
#' columns or a \code{"spatial"} reduction (Seurat).
#'
#' @param x A \code{Seurat} or \code{SpatialExperiment} object.
#' @param ... Unused.
#' @return A \code{\link{SpatialCellData-class}} object.
#' @examples
#' \dontrun{
#' obj <- as_SpatialCellData(seurat_object)
#' }
#' @export
as_SpatialCellData <- function(x, ...) {
  if (methods::is(x, "SpatialExperiment")) {
    counts <- t(as.matrix(SummarizedExperiment::assay(x, "counts")))
    coords <- as.data.frame(SpatialExperiment::spatialCoords(x))
    names(coords)[1:2] <- c("x", "y")
    meta <- as.data.frame(SummarizedExperiment::colData(x))
    return(CreateSpatialObject(counts, coords, meta_data = meta))
  }
  if (methods::is(x, "Seurat")) {
    counts <- t(as.matrix(SeuratObject::GetAssayData(x, layer = "counts")))
    meta <- x[[]]
    if (all(c("x", "y") %in% names(meta))) {
      coords <- data.frame(x = meta$x, y = meta$y)
    } else if ("spatial" %in% SeuratObject::Reductions(x)) {
      emb <- SeuratObject::Embeddings(x, "spatial")
      coords <- data.frame(x = emb[, 1L], y = emb[, 2L])
    } else {
      stop("No coordinates found: expected x/y metadata or a 'spatial' ",
           "reduction.", call. = FALSE)
    }
    return(CreateSpatialObject(counts, coords, meta_data = meta))
  }
  stop("as_SpatialCellData() supports Seurat and SpatialExperiment objects.",
       call. = FALSE)
}
