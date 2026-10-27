exhaustive_p <- function(v, a) {
  na <- sum(a)
  obs <- mean(v[a]) - mean(v[!a])
  null <- apply(utils::combn(length(v), na), 2, function(i) mean(v[i]) - mean(v[-i]))
  mean(abs(null) >= abs(obs) - 1e-12)
}

patients <- data.frame(
  patient = paste0("p", 1:7), arm = c("x", "x", "x", "y", "y", "z", "z"),
  e1 = c(1.5, 2, 3, 6, 7.25, NA, 4), e2 = c(5, 4, 6, 1, 2, 3, 3.5),
  e3 = c(NA, NA, NA, 1, 2, 3, 4)
)
registry <- data.frame(
  family = c("f1", "f1", "f2", "f2", "f1"),
  endpoint = c("e1", "e2", "e1", "e2", "e3"),
  contrast = c("x vs y", "x vs y", "xy vs z", "xy vs z", "x vs y")
)
contrasts <- list("x vs y" = list(A = "x", B = "y"),
                  "xy vs z" = list(A = c("x", "y"), B = "z"))

test_that("complete-case contrasts equal direct exhaustive tests", {
  out <- ContrastPatientEndpoints(patients, registry, contrasts, "patient", "arm")
  expect_identical(out$hypothesis_id, paste0("h", 1:5))
  expect_identical(out$family_id, paste(registry$family, registry$contrast, sep = " :: "))
  # e1, x vs y: all finite
  v <- patients$e1[1:5]
  a <- patients$arm[1:5] == "x"
  expect_equal(out$p_value[1], exhaustive_p(v, a), tolerance = 0)
  expect_equal(out$mean_difference[1], mean(v[a]) - mean(v[!a]))
  # e1, xy vs z: p6 missing, dropped
  keep <- c(1:5, 7)
  v <- patients$e1[keep]
  a <- patients$arm[keep] %in% c("x", "y")
  expect_equal(out$p_value[3], exhaustive_p(v, a), tolerance = 0)
  expect_identical(out$n_b_evaluable[3], 1L)
  expect_identical(out$n_b_expected[3], 2L)
  # e3, x vs y: arm x has no finite value
  expect_identical(out$status[5], "UNAVAILABLE_EMPTY_ARM")
  expect_true(is.na(out$p_value[5]))
})

test_that("require_complete leaves incomplete hypotheses unavailable", {
  out <- ContrastPatientEndpoints(patients, registry, contrasts, "patient", "arm",
                                  missingness = "require_complete")
  expect_identical(out$status[3], "UNAVAILABLE_INCOMPLETE")
  expect_true(is.na(out$p_value[3]))
  cc <- ContrastPatientEndpoints(patients, registry, contrasts, "patient", "arm")
  expect_identical(out$p_value[c(1, 2, 4)], cc$p_value[c(1, 2, 4)])
  adjusted <- AdjustPatientFamilies(out, policy = "declared")
  expect_identical(nrow(adjusted$tests), 5L)
  expect_identical(adjusted$families$n_declared, c(3L, 2L))
})

test_that("invalid declarations fail", {
  expect_error(ContrastPatientEndpoints(patients, registry,
    list("x vs y" = list(A = "x", B = "x"), "xy vs z" = contrasts[[2]]), "patient", "arm"),
    "disjoint")
  bad <- registry
  bad$endpoint[1] <- "missing"
  expect_error(ContrastPatientEndpoints(patients, bad, contrasts, "patient", "arm"),
               "Unknown endpoint")
  bad <- registry
  bad$contrast[1] <- "other"
  expect_error(ContrastPatientEndpoints(patients, bad, contrasts, "patient", "arm"),
               "Unknown contrast")
})
