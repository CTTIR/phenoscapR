#' Correlate Paired Ranks Within Explicit Groups
#'
#' Computes descriptive Spearman correlations over paired observations, using
#' average ranks for ties. Each observation must occur once per complete group
#' key. Include the independent sampling unit in `groups`; no independence,
#' eligibility, causal interpretation or inferential p value is established.
#' Missingness is paired: a row is available only when both values are known.
#' The default suppresses correlation when any pair is unavailable. Explicit
#' available-case analysis retains the supplied and unavailable pair counts.
#'
#' @param data Data frame with group keys, observation IDs and paired values.
#' @param groups Nonempty character vector of distinct group columns with
#'   nonempty character values and no missing keys.
#' @param id Character column naming observations within each group.
#' @param x,y Distinct numeric value columns. Finite numbers and NA are allowed;
#'   NaN and infinite values are rejected.
#' @param min_pairs Integer minimum available pair count, at least two.
#' @param missing Missingness policy: `"propagate"` or explicit `"available"`.
#' @return Data frame sorted by group keys with `n_supplied`, `n_available`,
#'   `n_unavailable`, available-pair `n_unique_x` and `n_unique_y`, `rho`,
#'   `status`, and `missing_policy`. Status precedence is UNAVAILABLE,
#'   INSUFFICIENT, MISSING_PAIRS (propagation), CONSTANT_BOTH, CONSTANT_X,
#'   CONSTANT_Y, then COMPLETE or PARTIAL. Suppressed correlations are NA.
#'   Empty input returns a typed empty table; absent groups are not invented.
#' @examples
#' d <- data.frame(sample = "one", cell = letters[1:4],
#'                 a = c(1, 1, 3, 4), b = c(4, 3, 2, 1))
#' CorrelateGroupedRanks(d, "sample", "cell", "a", "b")
#' @export
CorrelateGroupedRanks <- function(data, groups, id, x, y, min_pairs = 3L,
                                  missing = c("propagate", "available")) {
  missing <- match.arg(missing)
  valid_name <- function(z) {
    is.character(z) && is.null(dim(z)) && length(z) == 1L &&
      !is.na(z) && nzchar(trimws(z))
  }
  .exact_assert(is.character(groups) && is.null(dim(groups)) &&
                  length(groups) > 0L && !anyNA(groups) &&
                  all(nzchar(trimws(groups))) && !anyDuplicated(groups),
                "Groups require distinct nonempty column names")
  .exact_assert(valid_name(id) && valid_name(x) && valid_name(y),
                "Invalid selected columns")
  selected <- c(groups, id, x, y)
  outputs <- c("n_supplied", "n_available", "n_unavailable", "n_unique_x",
    "n_unique_y", "rho", "status", "missing_policy")
  .exact_assert(!anyDuplicated(selected) && !any(groups %in% outputs),
                "Selected columns and group/output columns must be distinct")
  .exact_table(data, selected, "data")
  data <- as.data.frame(data)
  .exact_assert(all(vapply(data[c(groups, id)], function(z) {
    is.null(dim(z))
  }, logical(1))), "Keys must be dimensionless character vectors")
  .exact_assert(!anyDuplicated(.exact_keys(data, c(groups, id))),
                "Duplicate observation within group")
  valid_values <- function(z) {
    is.numeric(z) && is.null(dim(z)) && !any(is.nan(z)) &&
      all(is.na(z) | is.finite(z))
  }
  .exact_assert(valid_values(data[[x]]) && valid_values(data[[y]]),
                "Values must be finite numeric values or NA")
  .exact_assert(is.numeric(min_pairs) && is.null(dim(min_pairs)) &&
                  length(min_pairs) == 1L && is.finite(min_pairs) &&
                  min_pairs >= 2 && min_pairs == floor(min_pairs),
                "min_pairs must be an integer of at least two")
  summarize <- function(a, b) {
    keep <- !is.na(a) & !is.na(b)
    n <- sum(keep)
    nx <- length(unique(a[keep]))
    ny <- length(unique(b[keep]))
    status <- if (!n) "UNAVAILABLE" else if (n < min_pairs) "INSUFFICIENT"
    else if (n < length(a) && missing == "propagate") "MISSING_PAIRS"
    else if (nx < 2L && ny < 2L) "CONSTANT_BOTH"
    else if (nx < 2L) "CONSTANT_X" else if (ny < 2L) "CONSTANT_Y"
    else if (n < length(a)) "PARTIAL" else "COMPLETE"
    rho <- if (status %in% c("COMPLETE", "PARTIAL")) {
      stats::cor(a[keep], b[keep], method = "spearman")
    } else {
      NA_real_
    }
    .exact_assert(is.na(rho) || (is.finite(rho) && abs(rho) <= 1),
                  "Invalid rank correlation result")
    list(n_supplied = length(a), n_available = n,
      n_unavailable = length(a) - n, n_unique_x = nx, n_unique_y = ny,
      rho = rho, status = status, missing_policy = missing)
  }
  if (!nrow(data)) {
    return(cbind(data[0, groups, drop = FALSE],
      as.data.frame(summarize(numeric(), numeric()))[0, ]))
  }
  d <- data.table::as.data.table(data[c(groups, x, y)])
  internal_groups <- paste0("group_", seq_along(groups))
  internal_values <- c("value_x", "value_y")
  data.table::setnames(d, c(internal_groups, internal_values))
  summarize_columns <- function(part) summarize(part[[1L]], part[[2L]])
  result <- do.call("[", list(d, j = quote(summarize_columns(.SD)),
    by = internal_groups, .SDcols = internal_values))
  data.table::setorderv(result, internal_groups)
  data.table::setnames(result, internal_groups, groups)
  as.data.frame(result)
}
