test_that("grouped continuous summaries retain missingness and explicit weights", {
  d <- data.frame(sample = c("a", "a", "a", "b"), id = letters[1:4],
    signal = c(1, 3, NA, 9), weight = c(1, 3, 5, 0))
  z <- SummarizeGroupedValues(d, "sample", "id", "signal", "weight", threshold = 2)
  expect_identical(z$n_supplied, c(3L, 1L))
  expect_identical(z$n_available, c(2L, 1L))
  expect_identical(z$status, c("PARTIAL", "COMPLETE"))
  expect_equal(z$mean, c(NA, 9))
  expect_equal(z$median, c(NA, 9))
  expect_equal(z$fraction_at_least, c(NA, 1))
  expect_equal(z$weighted_mean, c(NA_real_, NA_real_))
  expect_identical(z$weighted_status, c("PARTIAL", "NO_POSITIVE_WEIGHT"))
  a <- SummarizeGroupedValues(d, "sample", "id", "signal", "weight",
    threshold = 2, missing = "available")
  expect_equal(a$mean, c(2, 9))
  expect_equal(a$median, c(2, 9))
  expect_equal(a$fraction_at_least, c(.5, 1))
  expect_equal(a$weighted_mean, c(2.5, NA))
  expect_equal(a$n_weighted_available, c(2L, 1L))
  expect_identical(a$missing_policy, c("available", "available"))
  b <- SummarizeGroupedValues(d, "sample", "id", "signal", min_available = 3)
  expect_true(all(is.na(b$mean)))
  expect_identical(b$status, rep("INSUFFICIENT", 2))
  expect_identical(b$weighted_status, rep("NOT_REQUESTED", 2))
  expect_identical(SummarizeGroupedValues(d[0, ], "sample", "id", "signal")$n_supplied,
    integer())
  d$signal[] <- NA_real_
  expect_identical(SummarizeGroupedValues(d, "sample", "id", "signal")$status,
    rep("UNAVAILABLE", 2))
})

test_that("grouped values reject duplicate observations and malformed contracts", {
  d <- data.frame(sample = c("a", "b"), id = c("same", "same"),
    signal = c(1, 3), weight = c(1, 3))
  expect_equal(nrow(SummarizeGroupedValues(d, "sample", "id", "signal")), 2)
  e <- d; e$sample[2] <- "a"
  expect_error(SummarizeGroupedValues(e, "sample", "id", "signal"), "Duplicate")
  e <- d; e$signal[1] <- Inf
  expect_error(SummarizeGroupedValues(e, "sample", "id", "signal"), "finite")
  e <- d; e$weight[1] <- -1
  expect_error(SummarizeGroupedValues(e, "sample", "id", "signal", "weight"), "nonnegative")
  expect_error(SummarizeGroupedValues(d, "sample", "id", "signal", min_available = 0),
    "minimum")
  expect_error(SummarizeGroupedValues(d, c("sample", "sample"), "id", "signal"),
    "unique")
  expect_error(SummarizeGroupedValues(d, "sample", "id", "signal", threshold = NA_real_),
    "threshold")
})


test_that("column names cannot shadow grouping internals or hide overflow", {
  d <- data.frame(groups = c("a", "a", "b"), id = letters[1:3],
    value = c(1, 3, 9), weight = c(1, 3, 0))
  z <- SummarizeGroupedValues(d, "groups", "id", "value", "weight")
  expect_equal(z$mean, c(2, 9))
  expect_equal(z$weighted_mean, c(2.5, NA))
  d$weight <- 1e308
  expect_error(SummarizeGroupedValues(d, "groups", "id", "value", "weight"),
    "Numerical range")
})


test_that("weighted denominator overflow and multi-key name capture fail safely", {
  d <- data.frame(groups = c("a", "a"), part = c("x", "y"),
    id = c("same", "same"), signal = c(1, 3))
  z <- SummarizeGroupedValues(d, c("groups", "part"), "id", "signal")
  expect_identical(z$part, c("x", "y"))
  expect_equal(z$mean, c(1, 3))
  d <- data.frame(sample = "a", id = c("x", "y"),
    signal = c(1e-308, 1e-308), weight = c(1e308, 1e308))
  expect_error(SummarizeGroupedValues(d, "sample", "id", "signal", "weight"),
    "Numerical range")
  d$weight <- 1e-308
  expect_error(SummarizeGroupedValues(d, "sample", "id", "signal", "weight"),
    "Numerical range")
})


test_that("weight totals expose the actual denominator without inventing availability", {
  d <- data.frame(sample = c("a", "a", "a", "b"), id = letters[1:4],
    signal = c(1, 3, NA, 9), weight = c(1, 3, 5, 0))
  z <- SummarizeGroupedValues(d, "sample", "id", "signal", "weight")
  expect_equal(z$weight_sum, c(NA, 0))
  z <- SummarizeGroupedValues(d, "sample", "id", "signal", "weight",
    missing = "available")
  expect_equal(z$weight_sum, c(4, 0))
  expect_equal(z$weighted_mean[1] * z$weight_sum[1], 10)
  d$signal[3] <- 7; d$weight[3] <- NA_real_
  z <- SummarizeGroupedValues(d, "sample", "id", "signal", "weight")
  expect_equal(z$mean[1], 11 / 3)
  expect_equal(z$weight_sum, c(NA, 0))
  z <- SummarizeGroupedValues(d, "sample", "id", "signal", "weight",
    missing = "available", min_available = 3)
  expect_identical(z$weight_sum, c(NA_real_, NA_real_))
  expect_identical(SummarizeGroupedValues(d[0, ], "sample", "id", "signal")$weight_sum,
    numeric())
})
