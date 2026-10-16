#' Complete Numeric Observations Against an Explicit Registry
#'
#' Matches one numeric observation to each caller-supplied composite registry key.
#' The registry defines the entire row universe and its order. No Cartesian
#' product, observed group, eligibility rule or biological absence is inferred.
#' The required absent_value applies only to absent rows, never to observed NA.
#'
#' Both tables require unique composite keys. Unknown data keys fail rather than
#' being discarded. Registry metadata is authoritative and carried unchanged;
#' extra data columns are ignored. Inputs are not mutated. Values are normalized
#' to double; no arithmetic or aggregation is performed.
#'
#' @param data Data frame containing the selected keys and numeric value column.
#' @param registry Data frame with every expected composite key, in output order.
#'   Additional metadata columns retain their values and classes. It must not
#'   contain the selected value column or observed, status, absent_value columns.
#' @param keys Nonempty plain character vector of distinct key column names.
#'   Key columns must be plain dimensionless nonblank character vectors without
#'   NA or the reserved ASCII 28 separator.
#' @param value Plain character scalar naming the value column, distinct from
#'   keys and reserved output names. Values must be plain integer/double vectors,
#'   finite or NA. Complex, classed, dimensional, infinite and NaN values fail.
#'   Names on numeric vectors are permitted.
#' @param absent_value Required plain integer/double scalar, finite or NA_real_.
#'   No default is supplied. Choosing zero explicitly does not impute observed NA.
#'
#' @return A data frame with registry columns, the selected value (double),
#'   observed (logical), status (character), and absent_value (double policy).
#'   Status is OBSERVED for known matched values, OBSERVED_MISSING for matched NA,
#'   ABSENT_FILLED for absent rows with finite fill, or ABSENT_UNAVAILABLE for
#'   absent rows with NA fill. Row count and order equal the registry. Empty
#'   registry requires empty data and returns a typed empty result. Provenance
#'   distinguishes observed zero, filled zero, observed NA and absent NA.
#' @examples
#' d <- data.frame(bin = c("a", "b"), fraction = c(0.5, NA_real_))
#' expected <- data.frame(bin = c("a", "b", "c"), sample = "one")
#' CompleteRegisteredValues(d, expected, "bin", "fraction", absent_value = 0)
#' @export
CompleteRegisteredValues <- function(data, registry, keys, value, absent_value) {
  valid_names <- function(x) {
    is.character(x) && !is.object(x) && is.null(dim(x)) && length(x) > 0L &&
      !anyNA(x) && all(nzchar(trimws(x))) && !anyDuplicated(x)
  }
  .exact_assert(valid_names(keys), "Invalid key columns")
  .exact_assert(valid_names(value) && length(value) == 1L, "Invalid value column")
  reserved <- c("observed", "status", "absent_value")
  .exact_assert(!value %in% c(keys, reserved), "Value column collides with keys or outputs")
  .exact_table(data, c(keys, value), "data")
  .exact_table(registry, keys, "registry")
  .exact_assert(!any(names(registry) %in% c(value, reserved)),
                "Registry columns collide with outputs")
  data <- as.data.frame(data.table::copy(data))
  result <- as.data.frame(data.table::copy(registry))
  plain_keys <- function(x) {
    all(vapply(x[keys], function(z) is.character(z) && !is.object(z), logical(1)))
  }
  .exact_assert(plain_keys(data) && plain_keys(result), "Keys must be plain character values")
  dk <- .exact_keys(data, keys)
  rk <- .exact_keys(result, keys)
  .exact_assert(!anyDuplicated(dk), "Duplicate data key")
  .exact_assert(!anyDuplicated(rk), "Duplicate registry key")
  .exact_assert(all(dk %in% rk), "Unknown data key")
  numeric_values <- function(x) {
    typeof(x) %in% c("integer", "double") && !is.object(x) && is.null(dim(x)) &&
      !any(is.nan(x)) && all(is.na(x) | is.finite(x))
  }
  .exact_assert(numeric_values(data[[value]]), "Values must be plain finite numbers or NA")
  .exact_assert(numeric_values(absent_value) && length(absent_value) == 1L,
                "Absent value must be one plain finite number or NA")
  index <- match(rk, dk)
  present <- !is.na(index)
  values <- as.numeric(data[[value]][index])
  values[!present] <- as.numeric(absent_value)
  status <- rep(if (is.na(absent_value)) "ABSENT_UNAVAILABLE" else "ABSENT_FILLED", length(rk))
  status[present] <- "OBSERVED"
  status[present & is.na(values)] <- "OBSERVED_MISSING"
  result[[value]] <- values
  result$observed <- present
  result$status <- status
  result$absent_value <- rep(as.numeric(absent_value), length(rk))
  result
}
