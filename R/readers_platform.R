# ============================================================================
# readers_platform.R -- Readers for imaging-platform cell-level exports
# ----------------------------------------------------------------------------
# Most spatial platforms export a cell-by-feature expression table plus a
# cell-metadata table carrying coordinates. ReadMatrixCoords() handles that
# general layout; the platform wrappers below just preset the column names used
# by each vendor's standard cell-level output.
# ============================================================================

#' Load a table from a path, matrix, or data.frame
#' @noRd
.load_table <- function(x) {
  if (is.character(x) && length(x) == 1L) {
    return(as.data.frame(data.table::fread(x), stringsAsFactors = FALSE))
  }
  if (is.matrix(x)) return(x)
  as.data.frame(x, stringsAsFactors = FALSE)
}

#' Read an Expression Matrix and a Coordinate/Metadata Table
#'
#' General-purpose reader for the common spatial layout of one cell-by-feature
#' expression table plus one cell-metadata table holding coordinates. Each
#' argument may be a file path (read with \code{data.table::fread}), a matrix,
#' or a data frame.
#'
#' @param expression Cells-by-markers expression (matrix, data frame, or CSV
#'   path). Non-numeric and \code{id_cols} columns are dropped.
#' @param metadata Cell metadata containing the coordinate columns (data frame
#'   or CSV path).
#' @param x_col,y_col Character. Coordinate column names in \code{metadata}.
#' @param cell_id_col Character or \code{NULL}. Shared cell-id column; if present
#'   in both tables, rows are matched on it, otherwise row order is assumed.
#' @param id_cols Character vector. Non-marker id columns to drop from
#'   \code{expression} (e.g. \code{"fov"}, \code{"cell_ID"}).
#' @param sample_id Character. Sample identifier. Default \code{"sample1"}.
#' @param transpose Logical. Set \code{TRUE} if \code{expression} is
#'   markers-by-cells. Default \code{FALSE}.
#' @param project Character. Project name.
#'
#' @return A \code{\link{SpatialCellData-class}} object.
#'
#' @examples
#' expr <- matrix(rpois(40, 5), nrow = 10,
#'                dimnames = list(NULL, c("CD3", "CD8", "CD20", "PanCK")))
#' meta <- data.frame(x = runif(10, 0, 100), y = runif(10, 0, 100))
#' obj <- ReadMatrixCoords(expr, meta)
#' obj
#'
#' @export
ReadMatrixCoords <- function(expression, metadata, x_col = "x", y_col = "y",
                             cell_id_col = NULL, id_cols = character(0),
                             sample_id = "sample1", transpose = FALSE,
                             project = "SpatialProject") {
  expr <- .load_table(expression)
  meta <- .load_table(metadata)

  if (!is.matrix(expr)) {
    drop <- intersect(c(id_cols, cell_id_col), names(expr))
    expr_ids <- if (!is.null(cell_id_col) && cell_id_col %in% names(expr)) {
      as.character(expr[[cell_id_col]])
    } else {
      NULL
    }
    keep <- setdiff(names(expr), drop)
    is_num <- vapply(expr[keep], is.numeric, logical(1L))
    counts <- as.matrix(expr[, keep[is_num], drop = FALSE])
    rownames(counts) <- expr_ids
  } else {
    counts <- expr
  }
  if (transpose) counts <- t(counts)

  if (!x_col %in% names(meta) || !y_col %in% names(meta)) {
    stop("Coordinate columns '", x_col, "'/'", y_col,
         "' not found in metadata.", call. = FALSE)
  }

  # Match expression rows to metadata rows when a shared id is available.
  if (!is.null(cell_id_col) && cell_id_col %in% names(meta) &&
      !is.null(rownames(counts))) {
    ord <- match(as.character(meta[[cell_id_col]]), rownames(counts))
    if (anyNA(ord)) {
      stop("Some metadata cell ids are absent from the expression table.",
           call. = FALSE)
    }
    counts <- counts[ord, , drop = FALSE]
  }
  if (nrow(counts) != nrow(meta)) {
    stop("Expression has ", nrow(counts), " cells but metadata has ",
         nrow(meta), "; provide cell_id_col to match them.", call. = FALSE)
  }

  coords <- data.frame(x = as.numeric(meta[[x_col]]),
                       y = as.numeric(meta[[y_col]]))
  extra <- setdiff(names(meta), c(x_col, y_col))
  meta_data <- meta[, extra, drop = FALSE]
  if (is.null(cell_id_col) || !cell_id_col %in% names(meta_data)) {
    meta_data$cell_id <- as.character(seq_len(nrow(meta)))
  } else {
    meta_data$cell_id <- as.character(meta_data[[cell_id_col]])
  }
  if (!"sample_id" %in% names(meta_data)) meta_data$sample_id <- sample_id

  CreateSpatialObject(counts, coords, meta_data = meta_data, project = project)
}

#' Read 10x Xenium Cell Output
#'
#' Convenience wrapper for Xenium: a \code{cells} table with
#' \code{x_centroid}/\code{y_centroid} coordinates plus a cell-by-gene
#' \code{expression} matrix (load the feature matrix yourself, e.g. via
#' \pkg{Matrix}, and pass it here).
#'
#' @param expression Cells-by-genes matrix / data frame / CSV path.
#' @param cells The Xenium \code{cells.csv(.gz)} metadata (path or data frame).
#' @param sample_id,project Passed to [ReadMatrixCoords()].
#' @return A \code{\link{SpatialCellData-class}} object.
#' @export
ReadXenium <- function(expression, cells, sample_id = "sample1",
                       project = "Xenium") {
  ReadMatrixCoords(expression, cells, x_col = "x_centroid",
                   y_col = "y_centroid", cell_id_col = "cell_id",
                   sample_id = sample_id, project = project)
}

#' Read NanoString CosMx Cell Output
#'
#' Convenience wrapper for CosMx: the \code{*_exprMat_file.csv} (cell-by-gene,
#' with \code{fov}/\code{cell_ID} columns) and \code{*_metadata_file.csv} (with
#' \code{CenterX_global_px}/\code{CenterY_global_px}).
#'
#' @param expr_file Path/data frame of the expression matrix.
#' @param meta_file Path/data frame of the cell metadata.
#' @param sample_id,project Passed to [ReadMatrixCoords()].
#' @return A \code{\link{SpatialCellData-class}} object.
#' @export
ReadCosMx <- function(expr_file, meta_file, sample_id = "sample1",
                      project = "CosMx") {
  ReadMatrixCoords(expr_file, meta_file,
                   x_col = "CenterX_global_px", y_col = "CenterY_global_px",
                   cell_id_col = "cell_ID", id_cols = c("fov", "cell_ID"),
                   sample_id = sample_id, project = project)
}

#' Read Vizgen MERSCOPE Cell Output
#'
#' Convenience wrapper for MERSCOPE: \code{cell_by_gene.csv} (cell-by-gene, first
#' column the cell id) and \code{cell_metadata.csv} (with
#' \code{center_x}/\code{center_y}).
#'
#' @param matrix_file Path/data frame of the cell-by-gene matrix.
#' @param metadata_file Path/data frame of the cell metadata.
#' @param sample_id,project Passed to [ReadMatrixCoords()].
#' @return A \code{\link{SpatialCellData-class}} object.
#' @export
ReadMERSCOPE <- function(matrix_file, metadata_file, sample_id = "sample1",
                         project = "MERSCOPE") {
  ReadMatrixCoords(matrix_file, metadata_file,
                   x_col = "center_x", y_col = "center_y",
                   cell_id_col = "cell", id_cols = "cell",
                   sample_id = sample_id, project = project)
}
