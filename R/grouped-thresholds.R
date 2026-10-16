#' Apply Supplied Group Thresholds to Observations
#'
#' Looks up one supplied threshold per composite group and tests strictly greater
#' than. Thresholds are not estimated; equality is FALSE. Eligibility and numeric
#' availability remain explicit. No labels, units or observation universe are
#' inferred. Unknown groups fail, including groups of ineligible observations.
#'
#' @param data Data frame of observations. Original columns, metadata and row
#'   order are preserved; inputs are not mutated.
#' @param thresholds Data frame with one threshold per unique group. Extra groups
#'   are permitted. Supply an explicit NA threshold for an unavailable group.
#' @param groups Nonempty plain character vector of distinct group column names.
#' @param id Plain character scalar naming the observation ID column. Identity
#'   is unique within groups; IDs may recur across different groups.
#' @param value Plain character scalar naming the observation value column.
#' @param threshold Plain character scalar naming the supplied threshold column.
#'   Selected numeric columns must be plain integer/double, finite or NA; classed,
#'   dimensional, complex, NaN and infinite values fail even when ineligible.
#' @param eligible Plain character scalar naming a plain logical eligibility
#'   column. TRUE, FALSE and NA are distinct. Data roles must not overlap;
#'   threshold must not overlap groups. Keys are plain nonblank character values
#'   without NA or ASCII 28. Selectors are dimensionless and nonblank.
#'
#' @return A data frame with all original observation columns unchanged, followed
#'   by threshold_value (double), threshold_available and value_available
#'   (logical), above_threshold (logical or NA), and threshold_status (character).
#'   Original columns with these reserved names fail. Status precedence is
#'   INELIGIBLE, UNKNOWN_ELIGIBILITY, MISSING_VALUE_AND_THRESHOLD,
#'   MISSING_THRESHOLD, MISSING_VALUE, COMPLETE. Availability flags retain numeric
#'   missingness independently of eligibility. Only eligible observations with
#'   both numbers known receive a comparison. Empty inputs retain typed outputs;
#'   nonempty observations require complete group-reference coverage. Metadata
#'   classes and the original value storage type are preserved. Units must agree
#'   upstream; no conversion is performed.
#' @examples
#' d <- data.frame(group = "a", id = c("x", "y"), value = c(1, 2), eligible = TRUE)
#' r <- data.frame(group = "a", cutoff = 1)
#' ApplyGroupedThresholds(d, r, "group", "id", "value", "cutoff", "eligible")
#' @export
ApplyGroupedThresholds <- function(data, thresholds, groups, id, value, threshold, eligible) {
  valid_names <- function(x) {
    is.character(x) && !is.object(x) && is.null(dim(x)) && length(x) > 0L &&
      !anyNA(x) && all(nzchar(trimws(x))) && !anyDuplicated(x)
  }
  .exact_assert(valid_names(groups), "Invalid group columns")
  for (selector in list(id, value, threshold, eligible)) {
    .exact_assert(valid_names(selector) && length(selector) == 1L, "Invalid scalar selector")
  }
  .exact_assert(!anyDuplicated(c(groups, id, value, eligible)), "Data roles overlap")
  .exact_assert(!threshold %in% groups, "Threshold overlaps groups")
  .exact_table(data, c(groups, id, value, eligible), "data")
  .exact_table(thresholds, c(groups, threshold), "thresholds")
  .exact_assert(valid_names(names(data)) && valid_names(names(thresholds)),
                "Table column names must be nonblank")
  reserved <- c("threshold_value", "threshold_available", "value_available",
                "above_threshold", "threshold_status")
  .exact_assert(!any(names(data) %in% reserved), "Data columns collide with outputs")
  result <- as.data.frame(data.table::copy(data))
  refs <- as.data.frame(data.table::copy(thresholds))
  plain_keys <- function(x, columns) {
    all(vapply(x[columns], function(z) is.character(z) && !is.object(z), logical(1)))
  }
  .exact_assert(plain_keys(result, c(groups, id)) && plain_keys(refs, groups),
                "Keys must be plain character values")
  observation_keys <- .exact_keys(result, c(groups, id))
  group_keys <- .exact_keys(result, groups)
  reference_keys <- .exact_keys(refs, groups)
  .exact_assert(!anyDuplicated(observation_keys), "Duplicate observation identity")
  .exact_assert(!anyDuplicated(reference_keys), "Duplicate threshold group")
  index <- match(group_keys, reference_keys)
  .exact_assert(!anyNA(index), "Unknown observation group")
  numeric_values <- function(x) {
    typeof(x) %in% c("integer", "double") && !is.object(x) && is.null(dim(x)) &&
      !any(is.nan(x)) && all(is.na(x) | is.finite(x))
  }
  .exact_assert(numeric_values(result[[value]]) && numeric_values(refs[[threshold]]),
                "Values and thresholds must be plain finite numbers or NA")
  eligibility <- result[[eligible]]
  .exact_assert(is.logical(eligibility) && !is.object(eligibility) && is.null(dim(eligibility)),
                "Eligibility must be plain logical")
  matched <- as.numeric(refs[[threshold]][index])
  value_available <- !is.na(result[[value]])
  threshold_available <- !is.na(matched)
  usable <- eligibility %in% TRUE & value_available & threshold_available
  above <- rep(NA, nrow(result))
  above[usable] <- result[[value]][usable] > matched[usable]
  status <- rep("COMPLETE", nrow(result))
  status[!value_available] <- "MISSING_VALUE"
  status[!threshold_available] <- "MISSING_THRESHOLD"
  status[!value_available & !threshold_available] <- "MISSING_VALUE_AND_THRESHOLD"
  status[is.na(eligibility)] <- "UNKNOWN_ELIGIBILITY"
  status[eligibility %in% FALSE] <- "INELIGIBLE"
  result$threshold_value <- matched
  result$threshold_available <- threshold_available
  result$value_available <- value_available
  result$above_threshold <- above
  result$threshold_status <- status
  result
}
