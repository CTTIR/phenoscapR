#' Contrast Explicit Groups Within Finite-Metric Overlap Strata
#'
#' Compares positive and control observations only within strata containing both
#' labels with finite metric values. The caller supplies the policy-selected
#' population, independent group keys, stratum assignments and binary labels.
#' This function does not select a population, construct strata, establish
#' independence, or infer a causal estimand or scientific eligibility policy.
#'
#' @param data Data frame of policy-selected observations, including unavailable
#'   metric values. Rows are counted before filtering for finite metric values.
#' @param registry Data frame declaring every group, including empty groups.
#'   Extra registry columns are ignored.
#' @param groups Nonempty character vector of distinct group column names.
#' @param strata Nonempty character vector of distinct stratum column names.
#'   Strata are nested within the complete group key and are supplied explicitly.
#' @param id Character name of the observation ID column. IDs must be unique
#'   within a group, even when stratum assignments differ.
#' @param positive Character name of a dimensionless logical column without NA.
#'   TRUE denotes positive observations and FALSE denotes controls.
#' @param value Character name of a real numeric metric column. NA, NaN and
#'   infinite values count in policy totals but are not metric-evaluable.
#' @param quality Optional named list of explicit nonnegative finite criteria:
#'   `min_positive_policy`, `min_positive_evaluable`, `min_positive_overlap`,
#'   `min_policy_coverage`, `min_evaluable_coverage`, and `min_control_ess`.
#'   Count criteria must be integers; coverage criteria must lie between zero and one (inclusive).
#'   Each criterion is optional. NULL requests no quality assessment.
#'
#' @details
#' Group, stratum and observation keys must be nonblank, nonmissing character
#' vectors without dimensions. Factors and numeric IDs are not coerced. All
#' selected column roles must be distinct, and keys must not collide with
#' output column names. Unknown groups and duplicate registry or observation
#' keys are rejected. Row order does not define identity.
#'
#' Overlap is determined separately within each group and stratum after filtering
#' for finite metric values. In an overlap stratum, positives receive weight one
#' and controls receive the finite positive count divided by the finite control
#' count. Observations with unavailable values or outside overlap retain NA
#' weights and explicit statuses. They are not discarded from the returned
#' observation and stratum audit tables.
#'
#' The contrast is the overlap-positive mean minus the weighted overlap-control
#' mean. Both policy-positive and metric-evaluable-positive coverage denominators
#' are reported. Effective control count is the squared sum of control weights
#' divided by their sum of squares, computed after scaling weights to avoid
#' avoidable overflow. Means similarly scale values and weights. Unrepresentable
#' results or scaling/product underflow raise an error rather than silently
#' dropping a nonzero contribution. Exact cancellation to zero is valid. Ordinary
#' floating-point rounding still applies; this is not arbitrary-precision arithmetic.
#'
#' All optional quality criteria are assessed separately. A failed criterion never
#' suppresses an otherwise finite contrast. A PASS means only that the requested
#' criteria passed, not that the contrast is defined or scientifically eligible;
#' inspect `status` and the explicit denominators as well. Criteria using an
#' unavailable denominator fail. No count population or threshold is selected
#' implicitly. Policy, evaluable and overlap positive counts are distinct.
#'
#' @return List with `schema_version` ("1.0.0"), `summary`, `strata`,
#'   `observations`, and the canonical requested `quality` list. All tables are
#'   sorted by explicit keys; empty registries return typed empty tables.
#'   The summary contains policy/evaluable/overlap counts, stratum counts,
#'   both positive coverage fractions, positive/control evaluable fractions,
#'   `positive_mean`, `control_weighted_mean`, `contrast`, `control_weight_sum`
#'   and `control_effective_n`. A zero weight total denotes an empty matched
#'   control set; missing means and ESS remain NA, never zero-imputed.
#'   Summary status is EMPTY_GROUP, NO_EVALUABLE_VALUES, NO_OVERLAP or DEFINED;
#'   availability is UNAVAILABLE, PARTIAL or COMPLETE. Quality is NOT_REQUESTED,
#'   PASS or FAIL with semicolon-separated failed criterion names.
#'   The stratum table retains policy/evaluable counts and overlap status.
#'   The observation table retains keys, `is_positive`, `metric_value`,
#'   `metric_evaluable`, `overlap`, `weight`, and OVERLAP, NONFINITE_VALUE or
#'   NO_OVERLAP_STRATUM status. Extra input columns are not returned.
#' @examples
#' d <- data.frame(sample = "one", block = c("a", "a", "a", "b"),
#'   cell = letters[1:4], positive = c(TRUE, FALSE, FALSE, TRUE),
#'   score = c(4, 1, 3, NA))
#' registry <- data.frame(sample = c("one", "empty"))
#' result <- ContrastGroupedOverlap(d, registry, groups = "sample", strata = "block",
#'   id = "cell", positive = "positive", value = "score")
#' result$summary
#' @export
ContrastGroupedOverlap <- function(data, registry, groups, strata, id, positive,
                                   value, quality = NULL) {
  assert <- function(ok, message) {
    if (!isTRUE(ok)) stop(message, call. = FALSE)
  }
  names_ok <- function(x) {
    is.character(x) && is.null(dim(x)) && length(x) > 0L && !anyNA(x) &&
      all(nzchar(trimws(x))) && !anyDuplicated(x)
  }
  assert(names_ok(groups) && names_ok(strata), "groups and strata require distinct names")
  assert(all(vapply(list(id, positive, value), function(x) {
    names_ok(x) && length(x) == 1L
  }, logical(1))), "selected columns require scalar names")
  assert(names_ok(c(groups, strata, id, positive, value)),
         "selected column roles must be distinct")
  counts <- c("n_policy", "n_positive_policy", "n_control_policy", "n_evaluable",
    "n_positive_evaluable", "n_control_evaluable", "n_unavailable",
    "n_strata_policy", "n_strata_evaluable", "n_overlap_strata",
    "n_positive_overlap", "n_control_overlap")
  numbers <- c("positive_coverage_policy", "positive_coverage_evaluable",
    "positive_evaluable_fraction", "control_evaluable_fraction", "positive_mean",
    "control_weighted_mean", "contrast", "control_weight_sum", "control_effective_n")
  outputs <- c(counts, numbers, "status", "availability_status", "quality_status",
    "quality_reasons", "is_positive", "metric_value", "metric_evaluable",
    "overlap", "weight")
  assert(!any(c(groups, strata, id) %in% outputs), "keys collide with output columns")
  table <- function(x, columns, label) {
    assert(is.data.frame(x) && !anyDuplicated(names(x)) &&
             all(columns %in% names(x)), paste(label, "has invalid schema"))
    as.data.frame(x, stringsAsFactors = FALSE)
  }
  data <- table(data, c(groups, strata, id, positive, value), "data")
  registry <- table(registry, groups, "registry")
  valid_keys <- function(x, columns) {
    for (column in columns) {
      z <- x[[column]]
      assert(is.character(z) && is.null(dim(z)) && !anyNA(z) &&
               all(nzchar(trimws(z))), "keys must be nonmissing nonblank character vectors")
    }
  }
  valid_keys(data, c(groups, strata, id))
  valid_keys(registry, groups)
  key <- function(x, columns) {
    if (!nrow(x)) return(character())
    parts <- lapply(x[columns], function(z) {
      z <- enc2utf8(z)
      paste0(nchar(z, type = "bytes"), ":", z)
    })
    do.call(paste0, unname(parts))
  }
  sort_rows <- function(x, columns) {
    x <- x[do.call(order, c(unname(x[columns]), list(method = "radix"))), , drop = FALSE]
    rownames(x) <- NULL
    x
  }
  registry <- sort_rows(registry[groups], groups)
  group_keys <- key(registry, groups)
  assert(!anyDuplicated(group_keys), "duplicate registry group")
  assert(!anyDuplicated(key(data, c(groups, id))), "duplicate observation ID within group")
  group_index <- match(key(data, groups), group_keys)
  assert(!anyNA(group_index), "observation group absent from registry")
  pos <- data[[positive]]
  values <- data[[value]]
  assert(is.logical(pos) && is.null(dim(pos)) && !anyNA(pos),
         "positive membership must be logical without missing values")
  assert(is.numeric(values) && !is.complex(values) && is.null(dim(values)),
         "metric values must be a real numeric vector")
  finite <- is.finite(values)
  criteria <- c("min_positive_policy", "min_positive_evaluable", "min_positive_overlap",
    "min_policy_coverage", "min_evaluable_coverage", "min_control_ess")
  if (!is.null(quality)) {
    assert(is.list(quality) && length(quality) > 0L && names_ok(names(quality)) &&
             all(names(quality) %in% criteria), "quality must name supported explicit criteria")
    for (name in names(quality)) {
      z <- quality[[name]]
      assert(is.numeric(z) && !is.complex(z) && is.null(dim(z)) && length(z) == 1L &&
               is.finite(z) && z >= 0, "quality criteria must be finite nonnegative scalars")
      if (grepl("coverage", name)) assert(z <= 1, "coverage criterion must not exceed one")
      if (grepl("min_positive", name)) assert(z == floor(z), "count criteria must be integers")
    }
    quality <- quality[criteria[criteria %in% names(quality)]]
  }
  divide <- function(a, b) if (b > 0) a / b else NA_real_
  stable_mean <- function(x, weights) {
    assert(length(x) > 0L && all(is.finite(weights)) && all(weights > 0),
           "invalid matched weights")
    normalized <- weights / max(weights)
    assert(all(normalized > 0), "numerical range exceeded normalizing weights")
    scale <- max(abs(x))
    if (scale == 0) return(0)
    scaled <- x / scale
    assert(all(scaled != 0 | x == 0), "numerical range exceeded scaling metric values")
    products <- scaled * normalized
    assert(all(products != 0 | scaled == 0), "numerical range exceeded in weighted products")
    numerator <- sum(products)
    quotient <- numerator / sum(normalized)
    assert(quotient != 0 || numerator == 0, "numerical range exceeded dividing weighted sum")
    answer <- quotient * scale
    assert(is.finite(answer) && (answer != 0 || quotient == 0),
           "numerical range exceeded in metric mean")
    answer
  }
  strata_out <- sort_rows(unique(data[c(groups, strata)]), c(groups, strata))
  stratum_index <- match(key(data, c(groups, strata)), key(strata_out, c(groups, strata)))
  stratum_counts <- counts[1:7]
  for (name in stratum_counts) strata_out[[name]] <- rep(0, nrow(strata_out))
  strata_out$overlap <- rep(FALSE, nrow(strata_out))
  strata_out$status <- rep(NA_character_, nrow(strata_out))
  stratum_rows <- split(seq_len(nrow(data)), stratum_index)
  for (j in seq_len(nrow(strata_out))) {
    rows <- stratum_rows[[as.character(j)]]
    good <- rows[finite[rows]]
    np <- sum(pos[good])
    nc <- sum(!pos[good])
    strata_out[j, stratum_counts] <- list(length(rows), sum(pos[rows]), sum(!pos[rows]),
      length(good), np, nc, length(rows) - length(good))
    strata_out$overlap[j] <- np > 0 && nc > 0
    strata_out$status[j] <- if (!length(good)) {
      "NO_EVALUABLE_VALUES"
    } else if (np == 0) {
      "CONTROL_ONLY"
    } else if (nc == 0) {
      "POSITIVE_ONLY"
    } else {
      "OVERLAP"
    }
  }
  overlap <- finite & strata_out$overlap[stratum_index]
  weights <- rep(NA_real_, nrow(data))
  weights[overlap & pos] <- 1
  control <- which(overlap & !pos)
  weights[control] <- strata_out$n_positive_evaluable[stratum_index[control]] /
    strata_out$n_control_evaluable[stratum_index[control]]
  assert(all(is.finite(weights[overlap]) & weights[overlap] > 0),
         "numerical range exceeded in overlap weights")
  summary <- registry
  for (name in counts) summary[[name]] <- rep(0, nrow(registry))
  for (name in numbers) summary[[name]] <- rep(NA_real_, nrow(registry))
  for (name in c("status", "availability_status", "quality_status", "quality_reasons")) {
    summary[[name]] <- rep(NA_character_, nrow(registry))
  }
  group_rows <- split(seq_len(nrow(data)), group_index)
  for (g in seq_len(nrow(registry))) {
    rows <- group_rows[[as.character(g)]]
    if (is.null(rows)) rows <- integer()
    good <- rows[finite[rows]]
    matched <- rows[overlap[rows]]
    p <- matched[pos[matched]]
    controls <- matched[!pos[matched]]
    si <- unique(stratum_index[rows])
    summary[g, counts] <- list(length(rows), sum(pos[rows]), sum(!pos[rows]), length(good),
      sum(pos[good]), sum(!pos[good]), length(rows) - length(good), length(si),
      sum(strata_out$n_evaluable[si] > 0), sum(strata_out$overlap[si]), length(p), length(controls))
    summary$positive_coverage_policy[g] <- divide(length(p), sum(pos[rows]))
    summary$positive_coverage_evaluable[g] <- divide(length(p), sum(pos[good]))
    summary$positive_evaluable_fraction[g] <- divide(sum(pos[good]), sum(pos[rows]))
    summary$control_evaluable_fraction[g] <- divide(sum(!pos[good]), sum(!pos[rows]))
    summary$status[g] <- if (!length(rows)) {
      "EMPTY_GROUP"
    } else if (!length(good)) {
      "NO_EVALUABLE_VALUES"
    } else if (!length(matched)) {
      "NO_OVERLAP"
    } else {
      "DEFINED"
    }
    summary$availability_status[g] <- if (!length(good)) "UNAVAILABLE" else if (
      length(good) < length(rows)) "PARTIAL" else "COMPLETE"
    summary$control_weight_sum[g] <- 0
    if (length(matched)) {
      wp <- weights[controls]
      wn <- wp / max(wp)
      total <- sum(wp)
      ess <- sum(wn) * (sum(wn) / sum(wn * wn))
      assert(is.finite(total) && is.finite(ess) && all(wn > 0) && all(wn * wn > 0),
             "numerical range exceeded in control weight summaries")
      pm <- stable_mean(values[p], rep(1, length(p)))
      cm <- stable_mean(values[controls], wp)
      contrast <- pm - cm
      assert(is.finite(contrast), "numerical range exceeded in contrast")
      summary$positive_mean[g] <- pm
      summary$control_weighted_mean[g] <- cm
      summary$contrast[g] <- contrast
      summary$control_weight_sum[g] <- total
      summary$control_effective_n[g] <- ess
    }
    summary$quality_status[g] <- "NOT_REQUESTED"
    summary$quality_reasons[g] <- ""
    if (!is.null(quality)) {
      actual <- c(min_positive_policy = summary$n_positive_policy[g],
        min_positive_evaluable = summary$n_positive_evaluable[g],
        min_positive_overlap = summary$n_positive_overlap[g],
        min_policy_coverage = summary$positive_coverage_policy[g],
        min_evaluable_coverage = summary$positive_coverage_evaluable[g],
        min_control_ess = summary$control_effective_n[g])
      reasons <- names(quality)[vapply(names(quality), function(name) {
        !is.finite(actual[[name]]) || actual[[name]] < quality[[name]]
      }, logical(1))]
      summary$quality_status[g] <- if (length(reasons)) "FAIL" else "PASS"
      summary$quality_reasons[g] <- paste(reasons, collapse = ";")
    }
  }
  observations <- data[c(groups, strata, id)]
  observations$is_positive <- pos
  observations$metric_value <- values
  observations$metric_evaluable <- finite
  observations$overlap <- overlap
  observations$weight <- weights
  observations$status <- rep("NO_OVERLAP_STRATUM", nrow(data))
  observations$status[!finite] <- "NONFINITE_VALUE"
  observations$status[overlap] <- "OVERLAP"
  observations <- sort_rows(observations, c(groups, id))
  list(schema_version = "1.0.0", summary = summary, strata = strata_out,
       observations = observations, quality = quality)
}
