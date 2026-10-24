#' Project Spatial Tables Without Changing Column Metadata
#'
#' Selects explicit rows and columns from a plain data frame or data.table.
#' Row order and repetitions follow `rows`; column order follows `columns`.
#' Selection uses a copied data.table inside the package namespace, preserving
#' column storage types, classes and attributes according to data.table subset
#' semantics. The result is a plain data frame with reset row names.
#' No eligibility, missing-value filtering, sorting or numerical transformation
#' is inferred. The supplied input is not modified.
#'
#' @param data A plain data.frame or data.table with distinct, nonempty column
#'   names. Other data-frame subclasses are not accepted.
#' @param rows A dimensionless, unclassed integer vector of positive row indices
#'   no greater than the number of input rows. Missing indices are not allowed.
#'   `integer()` selects zero rows; repeated and shuffled indices are retained.
#' @param columns A dimensionless, unclassed character vector of distinct,
#'   nonempty existing column names, in the requested order.
#' @return A plain data.frame with the requested rows and columns and reset row
#'   names. A one-column selection remains a data frame; an empty row selection
#'   retains typed columns and their metadata. Invalid inputs are rejected
#'   rather than coerced, recycled or partially matched.
#' @examples
#' d <- data.frame(id = letters[1:3], weight = c(0.5, 1.5, 2.5))
#' ProjectSpatialTable(d, c(3L, 1L, 3L), c("weight", "id"))
#' ProjectSpatialTable(d, integer(), "weight")
#' @export
ProjectSpatialTable <- function(data, rows, columns) {
  plain <- identical(class(data), "data.frame") ||
    identical(class(data), c("data.table", "data.frame"))
  if (!plain) {
    stop("data must be a plain data.frame or data.table", call. = FALSE)
  }
  column_names <- names(data)
  if (anyNA(column_names) || any(!nzchar(column_names)) ||
      anyDuplicated(column_names)) {
    stop("data requires distinct nonempty column names", call. = FALSE)
  }
  if (!is.integer(rows) || is.object(rows) || !is.null(dim(rows)) ||
      anyNA(rows) || any(rows < 1L) || any(rows > nrow(data))) {
    stop("rows must be unclassed integer indices within the input", call. = FALSE)
  }
  if (!is.character(columns) || is.object(columns) ||
      !is.null(dim(columns)) || !length(columns) || anyNA(columns) ||
      any(!nzchar(columns)) || anyDuplicated(columns) ||
      any(!columns %in% column_names)) {
    stop("columns must be distinct existing column names", call. = FALSE)
  }
  table <- data.table::as.data.table(data.table::copy(data))
  answer <- table[rows, columns, with = FALSE]
  answer <- as.data.frame(answer)
  rownames(answer) <- NULL
  answer
}
