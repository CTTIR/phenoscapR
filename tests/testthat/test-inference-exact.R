exact_fixture <- function() {
  list(endpoints = data.frame(endpoint_id = "e", patient_id = letters[1:4],
    value = c(1, 2, 3, 4), eligible = TRUE),
    design = data.frame(contrast_id = "c", patient_id = letters[1:4],
      group = c("A", "A", "B", "B")),
    hypotheses = data.frame(hypothesis_id = "h", endpoint_id = "e",
      contrast_id = "c", family_id = "f"))
}

test_that("exact patient inference enumerates two-sided allocation null", {
  x <- exact_fixture()
  z <- do.call(ExactPatientTests, x)
  expect_equal(z$mean_difference, -2)
  expect_equal(z$p_value, 2 / 6)
  expect_equal(z$allocations, 6)
  expect_equal(z$probability_grid_step, 1 / 6)
  expect_identical(z$status, "EXACT")
  x$endpoints <- x$endpoints[4:1, ]
  x$design <- x$design[c(3, 1, 4, 2), ]
  expect_identical(do.call(ExactPatientTests, x), z)
  x$endpoints$value <- 1
  z <- do.call(ExactPatientTests, x)
  expect_equal(z$p_value, 1)
  expect_equal(z$mean_difference, 0)
  x$endpoints$value <- c(0, 0, 1, 1)
  expect_equal(do.call(ExactPatientTests, x)$p_value, 1 / 3)
  x$endpoints$value <- c(0, 1e-14, 0, 1e-14)
  expect_equal(do.call(ExactPatientTests, x)$p_value, 1)
})

test_that("complete patient support is mandatory without imputation", {
  x <- exact_fixture()
  for (kind in c("absent", "missing", "ineligible", "unknown")) {
    y <- x
    if (kind == "absent") y$endpoints <- y$endpoints[-1, ]
    if (kind == "missing") y$endpoints$value[1] <- NA_real_
    if (kind == "ineligible") y$endpoints$eligible[1] <- FALSE
    if (kind == "unknown") y$endpoints$eligible[1] <- NA
    z <- do.call(ExactPatientTests, y)
    expect_true(is.na(z$p_value))
    expect_true(is.na(z$mean_difference))
    expect_equal(z$n_a_expected, 2)
    expect_equal(z$n_a_evaluable, 1)
    expect_equal(z$allocations, 6)
    expect_identical(z$status, "UNAVAILABLE_INCOMPLETE")
  }
  expect_error(do.call(ExactPatientTests, c(x, list(missingness = "drop"))), "require_complete")
})

test_that("patient identities, registries and finite arithmetic fail closed", {
  x <- exact_fixture()
  y <- x; y$endpoints <- rbind(y$endpoints, y$endpoints[1, ])
  expect_error(do.call(ExactPatientTests, y), "Duplicate patient endpoint")
  y <- x; y$design <- rbind(y$design, y$design[1, ])
  expect_error(do.call(ExactPatientTests, y), "Duplicate patient within")
  y <- x; y$hypotheses <- rbind(y$hypotheses, y$hypotheses)
  expect_error(do.call(ExactPatientTests, y), "Duplicate hypothesis")
  y$hypotheses$hypothesis_id <- c("h", "h2")
  expect_error(do.call(ExactPatientTests, y), "Duplicate endpoint contrast")
  for (v in list(Inf, NaN, "x")) {
    y <- x; y$endpoints$value[1] <- v
    expect_error(do.call(ExactPatientTests, y), "Values must")
  }
  y <- x; y$endpoints$eligible <- 1
  expect_error(do.call(ExactPatientTests, y), "eligible must")
  y <- x; y$design$group <- "A"
  expect_error(do.call(ExactPatientTests, y), "Both contrast")
  y <- x; y$design$group[1] <- "C"
  expect_error(do.call(ExactPatientTests, y), "group must")
  y <- x; y$endpoints$patient_id[1] <- "alien"
  expect_error(do.call(ExactPatientTests, y), "Unknown patient")
  y <- x; y$hypotheses$contrast_id <- "alien"
  expect_error(do.call(ExactPatientTests, y), "Unknown contrast")
  y <- x; y$hypotheses$endpoint_id <- "alien"
  expect_error(do.call(ExactPatientTests, y), "Unknown endpoint")
  y <- x; y$endpoints$patient_id[1] <- "\034"
  expect_error(do.call(ExactPatientTests, y), "Keys must")
  y <- x; y$hypotheses <- y$hypotheses[FALSE, ]
  expect_error(do.call(ExactPatientTests, y), "At least one")
  y <- x; y$endpoints$value <- c(1e308, 1e308, -1e308, -1e308)
  expect_error(do.call(ExactPatientTests, y), "Numerical overflow")
  expect_error(do.call(ExactPatientTests, c(x, list(max_allocations = 5))), "Allocation limit")
  expect_error(do.call(ExactPatientTests, c(x, list(max_allocations = NA))), "max_allocations")
})

test_that("family adjustments preserve declared unavailable hypotheses", {
  x <- data.frame(hypothesis_id = letters[1:5], family_id = c("f", "f", "f", "g", "g"),
    p_value = c(.03, .1, NA, NA, NA))
  z <- AdjustPatientFamilies(x, "declared")
  expect_equal(z$tests$q_bh_finite[1:2], c(.06, .1))
  expect_equal(z$tests$q_bh_declared[1:2], c(.09, .15))
  expect_equal(z$tests$q_by_declared[1:2], p.adjust(c(.03, .1), "BY", n = 3))
  expect_identical(z$tests$p_adjusted, z$tests$q_bh_declared)
  expect_identical(is.na(z$tests$p_adjusted), is.na(x$p_value))
  expect_equal(z$families$n_declared, c(3L, 2L))
  expect_equal(z$families$n_testable, c(2L, 0L))
  b <- AdjustPatientFamilies(x, "finite_only", "BY")
  expect_identical(b$tests$p_adjusted, b$tests$q_by_finite)
  reversed <- AdjustPatientFamilies(x[5:1, ], "declared")
  expect_equal(reversed$tests$p_adjusted[5:1], z$tests$p_adjusted)
  y <- x; y$hypothesis_id[2] <- "a"
  expect_error(AdjustPatientFamilies(y, "declared"), "Duplicate")
  for (v in c(-1, 2, Inf, NaN)) {
    y <- x; y$p_value[1] <- v
    expect_error(AdjustPatientFamilies(y, "declared"), "Invalid p")
  }
  y <- x; y$p_adjusted <- 1
  expect_error(AdjustPatientFamilies(y, "declared"), "Reserved")
  expect_error(AdjustPatientFamilies(x), "argument.*missing")
  expect_error(AdjustPatientFamilies(x, "unknown"), "arg")
  expect_error(AdjustPatientFamilies(x[FALSE, ], "declared"), "At least one")
})
