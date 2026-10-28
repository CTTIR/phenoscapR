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

# Well-conditioned designs: values of order 0.01-1000, 4-12 patients per group,
# with and without ties. The p values below were recorded with the
# implementation before centring and the relative tie tolerance; they equal an
# exact integer enumeration of the same designs.
exact_designs <- function() {
  sizes <- list(c(4, 4), c(4, 7), c(5, 5), c(6, 6), c(4, 12), c(7, 9), c(8, 8), c(12, 8), c(10, 10))
  scales <- c(0.01, 0.1, 1, 10, 100)
  out <- list()
  for (s in seq_along(sizes)) for (tie in c(FALSE, TRUE)) for (k in seq_along(scales)) {
    set.seed(100 * s + 10 * tie + k)
    na <- sizes[[s]][1]
    nb <- sizes[[s]][2]
    base <- if (tie) sample(c(1, 2, 2.5, 4, 7, 9.5), na + nb, TRUE) else round(stats::runif(na + nb, 1, 10), 2)
    out[[length(out) + 1L]] <- list(value = base * scales[k], group = sample(rep(c("A", "B"), c(na, nb))))
  }
  out
}
exact_run <- function(value, group) {
  ids <- sprintf("p%02d", seq_along(value))
  ExactPatientTests(data.frame(endpoint_id = "e", patient_id = ids, value = value, eligible = TRUE),
                    data.frame(contrast_id = "c", patient_id = ids, group = group),
                    data.frame(hypothesis_id = "h", endpoint_id = "e", contrast_id = "c", family_id = "f"))
}

test_that("exact p values of well-conditioned designs are unchanged", {
  recorded <- c(58L, 50L, 18L, 44L, 36L, 8L, 6L, 22L, 52L, 46L, 70L, 76L, 120L, 96L, 287L, 292L, 15L, 40L,
    233L, 107L, 250L, 70L, 186L, 190L, 76L, 174L, 222L, 242L, 192L, 108L, 390L, 712L, 514L, 160L,
    788L, 636L, 374L, 672L, 844L, 100L, 881L, 244L, 214L, 1346L, 1493L, 453L, 983L, 1001L, 158L,
    338L, 1769L, 1500L, 4574L, 3065L, 4787L, 4673L, 1606L, 7380L, 3614L, 4470L, 178L, 4066L, 1692L,
    4918L, 3896L, 2070L, 3292L, 11904L, 2740L, 12870L, 108162L, 94934L, 88130L, 21370L, 3447L,
    27467L, 14487L, 81260L, 24345L, 125970L, 72644L, 31558L, 95118L, 177210L, 29774L, 15892L, 43066L,
    184756L, 145174L, 83818L)
  allocations <- rep(c(70, 330, 252, 924, 1820, 11440, 12870, 125970, 184756), each = 10)
  p <- vapply(exact_designs(), function(d) exact_run(d$value, d$group)$p_value, numeric(1))
  expect_identical(p, recorded / allocations)
})

test_that("exact p values do not depend on the location or scale of the values", {
  designs <- exact_designs()[c(3, 8, 14, 19, 27, 33, 44, 48, 52, 59)]
  for (d in designs) {
    p <- exact_run(d$value, d$group)$p_value
    for (v in list(d$value + 1e4, d$value + 1e6, d$value * 1e-12, d$value * 1e6, -d$value)) {
      expect_identical(exact_run(v, d$group)$p_value, p)
    }
  }
  # Large values with fractional differences keep their exact p value.
  v <- 1e10 + c(0.1, 0.25, 0.3, 0.45, 0.5, 0.65)
  expect_identical(exact_run(v, rep(c("A", "B"), each = 3))$p_value, 0.1)
  iv <- c(873, 111, 953, 569, 37)
  g <- c("B", "A", "A", "B", "A")
  for (shift in c(0, 1e3, 1e4, 1e5, 1e6)) expect_identical(exact_run(iv / 1000 + shift, g)$p_value, 0.4)
  expect_identical(exact_run(iv * 1e-15, g)$p_value, 0.4)
})
