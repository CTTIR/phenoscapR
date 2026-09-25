# Explicit patient-level exact inference; no cell-level replication is inferred.
.exact_assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}

.exact_table <- function(x, columns, what) {
  .exact_assert(is.data.frame(x) && all(columns %in% names(x)),
                paste(what, "requires columns", paste(columns, collapse = ", ")))
  .exact_assert(!anyDuplicated(names(x)), paste(what, "has duplicate columns"))
}

.exact_keys <- function(x, columns) {
  .exact_assert(all(vapply(x[columns], function(z) {
    is.character(z) && !anyNA(z) && all(nzchar(trimws(z))) &&
      !any(grepl("\034", z, fixed = TRUE))
  }, logical(1))), "Keys must be nonempty character values without reserved separators")
  do.call(paste, c(x[columns], sep = "\034"))
}

#' Exact Allocation Tests of Independent Patient Endpoints
#'
#' Enumerates every allocation with the declared group sizes. The statistic is
#' the mean in A minus the mean in B; the two-sided p value is the fraction with
#' absolute statistic at least the observed absolute statistic minus 1e-12.
#' This requires exchangeability under the null. Observational confounding,
#' paired designs and stratified randomisation are not addressed by this test.
#' Repeated images must be aggregated to one endpoint per patient beforehand.
#'
#' @param endpoints Data frame with character `endpoint_id`, `patient_id`,
#'   numeric `value`, and logical `eligible`. At most one row per endpoint and
#'   patient. NA values or eligibility mark unavailable observations; NaN and
#'   infinite values are rejected. Extra columns are ignored.
#' @param design Data frame with character `contrast_id`, `patient_id`, and
#'   `group` (exactly `"A"` or `"B"`). Each patient occurs once per contrast;
#'   both groups must be nonempty. Patients can belong to multiple contrasts.
#' @param hypotheses Data frame with unique character `hypothesis_id` and
#'   character `endpoint_id`, `contrast_id`, `family_id`. Every declared row,
#'   including unavailable tests, remains in the result and family count.
#' @param missingness Only `"require_complete"` is supported. All expected
#'   patients must have finite eligible endpoint values. No patient is dropped.
#' @param max_allocations Positive integer ceiling on exhaustive allocations,
#'   at most one million. Exceeding it fails rather than using an approximation.
#'
#' @return A data frame with the registry, expected/evaluable group sizes,
#'   `mean_difference`, `p_value`, allocation count, probability grid step,
#'   and status. Grid step is a resolution bound, not a guaranteed attainable
#'   minimum two-sided p value. Unavailable effects and p values remain NA.
#' @examples
#' endpoints <- data.frame(endpoint_id = "e", patient_id = letters[1:4],
#'                         value = 1:4, eligible = TRUE)
#' design <- data.frame(contrast_id = "c", patient_id = letters[1:4],
#'                      group = c("A", "A", "B", "B"))
#' hypotheses <- data.frame(hypothesis_id = "h", endpoint_id = "e",
#'                          contrast_id = "c", family_id = "f")
#' ExactPatientTests(endpoints, design, hypotheses)
#' @export
ExactPatientTests <- function(endpoints, design, hypotheses,
                              missingness = "require_complete",
                              max_allocations = 1000000L) {
  .exact_assert(identical(missingness, "require_complete"),
                "Only require_complete missingness is supported")
  .exact_assert(is.numeric(max_allocations) && length(max_allocations) == 1L &&
                  is.finite(max_allocations) && max_allocations >= 1 &&
                  max_allocations <= 1000000 && max_allocations == floor(max_allocations),
                "max_allocations must be an integer between 1 and 1000000")
  .exact_table(endpoints, c("endpoint_id", "patient_id", "value", "eligible"), "endpoints")
  .exact_table(design, c("contrast_id", "patient_id", "group"), "design")
  registry <- c("hypothesis_id", "endpoint_id", "contrast_id", "family_id")
  .exact_table(hypotheses, registry, "hypotheses")
  .exact_assert(nrow(hypotheses) > 0L, "At least one hypothesis is required")
  .exact_assert(!anyDuplicated(.exact_keys(endpoints, c("endpoint_id", "patient_id"))),
                "Duplicate patient endpoint; explicit aggregation is required")
  .exact_assert(!anyDuplicated(.exact_keys(design, c("contrast_id", "patient_id"))),
                "Duplicate patient within contrast")
  .exact_keys(design, "group")
  .exact_keys(hypotheses, registry)
  .exact_assert(!anyDuplicated(hypotheses$hypothesis_id), "Duplicate hypothesis_id")
  .exact_assert(!anyDuplicated(.exact_keys(hypotheses, c("endpoint_id", "contrast_id"))),
                "Duplicate endpoint contrast hypothesis")
  .exact_assert(is.numeric(endpoints$value) && !any(is.nan(endpoints$value)) &&
                  all(is.na(endpoints$value) | is.finite(endpoints$value)),
                "Values must be numeric, finite or explicit NA")
  .exact_assert(is.logical(endpoints$eligible), "eligible must be logical")
  .exact_assert(all(design$group %in% c("A", "B")), "group must be A or B")
  .exact_assert(all(hypotheses$contrast_id %in% design$contrast_id), "Unknown contrast")
  .exact_assert(all(hypotheses$endpoint_id %in% endpoints$endpoint_id), "Unknown endpoint")
  .exact_assert(all(endpoints$patient_id %in% design$patient_id), "Unknown patient")
  contrasts <- split(design, design$contrast_id)
  for (d in contrasts) {
    na <- sum(d$group == "A")
    .exact_assert(na > 0L && na < nrow(d), "Both contrast groups must be nonempty")
    .exact_assert(choose(nrow(d), na) <= max_allocations, "Allocation limit exceeded")
  }
  rows <- lapply(seq_len(nrow(hypotheses)), function(i) {
    h <- hypotheses[i, registry, drop = FALSE]
    d <- contrasts[[h$contrast_id]]
    # Sorting fixes summation order independently of input table row order.
    d <- d[order(d$patient_id, method = "radix"), , drop = FALSE]
    e <- endpoints[endpoints$endpoint_id == h$endpoint_id, , drop = FALSE]
    m <- match(d$patient_id, e$patient_id)
    value <- e$value[m]
    ok <- !is.na(m) & is.finite(value) & !is.na(e$eligible[m]) & e$eligible[m]
    a <- d$group == "A"
    n <- nrow(d)
    na <- sum(a)
    count <- choose(n, na)
    effect <- p <- NA_real_
    if (all(ok)) {
      effect <- mean(value[a]) - mean(value[!a])
      allocation <- utils::combn(n, na)
      sums <- colSums(matrix(value[allocation], nrow = na))
      null <- sums / na - (sum(value) - sums) / (n - na)
      .exact_assert(is.finite(effect) && all(is.finite(null)), "Numerical overflow")
      p <- mean(abs(null) >= abs(effect) - 1e-12)
    }
    cbind(h, data.frame(n_a_expected = na, n_b_expected = n - na,
      n_a_evaluable = sum(ok & a), n_b_evaluable = sum(ok & !a),
      mean_difference = effect, p_value = p, allocations = count,
      probability_grid_step = 1 / count,
      status = if (all(ok)) "EXACT" else "UNAVAILABLE_INCOMPLETE",
      missingness_policy = missingness, inference_unit = "PATIENT"))
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Adjust Explicitly Declared Patient-Test Families
#'
#' Computes finite-only BH for historical comparison and declared-family BH/BY
#' using every registered hypothesis as the adjustment count. Unavailable p
#' values remain NA. Family IDs define the entire correction scope: include
#' setting and contrast in the ID only when separate families are intended.
#' A retrospective family registry is not prospective registration, and neither
#' adjustment establishes biological validity or study-wide error control.
#'
#' @param tests Data frame containing character `hypothesis_id`, `family_id`,
#'   and numeric `p_value`. All declared hypotheses must be present exactly once.
#' @param policy Explicit adjustment policy, `"declared"` or `"finite_only"`.
#' @param method Selected correction, `"BH"` or `"BY"`.
#' @return A list with `tests` (input columns plus all adjustment variants,
#'   selected `p_adjusted`, policy and method) and `families` (declared, testable
#'   and unavailable counts). Every NA is retained in the original row order.
#' @examples
#' x <- data.frame(hypothesis_id = c("h1", "h2"), family_id = "f",
#'                 p_value = c(0.03, NA))
#' AdjustPatientFamilies(x, policy = "declared")
#' @export
AdjustPatientFamilies <- function(tests, policy, method = c("BH", "BY")) {
  policy <- match.arg(policy, c("declared", "finite_only"))
  method <- match.arg(method)
  .exact_table(tests, c("hypothesis_id", "family_id", "p_value"), "tests")
  .exact_assert(nrow(tests) > 0L, "At least one declared hypothesis is required")
  .exact_keys(tests, c("hypothesis_id", "family_id"))
  .exact_assert(!anyDuplicated(tests$hypothesis_id), "Duplicate hypothesis_id")
  p <- tests$p_value
  .exact_assert(is.numeric(p) && !any(is.nan(p)) &&
                  all(is.na(p) | (is.finite(p) & p >= 0 & p <= 1)), "Invalid p value")
  added <- c("q_bh_finite", "q_by_finite", "q_bh_declared", "q_by_declared",
             "p_adjusted", "adjustment_policy", "adjustment_method")
  .exact_assert(!any(added %in% names(tests)), "Reserved adjustment output columns")
  out <- tests
  for (name in added[1:5]) out[[name]] <- NA_real_
  groups <- split(seq_len(nrow(tests)), tests$family_id)
  families <- lapply(groups, function(ii) {
    finite <- ii[is.finite(p[ii])]
    n <- length(ii)
    nf <- length(finite)
    out$q_bh_finite[finite] <<- stats::p.adjust(p[finite], "BH")
    out$q_by_finite[finite] <<- stats::p.adjust(p[finite], "BY")
    out$q_bh_declared[finite] <<- stats::p.adjust(p[finite], "BH", n = n)
    out$q_by_declared[finite] <<- stats::p.adjust(p[finite], "BY", n = n)
    data.frame(family_id = tests$family_id[ii[1L]], n_declared = n,
               n_testable = nf, n_unavailable = n - nf)
  })
  selected <- paste0("q_", tolower(method), if (policy == "declared") "_declared" else "_finite")
  out$p_adjusted <- out[[selected]]
  out$adjustment_policy <- policy
  out$adjustment_method <- method
  families <- do.call(rbind, families)
  rownames(families) <- NULL
  list(tests = out, families = families)
}
