#' Assemble Registered Paired Summaries
#'
#' Aligns already computed scalar summaries to an explicit expected group
#' registry. Computes the first side or first minus second side without pooling
#' observations or changing the supplied estimator. Choose the value and count
#' columns appropriate to the estimator, for example weighted_mean and
#' n_weighted_available from SummarizeGroupedValues(). This is descriptive
#' assembly, not an independence assessment or inferential test.
#'
#' Absent sides retain NA values, zero counts and a false presence flag.
#' Observed NA counts remain unknown. Optional weight totals are provenance
#' only and never used to reconstruct counts or recompute supplied values.
#' The registry defines output order; extra registry columns are ignored.
#'
#' @param data Data frame of precomputed summaries, at most one row per group
#'   and side. Extra columns are ignored.
#' @param registry Data frame with distinct expected group keys.
#' @param groups Nonempty character vector of distinct group columns. Keys must
#'   be nonblank character vectors without NA or the reserved ASCII 28 separator.
#' @param side Name of the character side column.
#' @param value Name of the finite plain integer/double summary column, allowing
#'   NA. Classed vectors (including factors, dates and integer64) are rejected
#'   for values, counts, weight totals and min_count; names are permitted.
#' @param count Name of the nonnegative whole-number count column, allowing NA.
#' @param weight_sum Optional name of a nonnegative finite numeric denominator
#'   column, allowing NA. Missing-side totals remain NA, not an observed zero.
#' @param sides Two distinct nonblank side labels, in subtraction order.
#' @param contrast Either "difference" (first minus second) or "first".
#' @param min_count Positive whole-number minimum for each required side.
#'
#' @return Data frame in registry order with keys, first/second presence, values,
#'   counts and weight totals, value, status, contrast, side labels and minimum.
#'   Status precedence is MISSING_SIDE, UNKNOWN_COUNT, INSUFFICIENT_COUNT,
#'   UNAVAILABLE_VALUE, COMPLETE, considering required sides only. An empty
#'   registry with empty data returns a typed empty table. Unknown group/side
#'   keys, duplicates, malformed numbers and arithmetic overflow fail.
#' @examples
#' d <- data.frame(sample = c("one", "one"), arm = c("A", "B"),
#'                 average = c(4, 1), n = c(3, 2))
#' AssemblePairedSummaries(d, data.frame(sample = c("one", "two")),
#'                         "sample", "arm", "average", "n")
#' @export
AssemblePairedSummaries <- function(data, registry, groups, side, value, count,
                                   weight_sum = NULL, sides = c("A", "B"),
                                   contrast = c("difference", "first"), min_count = 1L) {
  contrast <- match.arg(contrast)
  valid_names <- function(x) {
    is.character(x) && length(x) > 0L && !anyNA(x) &&
      all(nzchar(trimws(x))) && !anyDuplicated(x)
  }
  .exact_assert(valid_names(groups), "Invalid group columns")
  selected <- c(side, value, count, weight_sum)
  .exact_assert(all(vapply(list(side, value, count), function(x) {
    valid_names(x) && length(x) == 1L
  }, logical(1))) && (is.null(weight_sum) ||
    (valid_names(weight_sum) && length(weight_sum) == 1L)), "Invalid selected columns")
  outputs <- c("first_present", "second_present", "first_value", "second_value",
    "first_count", "second_count", "first_weight_sum", "second_weight_sum",
    "value", "status", "contrast", "first_side", "second_side", "min_count")
  .exact_assert(!anyDuplicated(c(groups, selected)) && !any(groups %in% outputs),
                "Selected columns must be distinct and groups must not collide with outputs")
  .exact_assert(valid_names(sides) && length(sides) == 2L &&
                  !any(grepl("\034", sides, fixed = TRUE)), "Invalid side labels")
  .exact_assert(typeof(min_count) %in% c("integer", "double") &&
                  !is.object(min_count) && is.null(dim(min_count)) && length(min_count) == 1L &&
                  is.finite(min_count) && min_count >= 1 && min_count == floor(min_count),
                "Invalid count minimum")
  .exact_table(data, c(groups, selected), "data")
  .exact_table(registry, groups, "registry")
  data <- as.data.frame(data)
  registry <- as.data.frame(registry)[groups]
  rownames(registry) <- NULL
  dk <- .exact_keys(data, groups)
  rk <- .exact_keys(registry, groups)
  .exact_assert(!anyDuplicated(rk), "Duplicate registry group")
  .exact_assert(!anyDuplicated(.exact_keys(data, c(groups, side))),
                "Duplicate group and side")
  .exact_assert(all(dk %in% rk), "Unknown data group")
  .exact_assert(all(data[[side]] %in% sides), "Unknown data side")
  numeric_values <- function(x) {
    typeof(x) %in% c("integer", "double") && !is.object(x) && is.null(dim(x)) && !any(is.nan(x)) &&
      all(is.na(x) | is.finite(x))
  }
  .exact_assert(numeric_values(data[[value]]), "Values must be finite numeric values or NA")
  counts <- data[[count]]
  .exact_assert(numeric_values(counts) && all(is.na(counts) |
    (counts >= 0 & counts == floor(counts))), "Counts must be nonnegative whole numbers or NA")
  if (!is.null(weight_sum)) {
    w <- data[[weight_sum]]
    .exact_assert(numeric_values(w) && all(is.na(w) | w >= 0),
                  "Weight totals must be finite nonnegative numbers or NA")
  }
  result <- registry
  for (i in seq_along(sides)) {
    label <- c("first", "second")[i]
    rows <- which(data[[side]] == sides[i])
    index <- rows[match(rk, dk[rows])]
    present <- !is.na(index)
    result[[paste0(label, "_present")]] <- present
    result[[paste0(label, "_value")]] <- as.numeric(data[[value]][index])
    result[[paste0(label, "_count")]] <- as.numeric(ifelse(present, data[[count]][index], 0))
    result[[paste0(label, "_weight_sum")]] <- if (is.null(weight_sum)) {
      rep(NA_real_, length(rk))
    } else {
      as.numeric(data[[weight_sum]][index])
    }
  }
  required <- if (contrast == "difference") c("first", "second") else "first"
  status <- rep("COMPLETE", length(rk))
  for (label in rev(required)) {
    present <- result[[paste0(label, "_present")]]
    n <- result[[paste0(label, "_count")]]
    v <- result[[paste0(label, "_value")]]
    status[is.na(v) & status == "COMPLETE"] <- "UNAVAILABLE_VALUE"
    status[!is.na(n) & n < min_count &
      status %in% c("COMPLETE", "UNAVAILABLE_VALUE")] <- "INSUFFICIENT_COUNT"
    status[is.na(n) & status != "MISSING_SIDE"] <- "UNKNOWN_COUNT"
    status[!present] <- "MISSING_SIDE"
  }
  computed <- result$first_value
  if (contrast == "difference") computed <- computed - result$second_value
  eligible <- status == "COMPLETE"
  .exact_assert(all(is.finite(computed[eligible])), "Numerical range exceeded in contrast")
  computed[!eligible] <- NA_real_
  result$value <- computed
  result$status <- status
  result$contrast <- rep(contrast, length(rk))
  result$first_side <- rep(sides[1L], length(rk))
  result$second_side <- rep(sides[2L], length(rk))
  result$min_count <- rep(min_count, length(rk))
  result
}
