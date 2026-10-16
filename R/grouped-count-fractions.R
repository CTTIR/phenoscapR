#' Summarize Grouped Subset Counts as Fractions
#'
#' Computes sum(numerator) / sum(denominator) from supplied subset counts,
#' without averaging observation fractions or manufacturing absent groups.
#' Eligibility and the independent sampling unit must be chosen upstream.
#' IDs must be unique within the complete group key.
#'
#' Counts must be plain integer/double vectors (names are permitted), with no
#' classes or dimensions. Known counts must be finite nonnegative whole numbers
#' at most 2^53 - 1. Numerators cannot exceed their corresponding denominators
#' where both are known. NaN is rejected; NA is explicitly unavailable.
#' Both known-count totals are checked incrementally against 2^53 - 1 before
#' each addition, even when missingness will suppress the reported totals.
#'
#' Missingness is always propagated: any missing count suppresses both totals
#' and the fraction. n_available counts rows with both counts known, including
#' observed zero counts. A zero denominator total leaves the fraction unavailable;
#' a zero numerator and positive denominator gives an observed zero fraction.
#'
#' @param data Data frame of observation keys and subset counts.
#' @param groups Nonempty character vector of distinct group column names.
#' @param id Name of the observation ID column. Group and ID keys must be
#'   dimensionless nonblank character vectors without NA or ASCII 28 separators.
#' @param numerator Name of the subset-count column, allowing NA.
#' @param denominator Name of the total-count column, allowing NA.
#'
#' @return Data frame sorted by group keys with integer n_supplied, n_available
#'   and n_unavailable; double numerator_total, denominator_total and fraction;
#'   character status and missing_policy. Status precedence is UNAVAILABLE (no
#'   complete count pairs), PARTIAL (some missing counts), ZERO_DENOMINATOR,
#'   COMPLETE. missing_policy is always "propagate". Empty input returns a typed
#'   empty table. Count totals outside the exact integer range fail. Fractions
#'   use ordinary double division after exact count accumulation.
#' @examples
#' d <- data.frame(sample = c("one", "one"), bin = c("a", "b"),
#'                 positive = c(1, 2), total = c(3, 7))
#' SummarizeGroupedCountFractions(d, "sample", "bin", "positive", "total")
#' @export
SummarizeGroupedCountFractions <- function(data, groups, id, numerator, denominator) {
  valid_names <- function(x) {
    is.character(x) && length(x) > 0L && !anyNA(x) &&
      all(nzchar(trimws(x))) && !anyDuplicated(x)
  }
  .exact_assert(valid_names(groups), "Invalid group columns")
  .exact_assert(all(vapply(list(id, numerator, denominator), function(x) {
    valid_names(x) && length(x) == 1L
  }, logical(1))), "Invalid selected columns")
  outputs <- c("n_supplied", "n_available", "n_unavailable", "numerator_total",
    "denominator_total", "fraction", "status", "missing_policy")
  .exact_assert(!anyDuplicated(c(groups, id, numerator, denominator)) &&
                  !any(groups %in% outputs), "Selected columns must be distinct from group outputs")
  .exact_table(data, c(groups, id, numerator, denominator), "data")
  data <- as.data.frame(data)
  .exact_assert(!anyDuplicated(.exact_keys(data, c(groups, id))),
                "Duplicate observation within group")
  maximum <- 2^53 - 1
  valid_counts <- function(x) {
    typeof(x) %in% c("integer", "double") && !is.object(x) && is.null(dim(x)) &&
      !any(is.nan(x)) && all(is.na(x) |
        (is.finite(x) & x >= 0 & x <= maximum & x == floor(x)))
  }
  .exact_assert(valid_counts(data[[numerator]]) && valid_counts(data[[denominator]]),
                "Counts must be plain nonnegative whole numbers up to 2^53 - 1 or NA")
  known <- !is.na(data[[numerator]]) & !is.na(data[[denominator]])
  .exact_assert(all(data[[numerator]][known] <= data[[denominator]][known]),
                "Numerator exceeds denominator")
  exact_sum <- function(x) {
    total <- 0
    for (next_count in x[!is.na(x)]) {
      .exact_assert(next_count <= maximum - total, "Exact count total range exceeded")
      total <- total + next_count
    }
    total
  }
  summarize <- function(n, d) {
    nt <- exact_sum(n)
    dt <- exact_sum(d)
    available <- sum(!is.na(n) & !is.na(d))
    status <- if (available == 0L) "UNAVAILABLE" else if (available < length(n)) "PARTIAL"
      else if (dt == 0) "ZERO_DENOMINATOR" else "COMPLETE"
    if (available < length(n) || !length(n)) nt <- dt <- NA_real_
    list(n_supplied = length(n), n_available = available,
      n_unavailable = length(n) - available, numerator_total = nt,
      denominator_total = dt, fraction = if (status == "COMPLETE") nt / dt else NA_real_,
      status = status, missing_policy = "propagate")
  }
  if (!nrow(data)) {
    return(cbind(data[0, groups, drop = FALSE],
      as.data.frame(summarize(numeric(), numeric()))[0, ]))
  }
  d <- data.table::as.data.table(data[c(groups, numerator, denominator)])
  internal_groups <- paste0("group_", seq_along(groups))
  internal_values <- c("numerator_input", "denominator_input")
  data.table::setnames(d, c(internal_groups, internal_values))
  summarize_columns <- function(part) summarize(part[[1L]], part[[2L]])
  result <- do.call("[", list(d, j = quote(summarize_columns(.SD)),
    by = internal_groups, .SDcols = internal_values))
  data.table::setorderv(result, internal_groups)
  data.table::setnames(result, internal_groups, groups)
  as.data.frame(result)
}
