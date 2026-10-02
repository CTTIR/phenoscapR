#' Summarize Continuous Observations in Explicit Groups
#'
#' Computes arithmetic means, medians and optional threshold fractions or
#' weighted means over supplied observations. No unobserved groups or zeros are
#' manufactured. Observation IDs must be unique within the complete group key.
#' Include the independent sampling unit in `groups` when required; this function
#' does not establish independence, eligibility, review authority or tissue area.
#'
#' Missing observations remain counted. The default suppresses summaries when
#' any required value is unavailable. `missing = "available"` explicitly selects
#' available-case summaries, still labelled PARTIAL. Weighted summaries require
#' both a value and its nonnegative weight, and positive total weight. A weight
#' of zero is an observed zero contribution, not unavailable. `min_available`
#' applies separately to unweighted and weighted available observations.
#'
#' @param data Data frame containing group/observation keys and numeric values.
#' @param groups Nonempty character vector of distinct group columns. Their
#'   values must be dimensionless, nonblank character vectors without NA.
#' @param id Character name of the observation ID column. IDs must be
#'   dimensionless, nonblank character values without NA, unique within each
#'   complete group key. The reserved ASCII 28 separator is rejected in keys.
#' @param value Character column containing finite numeric values or NA.
#' @param weight Optional character column with finite nonnegative weights or NA.
#' @param threshold Optional finite numeric scalar. Reports the fraction of
#'   available values greater than or equal to this fixed threshold.
#' @param min_available Positive integer minimum number of available observations.
#' @param missing Missingness policy: `"propagate"` or explicit `"available"`.
#'
#' @return Data frame sorted by group keys with supplied/available counts, mean,
#'   median, threshold fraction, weighted mean, total available weight, and separate
#'   availability statuses and
#'   the missingness policy. Status is COMPLETE, PARTIAL, INSUFFICIENT or
#'   UNAVAILABLE; optional weighted status also uses NOT_REQUESTED and
#'   NO_POSITIVE_WEIGHT. Empty input returns a typed empty table. Numerical
#'   overflow or product underflow fails rather than producing a misleading summary.
#'   `weight_sum` counts only pairs with both value and weight available; it is
#'   zero for observed zero weights, and NA when policy suppresses a weighted
#'   summary or weights were not requested.
#' @examples
#' d <- data.frame(sample = c("one", "one"), cell = c("a", "b"),
#'   score = c(1, 3), area = c(1, 3))
#' SummarizeGroupedValues(d, "sample", "cell", "score", "area", threshold = 2)
#' @export
SummarizeGroupedValues <- function(data, groups, id, value, weight = NULL,
                                   threshold = NULL, min_available = 1L,
                                   missing = c("propagate", "available")) {
  missing <- match.arg(missing)
  valid_name <- function(x) {
    is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
  }
  .exact_assert(is.character(groups) && length(groups) > 0L && !anyNA(groups) &&
                  all(nzchar(trimws(groups))) && !anyDuplicated(groups),
                "Groups require unique nonempty column names")
  .exact_assert(valid_name(id) && valid_name(value) &&
                  (is.null(weight) || valid_name(weight)), "Invalid selected columns")
  outputs <- c("n_supplied", "n_available", "n_unavailable", "mean", "median",
    "fraction_at_least", "status", "n_weighted_available", "weighted_mean",
    "weighted_status", "weight_sum", "missing_policy")
  .exact_assert(!any(groups %in% outputs) && !id %in% groups &&
                  !value %in% c(groups, id) &&
                  (is.null(weight) || !weight %in% c(groups, id, value)),
                "Group, observation, value, weight and output columns must be distinct")
  .exact_table(data, c(groups, id, value, weight), "data")
  data <- as.data.frame(data)
  .exact_assert(!anyDuplicated(.exact_keys(data, c(groups, id))),
                "Duplicate observation within group")
  numeric_values <- function(x) {
    is.numeric(x) && is.null(dim(x)) && all(is.na(x) | is.finite(x))
  }
  .exact_assert(numeric_values(data[[value]]), "Values must be finite numeric values or NA")
  if (!is.null(weight)) {
    .exact_assert(numeric_values(data[[weight]]) &&
                    all(is.na(data[[weight]]) | data[[weight]] >= 0),
                  "Weights must be finite nonnegative values or NA")
  }
  .exact_assert(is.numeric(min_available) && length(min_available) == 1L &&
                  is.finite(min_available) && min_available >= 1 &&
                  min_available == floor(min_available), "Invalid availability minimum")
  .exact_assert(is.null(threshold) || (is.numeric(threshold) &&
                  length(threshold) == 1L && is.finite(threshold)), "Invalid threshold")
  describe <- function(available, total) {
    if (available == 0L) "UNAVAILABLE" else if (available < min_available) "INSUFFICIENT"
    else if (available < total) "PARTIAL" else "COMPLETE"
  }
  allowed <- function(n, total) {
    n >= min_available && (missing == "available" || n == total)
  }
  summarize <- function(v, w = NULL) {
    keep <- !is.na(v)
    n <- sum(keep)
    use <- allowed(n, length(v))
    mean_value <- if (use) mean(v[keep]) else NA_real_
    median_value <- if (use) stats::median(v[keep]) else NA_real_
    fraction <- if (use && !is.null(threshold)) mean(v[keep] >= threshold) else NA_real_
    weighted <- NA_real_
    total_weight <- NA_real_
    nw <- NA_integer_
    ws <- "NOT_REQUESTED"
    if (!is.null(w)) {
      good <- keep & !is.na(w)
      nw <- sum(good)
      ws <- describe(nw, length(v))
      if (nw >= min_available && !any(w[good] > 0)) ws <- "NO_POSITIVE_WEIGHT"
      if (allowed(nw, length(v))) {
        total_weight <- sum(w[good])
        .exact_assert(is.finite(total_weight), "Numerical range exceeded in weight total")
      }
      if (allowed(nw, length(v)) && any(w[good] > 0)) {
        products <- v[good] * w[good]
        .exact_assert(is.finite(sum(w[good])) && all(is.finite(products)) &&
                        all(products != 0 | v[good] == 0 | w[good] == 0),
                      "Numerical range exceeded in weighted summary")
        weighted <- stats::weighted.mean(v[good], w[good])
        .exact_assert(is.finite(weighted), "Numerical range exceeded in weighted summary")
      }
    }
    .exact_assert(all(is.na(c(mean_value, median_value, weighted)) |
                        is.finite(c(mean_value, median_value, weighted))),
                  "Numerical range exceeded in summary")
    list(n_supplied = length(v), n_available = n, n_unavailable = length(v) - n,
      mean = mean_value, median = median_value, fraction_at_least = fraction,
      status = describe(n, length(v)), n_weighted_available = nw,
      weighted_mean = weighted, weighted_status = ws, weight_sum = total_weight,
      missing_policy = missing)
  }
  if (!nrow(data)) {
    template <- summarize(numeric(), if (!is.null(weight)) numeric() else NULL)
    return(cbind(data[0, groups, drop = FALSE], as.data.frame(template)[0, ]))
  }
  d <- data.table::as.data.table(data[c(groups, value, weight)])
  internal_groups <- paste0("group_", seq_along(groups))
  internal_values <- if (is.null(weight)) "value_input" else c("value_input", "weight_input")
  data.table::setnames(d, c(internal_groups, internal_values))
  summarize_columns <- function(part) {
    summarize(part[[1L]], if (ncol(part) > 1L) part[[2L]] else NULL)
  }
  result <- do.call("[", list(d, j = quote(summarize_columns(.SD)),
    by = internal_groups, .SDcols = internal_values))
  data.table::setorderv(result, internal_groups)
  data.table::setnames(result, internal_groups, groups)
  as.data.frame(result)
}
