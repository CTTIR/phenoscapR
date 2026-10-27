# Generic plot-data builders: reshape and select summary tables into the
# tidy form expected by the Plot* builders. No statistics are computed here.

#' Reshape Wide Summary Columns into Long Plot Data
#'
#' Stacks selected value columns of a summary table (one row per patient,
#' say) into one row per identifier and column, the form used by
#' [PlotPairedPatients()] and similar builders.
#'
#' @param data A data frame.
#' @param id Identifier columns kept on every row.
#' @param values Value columns to stack, in condition order.
#' @param conditions Condition names for `values`; default the column names.
#' @param names_to,values_to Names of the new condition and value columns.
#' @return A data frame with `id` columns, `names_to` (character, in the
#'   order of `values`) and `values_to` (numeric).
#' @examples
#' d <- data.frame(patient = c("p1", "p2"), a = 1:2, b = 3:4)
#' PlotDataLonger(d, "patient", c("a", "b"), conditions = c("A", "B"))
#' @export
PlotDataLonger <- function(data, id, values, conditions = values, names_to = "condition",
                           values_to = "value") {
  .fig_require_columns(data, c(id, values))
  if (length(conditions) != length(values)) stop("conditions must match values.", call. = FALSE)
  if (any(c(names_to, values_to) %in% id)) stop("New column names clash with id.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  parts <- lapply(seq_along(values), function(j) {
    out <- data[id]
    out[[names_to]] <- conditions[[j]]
    out[[values_to]] <- as.numeric(data[[values[[j]]]])
    out
  })
  out <- do.call(rbind, parts)
  rownames(out) <- NULL
  out
}

#' Select Rows and Columns of Plot Data
#'
#' Keeps rows whose columns take given values, optionally reorders rows by
#' a given order of one column, and keeps or renames columns.
#'
#' @param data A data frame.
#' @param filter Named list: column name to the values to keep.
#' @param columns Columns to keep (all if `NULL`).
#' @param rename Named character vector or list, new name to old name.
#' @param order_by Optional column whose values follow `order`.
#' @param order Value order for `order_by`; rows with other values are
#'   dropped.
#' @return A data frame.
#' @examples
#' d <- data.frame(type = c("x", "y", "x"), v = 1:3)
#' PlotDataSelect(d, filter = list(type = "x"), rename = c(value = "v"))
#' @export
PlotDataSelect <- function(data, filter = list(), columns = NULL, rename = NULL,
                           order_by = NULL, order = NULL) {
  if (!is.data.frame(data)) stop("data must be a data frame.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  .fig_require_columns(data, c(names(filter), columns, unlist(rename), order_by))
  keep <- rep(TRUE, nrow(data))
  for (col in names(filter)) keep <- keep & as.character(data[[col]]) %in% as.character(unlist(filter[[col]]))
  data <- data[keep, , drop = FALSE]
  if (!is.null(order_by)) {
    if (is.null(order)) stop("order is required with order_by.", call. = FALSE)
    pos <- match(as.character(data[[order_by]]), as.character(unlist(order)))
    data <- data[!is.na(pos), , drop = FALSE][order(pos[!is.na(pos)]), , drop = FALSE]
  }
  if (!is.null(columns)) data <- data[columns]
  if (!is.null(rename)) {
    rename <- unlist(rename)
    names(data)[match(rename, names(data))] <- names(rename)
  }
  rownames(data) <- NULL
  data
}
