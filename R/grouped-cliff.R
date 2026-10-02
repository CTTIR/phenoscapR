#' Compare Two Distributions Within Explicit Groups
#'
#' Computes descriptive Cliff's delta as the number of A-greater-than-B pairs
#' minus A-less-than-B pairs, divided by all available cross-arm pairs. Ties
#' contribute zero. No inferential p value or independence claim is supplied.
#' Pair counts use sorted value frequencies without a cross-product matrix or
#' value subtraction. Every registered group is retained, including empty arms.
#'
#' @param data Data frame with group keys, observation IDs, arms and values.
#' @param registry Data frame containing every allowed group key exactly once.
#' @param groups Nonempty character vector naming distinct group columns.
#' @param id Character name of the observation ID column; IDs are unique within
#'   each complete group key.
#' @param arm Character name of the arm column, containing exactly `"A"` or `"B"`.
#' @param value Character name of a numeric column containing finite values
#'   or explicit NA.
#'   NaN and infinities are rejected. Convert nonfinite input values to NA only
#'   through an explicit upstream policy.
#' @param missing `"propagate"` suppresses delta if any supplied value is NA;
#'   `"available"` explicitly uses available values independently in each arm.
#' @details
#' Group keys and observation IDs must be dimensionless, nonmissing, nonblank
#' character vectors. Factors and numeric IDs are not coerced. The reserved
#' ASCII 28 separator (`intToUtf8(28)`) is rejected in keys. Column selections
#' must be distinct, and group columns must not collide with output names.
#' Registry keys must be unique. Every observation must belong to a registered
#' group and have a unique ID within that complete group, including across arms.
#' The same ID may occur in different groups. Arm values must be exactly `"A"`
#' or `"B"`; no labels or population policy are inferred.
#'
#' Delta is positive when A tends to exceed B and negative when B tends to
#' exceed A. It equals the proportion of available cross-arm pairs with A
#' greater than B minus the proportion with A less than B. Equal values,
#' including signed zeros, are ties. Comparisons use represented numeric values
#' without a tolerance. No value subtraction, cross-pair matrix, rank test or
#' resampling is performed. Pair counts above `2^53 - 1` are rejected before
#' multiplication rather than rounded. Sorting distinct values and counting
#' frequencies avoids allocating a Cartesian product, but input and distinct
#' values must still fit in memory.
#'
#' Available-case analysis filters missing values separately within each arm;
#' it is not paired-observation deletion. Propagation suppresses delta when
#' either supplied arm contains missing values, while still reporting the
#' available pair counts. If an available arm is empty, status is `UNAVAILABLE`
#' under either policy. A declared group without observations is retained.
#' Group membership and missingness policies do not establish independence or
#' exchangeability. This function computes a descriptive effect only.
#'
#' @return Data frame sorted by group keys, preserving original key values.
#'   Supplied, available and unavailable counts are returned for each arm,
#'   together with available cross-pair, greater, less and tied counts, delta,
#'   missingness policy and status. Empty available arms yield UNAVAILABLE;
#'   otherwise propagation with missing values yields MISSING_VALUES, followed
#'   by PARTIAL or COMPLETE. Pair counts always describe available values even
#'   when delta is suppressed. Counts exceeding exact binary64 integer capacity
#'   are rejected before multiplication. An empty registry returns typed output.
#' @examples
#' d <- data.frame(
#'   g = "one", id = letters[1:4],
#'   arm = c("A", "A", "B", "B"), value = c(2, 4, 1, 2)
#' )
#' ContrastGroupedRanks(d, data.frame(g = "one"), "g", "id", "arm", "value")
#' @export
ContrastGroupedRanks <- function(data, registry, groups, id, arm, value,
                                 missing = c("propagate", "available")) {
  missing <- match.arg(missing)
  valid_names <- function(x) {
    is.character(x) && is.null(dim(x)) && length(x) > 0L &&
      !anyNA(x) && all(nzchar(trimws(x))) && !anyDuplicated(x)
  }
  .exact_assert(valid_names(groups), "Invalid group columns")
  .exact_assert(all(vapply(list(id, arm, value), function(x) {
    valid_names(x) && length(x) == 1L
  }, logical(1))), "Invalid selected columns")
  selected <- c(groups, id, arm, value)
  outputs <- c(
    "n_a_supplied", "n_b_supplied", "n_a_available", "n_b_available",
    "n_a_unavailable", "n_b_unavailable", "n_pairs", "n_a_greater",
    "n_a_less", "n_tied", "delta_a_vs_b", "status", "missing_policy"
  )
  .exact_assert(
    !anyDuplicated(selected) && !any(groups %in% outputs),
    "Selected columns and group/output columns must be distinct"
  )
  .exact_table(data, selected, "data")
  .exact_table(registry, groups, "registry")
  data <- as.data.frame(data)
  registry <- as.data.frame(registry)[groups]
  .exact_assert(all(vapply(c(data[c(groups, id, arm)], registry), function(x) {
    is.null(dim(x))
  }, logical(1))), "Keys and arms must be dimensionless character vectors")
  row_keys <- function(x, columns) {
    .exact_assert(all(vapply(x[columns], function(z) {
      is.character(z) && !anyNA(z) && all(nzchar(trimws(z))) &&
        !any(grepl("\034", z, fixed = TRUE))
    }, logical(1))), "Keys must be nonempty character values without reserved separators")
    do.call(paste, c(unname(x[columns]), list(sep = "\034")))
  }
  .exact_assert(
    !anyDuplicated(row_keys(data, c(groups, id))),
    "Duplicate observation within group"
  )
  keys <- row_keys(data, groups)
  registered <- row_keys(registry, groups)
  .exact_assert(!anyDuplicated(registered), "Duplicate registered group")
  row_keys(data, arm)
  .exact_assert(all(data[[arm]] %in% c("A", "B")), "arm must be A or B")
  group_index <- match(keys, registered)
  .exact_assert(!anyNA(group_index), "Data contain an unregistered group")
  values <- data[[value]]
  .exact_assert(
    is.numeric(values) && is.null(dim(values)) &&
      !any(is.nan(values)) && all(is.na(values) | is.finite(values)),
    "Values must be finite numeric values or NA"
  )
  summarize <- function(a, b) {
    supplied_a <- length(a)
    supplied_b <- length(b)
    a <- a[!is.na(a)]
    b <- b[!is.na(b)]
    na <- length(a)
    nb <- length(b)
    .exact_assert(
      nb == 0 || na <= floor((2^53 - 1) / nb),
      "Pair count exceeds exact integer capacity"
    )
    pairs <- as.double(na) * as.double(nb)
    greater <- tied <- less <- 0
    if (pairs > 0) {
      levels <- sort(unique(c(a, b)), method = "radix")
      counts_a <- as.double(tabulate(match(a, levels), nbins = length(levels)))
      counts_b <- as.double(tabulate(match(b, levels), nbins = length(levels)))
      below_b <- c(0, head(cumsum(counts_b), -1L))
      greater <- sum(counts_a * below_b)
      tied <- sum(counts_a * counts_b)
      less <- pairs - greater - tied
    }
    partial <- na < supplied_a || nb < supplied_b
    status <- if (!pairs) {
      "UNAVAILABLE"
    } else if (partial && missing == "propagate") {
      "MISSING_VALUES"
    } else if (partial) {
      "PARTIAL"
    } else {
      "COMPLETE"
    }
    delta <- if (status %in% c("COMPLETE", "PARTIAL")) {
      (greater - less) / pairs
    } else {
      NA_real_
    }
    data.frame(
      n_a_supplied = supplied_a, n_b_supplied = supplied_b,
      n_a_available = na, n_b_available = nb,
      n_a_unavailable = supplied_a - na, n_b_unavailable = supplied_b - nb,
      n_pairs = pairs, n_a_greater = greater, n_a_less = less, n_tied = tied,
      delta_a_vs_b = delta, status = status, missing_policy = missing
    )
  }
  if (!nrow(registry)) {
    return(cbind(registry, summarize(numeric(), numeric())[0, ]))
  }
  indices <- split(seq_len(nrow(data)), factor(group_index,
    levels = seq_len(nrow(registry))
  ), drop = FALSE)
  rows <- lapply(indices, function(i) {
    summarize(
      values[i][data[[arm]][i] == "A"],
      values[i][data[[arm]][i] == "B"]
    )
  })
  out <- cbind(registry, do.call(rbind, rows))
  sort_keys <- lapply(out[groups], enc2utf8)
  out <- out[do.call(order, c(unname(sort_keys), list(method = "radix"))), , drop = FALSE]
  rownames(out) <- NULL
  out
}
