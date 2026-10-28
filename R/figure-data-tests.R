# Plot-data builders that describe families of tests for figures: the bound
# of an exact permutation P value, family summaries and text-table cells.
# Tests themselves come from upstream analysis tables.

#' Lower Bound of an Exact Two-Sided Permutation P Value
#'
#' For an exact permutation test of two groups of sizes `n_a` and `n_b`
#' (all allocations of the pooled values), the observed allocation always
#' reaches its own statistic; with equal group sizes its mirror allocation
#' reaches the same absolute difference. The smallest attainable two-sided
#' P is therefore at least `2 / choose(n_a + n_b, n_a)` for equal and
#' `1 / choose(n_a + n_b, n_a)` for unequal sizes.
#'
#' @param n_a,n_b Group sizes.
#' @return Numeric lower bound.
#' @examples
#' ExactPermutationBound(6, 6)
#' ExactPermutationBound(4, 2)
#' @export
ExactPermutationBound <- function(n_a, n_b) {
  if (!is.numeric(n_a) || !is.numeric(n_b) || any(n_a < 1 | n_b < 1)) {
    stop("Group sizes must be positive.", call. = FALSE)
  }
  ifelse(n_a == n_b, 2, 1) / choose(n_a + n_b, n_a)
}

#' Summary of a Family of Two-Group Tests
#'
#' One row describing a set of exact two-group tests: the number of tests
#' with a finite P value, of nominal (`p < alpha`) and of adjusted
#' (`q < alpha`) results, the group sizes and [ExactPermutationBound()].
#'
#' @param data Test table, one row per endpoint.
#' @param p,q P value and adjusted P value columns.
#' @param n_a,n_b Group-size columns (the most frequent sizes are used).
#' @param alpha Significance level.
#' @param label Optional column whose distinct values are counted as
#'   `endpoints`.
#' @return A one-row data frame with `tests`, `nominal`, `adjusted`, `n_a`,
#'   `n_b`, `p_bound` and `endpoints`.
#' @examples
#' t <- data.frame(p = c(0.01, 0.2, NA), q = c(0.1, 0.4, NA), n_a = 4, n_b = 2)
#' PlotDataContrastSummary(t)
#' @export
PlotDataContrastSummary <- function(data, p = "p", q = "q", n_a = "n_a", n_b = "n_b",
                                    alpha = 0.05, label = NULL) {
  .fig_require_columns(data, c(p, q, n_a, n_b, label))
  pv <- as.numeric(data[[p]])
  ok <- is.finite(pv)
  modal <- function(v) {
    v <- v[ok & !is.na(v)]
    if (!length(v)) return(NA_real_)
    t <- table(v)
    as.numeric(names(t)[which.max(t)])
  }
  na <- modal(data[[n_a]])
  nb <- modal(data[[n_b]])
  data.frame(tests = sum(ok), nominal = sum(pv[ok] < alpha),
             adjusted = sum(as.numeric(data[[q]])[ok] < alpha, na.rm = TRUE),
             n_a = na, n_b = nb,
             p_bound = if (is.finite(na) && is.finite(nb)) ExactPermutationBound(na, nb) else NA_real_,
             endpoints = if (is.null(label)) sum(ok) else length(unique(data[[label]])))
}

#' Text-Table Cells from a Per-Unit Table
#'
#' Transposes a table with one row per unit (patient, analysis) into the
#' cells of a small text table for [PlotTextBlock()]: a header row with the
#' unit labels and one row per value column, each with a row label in the
#' first column. Values are written as numbers (whole numbers without
#' decimals, missing as `"NE"`), as text for text columns, or from one
#' template per table row (see [FormatTemplate()]). Cells whose value lies
#' below `highlight_below` are flagged.
#'
#' @param data A data frame, one row per unit, in display order.
#' @param id Column with the unit labels shown in the header.
#' @param values Value columns, one table row each (optional with
#'   `templates`).
#' @param row_labels Labels of the value rows.
#' @param header Label of the header row.
#' @param key Optional column copied to the header cells as `key` (for
#'   example a group used to colour header text).
#' @param highlight_below Values below this are flagged (`highlight = TRUE`).
#' @param zero_text Optional text written instead of zero values.
#' @param templates Optional templates, one per table row, filled from each
#'   unit's row (for example `"p = {p|p}"`).
#' @return A data frame of cells with `row`, `column`, `label`, `header`,
#'   `highlight` and `key`.
#' @examples
#' d <- data.frame(id = c("1", "2"), a = c(3, 0), b = c(12, 40), g = c("x", "y"))
#' PlotDataTableCells(d, "id", c("a", "b"), c("First", "Second"), key = "g",
#'                    highlight_below = 10, zero_text = "0 (NE)")
#' PlotDataTableCells(data.frame(id = c("A", "B"), p = c(0.018, 0.058)), "id",
#'                    row_labels = "Permutation test", templates = "p = {p|p}")
#' @export
PlotDataTableCells <- function(data, id, values = NULL, row_labels = values, header = "", key = NULL,
                               highlight_below = NULL, zero_text = NULL, templates = NULL) {
  .fig_require_columns(data, c(id, values, key))
  rows <- if (!is.null(templates)) length(templates) else length(values)
  if (length(row_labels) != rows) stop("row_labels must match values or templates.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  n <- nrow(data)
  cells <- list(data.frame(row = 1L, column = seq_len(n + 1L), label = c(header, as.character(data[[id]])),
                           header = TRUE, highlight = FALSE,
                           key = c(NA, if (is.null(key)) rep(NA, n) else as.character(data[[key]]))))
  for (j in seq_len(rows)) {
    hl <- rep(FALSE, n)
    if (!is.null(templates)) {
      lab <- if (n) FormatTemplate(rep_len(templates[[j]], n), data) else character()
    } else if (is.character(data[[values[[j]]]]) || is.factor(data[[values[[j]]]])) {
      lab <- ifelse(is.na(data[[values[[j]]]]), "NE", as.character(data[[values[[j]]]]))
    } else {
      v <- as.numeric(data[[values[[j]]]])
      lab <- ifelse(is.na(v), "NE", formatC(v, format = "fg", big.mark = ""))
      lab <- ifelse(!is.na(v) & v == round(v), as.character(round(v)), lab)
      if (!is.null(zero_text)) lab[!is.na(v) & v == 0] <- zero_text
      if (!is.null(highlight_below)) hl <- !is.na(v) & v < highlight_below
    }
    cells[[j + 1L]] <- data.frame(row = j + 1L, column = seq_len(n + 1L), label = c(row_labels[[j]], lab),
                                  header = FALSE, highlight = c(FALSE, hl), key = NA)
  }
  out <- do.call(rbind, cells)
  rownames(out) <- NULL
  out
}
