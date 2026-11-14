# ============================================================================
# interop.R -- Conversion to/from SpatialExperiment and Seurat
# ----------------------------------------------------------------------------
# Bridges to the wider single-cell ecosystem. The target packages are optional
# (Suggests); each converter checks for them and gives an actionable message
# when absent.
# ============================================================================

# The ecosystem assays have already chosen their feature set. Do not run the
# raw-input constructor's all-missing-feature filter on a round trip.
.import_spatial_assays <- function(counts, coords, meta, normalized = NULL) {
  if (is.null(colnames(counts)) && ncol(counts)) {
    colnames(counts) <- paste0("M", seq_len(ncol(counts)))
  }
  if (!"cell_id" %in% names(meta)) {
    meta$cell_id <- if (!is.null(rownames(counts))) rownames(counts) else as.character(seq_len(nrow(counts)))
  }
  if (!"sample_id" %in% names(meta)) meta$sample_id <- rep("sample1", nrow(counts))
  object <- methods::new("SpatialCellData", counts = counts, data = counts,
                          coords = coords, meta_data = meta, project = "SpatialProject")
  if (is.null(normalized)) return(object)
  normalized <- as.matrix(normalized)
  # Legacy Seurat assays expose an absent data layer as a 0 x 0 matrix.
  if (identical(dim(normalized), c(0L, 0L))) return(object)
  if (!identical(dim(normalized), dim(counts))) {
    stop("Normalized assay must contain the same cells and markers as counts; ",
         "select matching assays before import.", call. = FALSE)
  }
  for (axis in 1:2) {
    expected <- dimnames(counts)[[axis]]
    actual <- dimnames(normalized)[[axis]]
    if (is.null(expected) || is.null(actual) || identical(expected, actual)) next
    if (anyDuplicated(expected) || anyDuplicated(actual) || !setequal(expected, actual)) {
      stop("Normalized assay axes do not match counts.", call. = FALSE)
    }
    index <- match(expected, actual)
    normalized <- if (axis == 1L) normalized[index, , drop = FALSE] else normalized[, index, drop = FALSE]
  }
  dimnames(normalized) <- dimnames(counts)
  object@data <- normalized
  methods::validObject(object)
  object
}

# Use the version-appropriate assay API; a missing optional data layer is the
# only reason to retain raw counts as data. Other backend errors propagate.
.seurat_assay <- function(object, layer, optional = FALSE) {
  if (utils::packageVersion("SeuratObject") >= "5.0.0") {
    layers <- SeuratObject::Layers(object, search = NA)
    if (optional && !any(layers == layer | startsWith(layers, paste0(layer, ".")))) return(NULL)
    SeuratObject::GetAssayData(object, layer = layer)
  } else {
    SeuratObject::GetAssayData(object, slot = layer)
  }
}

#' Convert a SpatialCellData to a Seurat Object
#'
#' Builds a \pkg{Seurat} object with raw counts, normalised data, cell metadata,
#' and the spatial coordinates stored both in metadata (\code{x}, \code{y}) and
#' as a \code{"spatial"} dimensional reduction. Cell IDs repeated across
#' samples are made unique with [make.unique()] for the Seurat cell names; the
#' metadata keep the original \code{cell_id}. Export refuses marker identifiers
#' that Seurat would rewrite (such as underscores); use [as_SpatialExperiment()]
#' for unchanged identifiers, or rename markers explicitly before export.
#' The reduction uses named x/y only. Extra coordinate columns are retained in
#' `misc$phenoscapR_coordinates`, keyed by unique Seurat cell names, and restored
#' by [as_SpatialCellData()] after cell subsetting or reordering. Saved columns
#' never override current x/y. Conflicting x/y metadata are refused rather than
#' overwritten; rename such metadata explicitly before export.
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
  methods::validObject(object)
  # Cell IDs need only be unique within a sample; Seurat needs unique names.
  cells <- make.unique(as.character(object@meta_data$cell_id))
  counts <- t(object@counts)
  colnames(counts) <- cells
  rownames(counts) <- Markers(object)

  meta <- object@meta_data
  rownames(meta) <- cells
  xy <- .spatial_xy(object)
  for (axis in c("x", "y")) {
    if (axis %in% names(meta) &&
        !isTRUE(all.equal(meta[[axis]], xy[, axis], check.attributes = FALSE))) {
      stop("Metadata column '", axis, "' conflicts with spatial coordinates; ",
           "rename it explicitly before Seurat export.", call. = FALSE)
    }
    meta[[axis]] <- xy[, axis]
  }

  se <- suppressWarnings(
    Seurat::CreateSeuratObject(counts = counts, meta.data = meta))
  if (!identical(rownames(.seurat_assay(se, "counts")), Markers(object))) {
    stop("Seurat rewrites these marker identifiers (for example underscores to hyphens). ",
         "Use as_SpatialExperiment() to retain them, or rename markers explicitly before export.",
         call. = FALSE)
  }
  data_mat <- t(object@data)
  colnames(data_mat) <- cells
  rownames(data_mat) <- Markers(object)
  se <- suppressWarnings(if (utils::packageVersion("SeuratObject") >= "5.0.0") {
    Seurat::SetAssayData(se, layer = "data", new.data = data_mat)
  } else {
    Seurat::SetAssayData(se, slot = "data", new.data = data_mat)
  })

  emb <- xy
  rownames(emb) <- cells
  colnames(emb) <- c("spatial_1", "spatial_2")
  se[["spatial"]] <- Seurat::CreateDimReducObject(
    embeddings = emb, key = "spatial_", assay = Seurat::DefaultAssay(se))
  extra <- object@coords[, setdiff(names(object@coords), c("x", "y")), drop = FALSE]
  if (ncol(extra)) {
    rownames(extra) <- cells
    se@misc$phenoscapR_coordinates <- list(version = 1L, extra = extra)
  }
  se
}

#' Convert a SpatialCellData to a SpatialExperiment Object
#'
#' Builds a \pkg{SpatialExperiment} with \code{counts} and \code{logcounts}
#' assays (markers x cells), the metadata as \code{colData}, and the
#' coordinates as \code{spatialCoords}. All numeric coordinate dimensions and
#' their names are retained. Nonnumeric coordinate annotations are refused;
#' move them to metadata explicitly before export.
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @return A \code{SpatialExperiment} object.
#' @examples
#' \donttest{
#' if (requireNamespace("SpatialExperiment", quietly = TRUE)) {
#'   counts <- matrix(c(5, 0, 3, 1, 2, 7, 0, 4, 6, 1, 2, 3), nrow = 4,
#'                    dimnames = list(NULL, c("CD3", "CD8", "CD20")))
#'   obj <- CreateSpatialObject(counts, data.frame(x = c(1, 5, 9, 4), y = c(2, 8, 3, 6)))
#'   spe <- as_SpatialExperiment(obj)
#' }
#' }
#' @export
as_SpatialExperiment <- function(object) {
  if (!requireNamespace("SpatialExperiment", quietly = TRUE)) {
    stop("as_SpatialExperiment() requires the 'SpatialExperiment' package ",
         "(Bioconductor). Install it with ",
         "BiocManager::install(\"SpatialExperiment\").", call. = FALSE)
  }
  methods::validObject(object)
  .spatial_xy(object)
  if (!all(vapply(object@coords, function(z) {
    is.numeric(z) && !is.complex(z) && is.null(dim(z)) && !is.object(z)
  }, logical(1)))) {
    stop("SpatialExperiment coordinates must be plain numeric columns; ",
         "move nonnumeric annotations to metadata explicitly before export.", call. = FALSE)
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
#' columns or a \code{"spatial"} reduction (Seurat). The normalized `logcounts`
#' assay (SpatialExperiment) or `data` layer (Seurat) is retained when present;
#' raw counts are used as data only when it is absent. Normalized assays must
#' contain the same cells and features as counts; named axes are aligned, and
#' incompatible partial assays are refused. All-missing features are retained.
#' Existing cell identifiers are kept; absent `cell_id` metadata use the source
#' cell names when available. No normalization method is inferred or applied.
#' SpatialExperiment coordinates retain named x/y regardless of column order;
#' when neither name exists, the first two dimensions become x/y. Partial or
#' duplicate coordinate names are refused. Seurat exports from this package
#' restore additional coordinate columns from the namespaced misc mapping using
#' current cell names. Missing or ambiguous mappings are refused; current x/y
#' metadata (or the spatial reduction fallback) remain authoritative.
#'
#' @param x A \code{Seurat} or \code{SpatialExperiment} object.
#' @param ... Unused.
#' @return A \code{\link{SpatialCellData-class}} object.
#' @examples
#' \donttest{
#' if (requireNamespace("Seurat", quietly = TRUE)) {
#'   counts <- matrix(c(5, 0, 3, 1, 2, 7, 0, 4, 6, 1, 2, 3), nrow = 4,
#'                    dimnames = list(NULL, c("CD3", "CD8", "CD20")))
#'   obj <- CreateSpatialObject(counts, data.frame(x = c(1, 5, 9, 4), y = c(2, 8, 3, 6)))
#'   seurat_object <- as_Seurat(obj)
#'   as_SpatialCellData(seurat_object)
#' }
#' }
#' @export
as_SpatialCellData <- function(x, ...) {
  if (methods::is(x, "SpatialExperiment")) {
    counts <- t(as.matrix(SummarizedExperiment::assay(x, "counts")))
    coords <- as.data.frame(SpatialExperiment::spatialCoords(x))
    coordinate_names <- names(coords)
    if (anyDuplicated(coordinate_names) || ncol(coords) < 2L ||
        xor("x" %in% coordinate_names, "y" %in% coordinate_names)) {
      stop("SpatialExperiment coordinates require at least two uniquely named ",
           "columns, with both x/y names or neither.", call. = FALSE)
    }
    if (!all(c("x", "y") %in% coordinate_names)) names(coords)[1:2] <- c("x", "y")
    meta <- as.data.frame(SummarizedExperiment::colData(x))
    normalized <- if ("logcounts" %in% SummarizedExperiment::assayNames(x)) {
      t(as.matrix(SummarizedExperiment::assay(x, "logcounts")))
    } else NULL
    return(.import_spatial_assays(counts, coords, meta, normalized))
  }
  if (methods::is(x, "Seurat")) {
    counts <- t(as.matrix(.seurat_assay(x, "counts")))
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
    saved <- x@misc$phenoscapR_coordinates
    if (!is.null(saved)) {
      extra <- if (is.list(saved)) saved$extra else NULL
      keys <- if (is.data.frame(extra)) rownames(extra) else NULL
      cells <- rownames(counts)
      if (!is.list(saved) || !identical(saved$version, 1L) ||
          !is.data.frame(extra) || is.null(keys) || anyNA(keys) ||
          anyDuplicated(keys) || any(!nzchar(keys)) ||
          anyDuplicated(names(extra)) || any(c("x", "y") %in% names(extra)) ||
          is.null(cells) || anyDuplicated(cells) || !all(cells %in% keys)) {
        stop("Invalid phenoscapR coordinate mapping in Seurat misc; ",
             "current cells must match unique saved cell names.", call. = FALSE)
      }
      extra <- extra[match(cells, keys), , drop = FALSE]
      rownames(extra) <- rownames(coords)
      coords <- cbind(coords, extra)
    }
    normalized <- .seurat_assay(x, "data", optional = TRUE)
    if (!is.null(normalized)) normalized <- t(as.matrix(normalized))
    return(.import_spatial_assays(counts, coords, meta, normalized))
  }
  stop("as_SpatialCellData() supports Seurat and SpatialExperiment objects.",
       call. = FALSE)
}
