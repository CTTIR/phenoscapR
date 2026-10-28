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

# Character key of one or more id columns (one column keeps its plain values).
.cell_key <- function(table, columns) {
  if (length(columns) == 1L) return(as.character(table[[columns]]))
  do.call(paste, c(lapply(table[columns], as.character), sep = "\r"))
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
#'   Further columns (for example \code{"fov"}) can follow: those present in
#'   both tables are matched as well, so ids need only be unique within them.
#'   The first column becomes \code{cell_id}. Matched ids must be unique.
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
  id_col <- cell_id_col[1L]
  keys <- id_col
  expr_keys <- NULL

  if (!is.matrix(expr)) {
    drop <- intersect(c(id_cols, cell_id_col), names(expr))
    expr_ids <- if (!is.null(id_col) && id_col %in% names(expr)) {
      as.character(expr[[id_col]])
    } else {
      NULL
    }
    if (!is.null(expr_ids) && !transpose) {
      keys <- c(id_col, intersect(cell_id_col[-1L], intersect(names(expr), names(meta))))
      expr_keys <- .cell_key(expr, keys)
    }
    keep <- setdiff(names(expr), drop)
    is_num <- vapply(expr[keep], is.numeric, logical(1L))
    counts <- as.matrix(expr[, keep[is_num], drop = FALSE])
    rownames(counts) <- expr_ids
  } else {
    counts <- expr
  }
  if (transpose) counts <- t(counts)
  if (is.null(expr_keys)) expr_keys <- rownames(counts)

  if (!x_col %in% names(meta) || !y_col %in% names(meta)) {
    stop("Coordinate columns '", x_col, "'/'", y_col,
         "' not found in metadata.", call. = FALSE)
  }

  # Match expression rows to metadata rows when a shared id is available.
  if (!is.null(id_col) && id_col %in% names(meta) && !is.null(expr_keys)) {
    meta_keys <- .cell_key(meta, keys)
    if (anyDuplicated(meta_keys) || anyDuplicated(expr_keys)) {
      stop("Cell ids are not unique; add the columns that tell cells apart ",
           "(for example \"fov\") to cell_id_col.", call. = FALSE)
    }
    ord <- match(meta_keys, expr_keys)
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
  if (is.null(id_col) || !id_col %in% names(meta_data)) {
    meta_data$cell_id <- as.character(seq_len(nrow(meta)))
  } else {
    meta_data$cell_id <- as.character(meta_data[[id_col]])
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
#' @examples
#' cells <- tempfile(fileext = ".csv")
#' write.csv(data.frame(cell_id = c("aaa-1", "aab-1", "aac-1"),
#'                      x_centroid = c(10.5, 42, 77.25), y_centroid = c(5, 18.5, 33)),
#'           cells, row.names = FALSE)
#' counts <- data.frame(cell_id = c("aac-1", "aaa-1", "aab-1"),
#'                      CD3E = c(0, 4, 1), MS4A1 = c(7, 0, 2))
#' obj <- ReadXenium(expression = counts, cells = cells)
#' obj
#' unlink(cells)
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
#' \code{CenterX_global_px}/\code{CenterY_global_px}). CosMx numbers cells
#' within each FOV, so cells are matched on \code{fov} and \code{cell_ID}; the
#' \code{cell_ID} becomes \code{cell_id} and \code{fov} is kept.
#'
#' @param expr_file Path/data frame of the expression matrix.
#' @param meta_file Path/data frame of the cell metadata.
#' @param sample_id,project Passed to [ReadMatrixCoords()].
#' @return A \code{\link{SpatialCellData-class}} object.
#' @examples
#' expr_file <- tempfile(fileext = ".csv")
#' meta_file <- tempfile(fileext = ".csv")
#' write.csv(data.frame(fov = c(1, 1, 2, 2), cell_ID = c(1, 2, 1, 2),
#'                      CD3E = c(3, 0, 1, 5), KRT8 = c(0, 9, 2, 0)),
#'           expr_file, row.names = FALSE)
#' write.csv(data.frame(fov = c(1, 1, 2, 2), cell_ID = c(1, 2, 1, 2),
#'                      CenterX_global_px = c(100, 140, 2100, 2160),
#'                      CenterY_global_px = c(50, 80, 60, 95)),
#'           meta_file, row.names = FALSE)
#' obj <- ReadCosMx(expr_file, meta_file)
#' obj
#' unlink(c(expr_file, meta_file))
#' @export
ReadCosMx <- function(expr_file, meta_file, sample_id = "sample1",
                      project = "CosMx") {
  ReadMatrixCoords(expr_file, meta_file,
                   x_col = "CenterX_global_px", y_col = "CenterY_global_px",
                   cell_id_col = c("cell_ID", "fov"), id_cols = c("fov", "cell_ID"),
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
#' @examples
#' matrix_file <- tempfile(fileext = ".csv")
#' metadata_file <- tempfile(fileext = ".csv")
#' write.csv(data.frame(cell = c(101, 102, 103), CD3E = c(2, 0, 6), PTPRC = c(5, 1, 8)),
#'           matrix_file, row.names = FALSE)
#' write.csv(data.frame(cell = c(103, 101, 102), center_x = c(15, 210, 88),
#'                      center_y = c(40, 12, 160)),
#'           metadata_file, row.names = FALSE)
#' obj <- ReadMERSCOPE(matrix_file, metadata_file)
#' obj
#' unlink(c(matrix_file, metadata_file))
#' @export
ReadMERSCOPE <- function(matrix_file, metadata_file, sample_id = "sample1",
                         project = "MERSCOPE") {
  ReadMatrixCoords(matrix_file, metadata_file,
                   x_col = "center_x", y_col = "center_y",
                   cell_id_col = "cell", id_cols = "cell",
                   sample_id = sample_id, project = project)
}
