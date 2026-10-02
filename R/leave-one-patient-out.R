#' Exact Patient Omission Diagnostics for Declared Hypotheses
#'
#' Computes full tests once through `ExactPatientTests`, then evaluates explicitly
#' declared patient omissions through the same API. An incomplete full hypothesis
#' cannot become testable by omitting a missing or ineligible patient. No clinical
#' groups, independence, omission set or multiplicity policy is inferred.
#'
#' @param endpoints,design,hypotheses Inputs with the `ExactPatientTests` schemas.
#'   Selected columns must be dimensionless vectors. Extra columns are ignored.
#' @param omissions Data frame with character `hypothesis_id` and `patient_id`.
#'   Each pair must be unique; the patient must belong to that hypothesis's
#'   contrast design. Zero rows are allowed with typed character columns.
#' @param missingness Only `"require_complete"` is supported.
#' @param max_allocations Allocation ceiling passed unchanged to full and reduced
#'   exact tests. No random approximation or changed numerical rule is used.
#' @return List with `full_tests` (the complete exact-test result) and `omissions`
#'   (one row per supplied omission in its original order). Omission rows retain
#'   hypothesis keys and full results, reduced expected/supplied/evaluable counts,
#'   the omitted arm, an explicit `empty_arm` flag, reduced results and effect
#'   direction diagnostics. `reduced_status` is UNAVAILABLE_FULL_INCOMPLETE,
#'   UNAVAILABLE_EMPTY_ARM or EXACT, in that priority order. Reduced allocations,
#'   grid step, effect and p value are NA when no reduced test is performed.
#'   Supplied counts include present endpoint rows regardless of eligibility;
#'   evaluable counts require a finite value and nonmissing TRUE eligibility.
#'   Full-incomplete omissions do not execute reduced tests. Zero effects have
#'   direction ZERO; direction preservation is NA when either effect is missing.
#'   Arithmetic overflow in an effect change fails rather than returning Inf.
#' @export
LeaveOnePatientOut <- function(endpoints, design, hypotheses, omissions,
                              missingness = "require_complete",
                              max_allocations = 1000000L) {
  assert <- function(ok, message) {
    if (!isTRUE(ok)) stop(message, call. = FALSE)
  }
  tables <- list(endpoints = endpoints, design = design,
                 hypotheses = hypotheses, omissions = omissions)
  selected <- list(
    endpoints = c("endpoint_id", "patient_id", "value", "eligible"),
    design = c("contrast_id", "patient_id", "group"),
    hypotheses = c("hypothesis_id", "endpoint_id", "contrast_id", "family_id"),
    omissions = c("hypothesis_id", "patient_id")
  )
  for (name in names(tables)) {
    x <- tables[[name]]
    assert(is.data.frame(x) && !anyDuplicated(names(x)) &&
             all(selected[[name]] %in% names(x)),
           paste("Invalid", name, "schema"))
    for (column in selected[[name]]) {
      assert(is.null(dim(x[[column]])) && length(x[[column]]) == nrow(x),
             paste("Selected columns must be dimensionless vectors:", column))
    }
    tables[[name]] <- as.data.frame(x)[selected[[name]]]
  }
  endpoints <- tables$endpoints
  design <- tables$design
  hypotheses <- tables$hypotheses
  omissions <- tables$omissions
  for (column in selected$omissions) {
    x <- omissions[[column]]
    assert(is.character(x) && !anyNA(x) && all(nzchar(trimws(x))) &&
             !any(grepl("\034", x, fixed = TRUE)), "Invalid omission keys")
  }
  assert(!anyDuplicated(omissions), "Duplicate hypothesis patient omission")
  assert(all(omissions$hypothesis_id %in% hypotheses$hypothesis_id),
         "Unknown omission hypothesis")
  # The existing API owns endpoint/design/hypothesis and allocation validation.
  full <- ExactPatientTests(endpoints, design, hypotheses,
                            missingness = missingness,
                            max_allocations = max_allocations)
  for (i in seq_len(nrow(omissions))) {
    h <- hypotheses[match(omissions$hypothesis_id[i],
                          hypotheses$hypothesis_id), , drop = FALSE]
    allowed <- design$patient_id[design$contrast_id == h$contrast_id]
    assert(omissions$patient_id[i] %in% allowed,
           "Omitted patient is outside the hypothesis contrast")
  }
  empty <- data.frame(
    hypothesis_id = character(), endpoint_id = character(),
    contrast_id = character(), family_id = character(),
    omitted_patient = character(), omitted_arm = character(),
    full_status = character(), full_mean_difference = double(),
    full_p_value = double(), full_allocations = double(),
    full_probability_grid_step = double(),
    n_a_expected = integer(), n_b_expected = integer(),
    n_a_supplied = integer(), n_b_supplied = integer(),
    n_a_evaluable = integer(), n_b_evaluable = integer(),
    empty_arm = logical(), reduced_status = character(),
    mean_difference = double(), p_value = double(), allocations = double(),
    probability_grid_step = double(), absolute_effect_change = double(),
    full_effect_direction = character(), reduced_effect_direction = character(),
    effect_direction_preserved = logical(), missingness_policy = character(),
    inference_unit = character(), stringsAsFactors = FALSE
  )
  direction <- function(value) {
    if (is.na(value)) return(NA_character_)
    if (value > 0) return("POSITIVE")
    if (value < 0) return("NEGATIVE")
    "ZERO"
  }
  results <- vector("list", nrow(omissions))
  for (i in seq_len(nrow(omissions))) {
    omission <- omissions[i, , drop = FALSE]
    h <- hypotheses[match(omission$hypothesis_id,
                          hypotheses$hypothesis_id), , drop = FALSE]
    f <- full[match(h$hypothesis_id, full$hypothesis_id), , drop = FALSE]
    d <- design[design$contrast_id == h$contrast_id, , drop = FALSE]
    arm <- d$group[match(omission$patient_id, d$patient_id)]
    d <- d[d$patient_id != omission$patient_id, , drop = FALSE]
    e <- endpoints[endpoints$endpoint_id == h$endpoint_id &
                     endpoints$patient_id %in% d$patient_id, , drop = FALSE]
    match_index <- match(d$patient_id, e$patient_id)
    supplied <- !is.na(match_index)
    evaluable <- supplied & is.finite(e$value[match_index]) &
      !is.na(e$eligible[match_index]) & e$eligible[match_index]
    a <- d$group == "A"
    n_a <- sum(a)
    n_b <- sum(!a)
    empty_arm <- n_a == 0L || n_b == 0L
    status <- if (f$status != "EXACT") {
      "UNAVAILABLE_FULL_INCOMPLETE"
    } else if (empty_arm) {
      "UNAVAILABLE_EMPTY_ARM"
    } else {
      "EXACT"
    }
    effect <- p <- allocations <- grid <- NA_real_
    if (status == "EXACT") {
      reduced <- ExactPatientTests(e, d, h, missingness = missingness,
                                   max_allocations = max_allocations)
      assert(nrow(reduced) == 1L && reduced$status == "EXACT",
             "Complete reduced hypothesis unexpectedly unavailable")
      effect <- reduced$mean_difference
      p <- reduced$p_value
      allocations <- reduced$allocations
      grid <- reduced$probability_grid_step
    }
    change <- if (is.na(effect) || is.na(f$mean_difference)) {
      NA_real_
    } else {
      abs(effect - f$mean_difference)
    }
    assert(is.na(change) || is.finite(change), "Numerical overflow in effect change")
    results[[i]] <- data.frame(
      h, omitted_patient = omission$patient_id, omitted_arm = arm,
      full_status = f$status, full_mean_difference = f$mean_difference,
      full_p_value = f$p_value, full_allocations = f$allocations,
      full_probability_grid_step = f$probability_grid_step,
      n_a_expected = n_a, n_b_expected = n_b,
      n_a_supplied = sum(supplied & a), n_b_supplied = sum(supplied & !a),
      n_a_evaluable = sum(evaluable & a), n_b_evaluable = sum(evaluable & !a),
      empty_arm = empty_arm, reduced_status = status,
      mean_difference = effect, p_value = p, allocations = allocations,
      probability_grid_step = grid, absolute_effect_change = change,
      full_effect_direction = direction(f$mean_difference),
      reduced_effect_direction = direction(effect),
      effect_direction_preserved = if (is.na(effect) || is.na(f$mean_difference)) {
        NA
      } else {
        sign(effect) == sign(f$mean_difference)
      },
      missingness_policy = missingness, inference_unit = "PATIENT",
      stringsAsFactors = FALSE
    )
  }
  result <- if (length(results)) do.call(rbind, results) else empty
  rownames(result) <- NULL
  list(full_tests = full, omissions = result)
}
