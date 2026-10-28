# Registered two-group contrasts of wide patient endpoint tables.

#' Exact Two-Group Contrasts for a Registry of Patient Endpoints
#'
#' Runs [ExactPatientTests()] for every row of a hypothesis registry
#' (endpoint, contrast, family) on a wide patient table (one row per patient,
#' one column per endpoint). Contrast arms are declared as sets of patient
#' groups. Two missingness policies are offered:
#'
#' * `"complete_case"`: each hypothesis uses only patients with a finite value;
#'   a hypothesis whose arm has no such patient is unavailable. This reproduces
#'   tables that silently drop missing patients.
#' * `"require_complete"`: every patient of both arms must have a finite value,
#'   otherwise the hypothesis is unavailable (no patient is dropped).
#'
#' Each hypothesis receives its own design, so a registry may repeat an
#' endpoint-contrast pair in different families. The effect is the mean of arm
#' A minus the mean of arm B.
#'
#' @param data Wide patient table with the `id`, `group` and endpoint columns.
#' @param registry Data frame with one row per hypothesis and the `endpoint`,
#'   `contrast` and `family` columns. Extra columns are ignored.
#' @param contrasts Named list: contrast name to a list with character vectors
#'   `A` and `B` of patient groups (disjoint).
#' @param id,group Patient identifier and patient group columns of `data`.
#' @param endpoint,contrast,family Column names in `registry`.
#' @param missingness `"complete_case"` or `"require_complete"`.
#' @param hypothesis_prefix Prefix of the generated `hypothesis_id` (followed
#'   by the registry row number).
#' @param max_allocations Passed to [ExactPatientTests()].
#' @return A data frame with the registry columns, `hypothesis_id`,
#'   `family_id` (`family :: contrast`), expected and evaluable arm sizes,
#'   `mean_difference`, `p_value`, `allocations`, `status` and `missingness`,
#'   in registry order. Pass it to [AdjustPatientFamilies()].
#' @examples
#' d <- data.frame(patient = paste0("p", 1:6), arm = rep(c("x", "y"), each = 3),
#'                 e1 = c(1, 2, 3, 6, 7, NA), e2 = c(5, 4, 6, 1, 2, 3))
#' reg <- data.frame(endpoint = c("e1", "e2"), contrast = "x vs y", family = "f")
#' ctr <- list("x vs y" = list(A = "x", B = "y"))
#' ContrastPatientEndpoints(d, reg, ctr, "patient", "arm")
#' ContrastPatientEndpoints(d, reg, ctr, "patient", "arm",
#'                          missingness = "require_complete")
#' @export
ContrastPatientEndpoints <- function(data, registry, contrasts, id, group,
                                     endpoint = "endpoint", contrast = "contrast",
                                     family = "family",
                                     missingness = c("complete_case", "require_complete"),
                                     hypothesis_prefix = "h", max_allocations = 1000000L) {
  missingness <- match.arg(missingness)
  .an_assert(all(vapply(list(id, group, endpoint, contrast, family, hypothesis_prefix),
                        .an_name, logical(1))), "Invalid column names or prefix")
  .an_require(data, c(id, group), "data")
  .an_require(registry, c(endpoint, contrast, family), "registry")
  .an_assert(nrow(registry) > 0L, "registry is empty")
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  registry <- as.data.frame(registry, stringsAsFactors = FALSE)
  patients <- as.character(data[[id]])
  groups <- as.character(data[[group]])
  .an_assert(!anyNA(patients) && !anyDuplicated(patients), "Patients must be unique")
  .an_assert(is.list(contrasts) && .an_names(names(contrasts), FALSE),
             "contrasts must be a named list")
  for (k in names(contrasts)) {
    arms <- contrasts[[k]]
    .an_assert(is.list(arms) && all(c("A", "B") %in% names(arms)) &&
                 !length(intersect(unlist(arms$A), unlist(arms$B))),
               paste("Contrast", k, "needs disjoint arms A and B"))
  }
  ends <- as.character(registry[[endpoint]])
  ctrs <- as.character(registry[[contrast]])
  .an_assert(all(ends %in% names(data)), paste("Unknown endpoint column(s):",
             paste(setdiff(ends, names(data)), collapse = ", ")))
  .an_assert(all(ctrs %in% names(contrasts)), "Unknown contrast in registry")
  hyp <- paste0(hypothesis_prefix, seq_len(nrow(registry)))
  .an_assert(!anyDuplicated(hyp), "Duplicate hypothesis identifiers")
  endpoints <- do.call(rbind, lapply(unique(ends), function(e) {
    v <- data[[e]]
    .an_assert(is.numeric(v) || all(is.na(v)), paste("Endpoint", e, "is not numeric"))
    v <- as.numeric(v)
    v[!is.finite(v)] <- NA_real_
    data.frame(endpoint_id = e, patient_id = patients, value = v, eligible = TRUE,
               stringsAsFactors = FALSE)
  }))
  design <- list()
  hypotheses <- list()
  empty <- rep(FALSE, nrow(registry))
  na_expected <- nb_expected <- integer(nrow(registry))
  for (i in seq_len(nrow(registry))) {
    arms <- contrasts[[ctrs[i]]]
    in_a <- groups %in% unlist(arms$A)
    in_b <- groups %in% unlist(arms$B)
    na_expected[i] <- sum(in_a)
    nb_expected[i] <- sum(in_b)
    keep <- in_a | in_b
    if (missingness == "complete_case") keep <- keep & is.finite(as.numeric(data[[ends[i]]]))
    if (!any(keep & in_a) || !any(keep & in_b)) {
      empty[i] <- TRUE
      next
    }
    design[[length(design) + 1L]] <- data.frame(contrast_id = hyp[i],
      patient_id = patients[keep], group = ifelse(in_a[keep], "A", "B"),
      stringsAsFactors = FALSE)
    hypotheses[[length(hypotheses) + 1L]] <- data.frame(hypothesis_id = hyp[i],
      endpoint_id = ends[i], contrast_id = hyp[i], family_id = "f",
      stringsAsFactors = FALSE)
  }
  base <- data.frame(hypothesis_id = hyp, n_a_expected = na_expected,
                     n_b_expected = nb_expected, n_a_evaluable = NA_integer_,
                     n_b_evaluable = NA_integer_, mean_difference = NA_real_,
                     p_value = NA_real_, allocations = NA_real_,
                     status = "UNAVAILABLE_EMPTY_ARM", stringsAsFactors = FALSE)
  if (length(design)) {
    design <- do.call(rbind, design)
    hypotheses <- do.call(rbind, hypotheses)
    tested <- ExactPatientTests(endpoints[endpoints$patient_id %in% design$patient_id, ],
                                design, hypotheses, max_allocations = max_allocations)
    m <- match(tested$hypothesis_id, base$hypothesis_id)
    for (k in c("n_a_evaluable", "n_b_evaluable", "mean_difference", "p_value",
                "allocations", "status")) {
      base[[k]][m] <- tested[[k]]
    }
  }
  out <- registry[c(endpoint, contrast, family)]
  out$hypothesis_id <- hyp
  out$family_id <- paste(registry[[family]], registry[[contrast]], sep = " :: ")
  out <- cbind(out, base[-1L])
  out$missingness <- missingness
  rownames(out) <- NULL
  out
}
