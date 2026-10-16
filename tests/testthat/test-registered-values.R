registered_fixture <- function() {
  list(data = data.frame(bin = c("a", "b"), feature = "x", score = c(0, NA_real_)),
    registry = data.frame(bin = c("c", "b", "a"), feature = "x", sample = "s"))
}
registered_call <- function(d, r, fill = 0) {
  CompleteRegisteredValues(d, r, c("bin", "feature"), "score", fill)
}

test_that("explicit fill distinguishes observed zero, missing and absent", {
  f <- registered_fixture()
  r <- registered_call(f$data, f$registry)
  expect_identical(r$score, c(0, NA_real_, 0))
  expect_identical(r$observed, c(FALSE, TRUE, TRUE))
  expect_identical(r$status, c("ABSENT_FILLED", "OBSERVED_MISSING", "OBSERVED"))
  expect_identical(r$absent_value, c(0, 0, 0))
  expect_identical(r[names(f$registry)], f$registry)
  r <- registered_call(f$data, f$registry, NA_real_)
  expect_identical(r$score, c(NA_real_, NA_real_, 0))
  expect_identical(r$status, c("ABSENT_UNAVAILABLE", "OBSERVED_MISSING", "OBSERVED"))
  expect_true(all(is.na(r$absent_value)))
  f$data$score <- c(a = 2L, b = NA_integer_)
  r <- registered_call(f$data, f$registry, -3L)
  expect_identical(r$score, c(-3, NA_real_, 2))
  expect_identical(r$absent_value, rep(-3, 3))
  expect_identical(registered_call(f$data[2:1, ], f$registry),
    registered_call(f$data, f$registry))
  expect_identical(registered_call(f$data, f$registry[3:1, ])$bin, c("a", "b", "c"))
})

test_that("authoritative metadata survives with classes and inputs unmodified", {
  f <- registered_fixture()
  f$registry$category <- factor(c("b", "a", "b"))
  f$registry$date <- as.Date(c("2020-01-01", NA, "2020-01-03"))
  f$registry$duration <- as.difftime(c(1, 2, 3), units = "secs")
  f$registry$details <- I(list(1:2, NULL, "entry"))
  f$data$sample <- "conflicting ignored metadata"
  before <- unserialize(serialize(f, NULL))
  r <- registered_call(f$data, f$registry)
  expect_identical(r[names(f$registry)], f$registry)
  expect_identical(f, before)
  d <- data.table::as.data.table(f$data)
  registry <- data.table::as.data.table(f$registry)
  before_d <- data.table::copy(d)
  before_r <- data.table::copy(registry)
  r <- registered_call(d, registry)
  expect_s3_class(r, "data.frame")
  expect_false(data.table::is.data.table(r))
  expect_identical(r[names(registry)], as.data.frame(before_r))
  expect_identical(d, before_d)
  expect_identical(registry, before_r)
  expect_error(registered_call(d, r), "Registry columns collide")
  expect_identical(d, before_d)
  expect_identical(registry, before_r)
})

test_that("empty observations and registries have typed and bounded results", {
  f <- registered_fixture()
  r <- registered_call(f$data[0, ], f$registry)
  expect_identical(r$score, rep(0, 3))
  expect_identical(r$observed, rep(FALSE, 3))
  expect_identical(r$status, rep("ABSENT_FILLED", 3))
  r <- registered_call(f$data[0, ], f$registry[0, ])
  expect_identical(nrow(r), 0L)
  expect_identical(vapply(r, typeof, character(1)), c(bin = "character", feature = "character",
    sample = "character", score = "double", observed = "logical", status = "character",
    absent_value = "double"))
  expect_error(registered_call(f$data, f$registry[0, ]), "Unknown data key")
})

test_that("keys, selectors, duplicates and unknown rows cannot change cardinality", {
  f <- registered_fixture()
  expect_error(registered_call(rbind(f$data, f$data[1, ]), f$registry), "Duplicate data key")
  expect_error(registered_call(f$data, rbind(f$registry, f$registry[1, ])), "Duplicate registry key")
  d <- f$data; d$feature[1] <- "unknown"
  expect_error(registered_call(d, f$registry), "Unknown data key")
  for (bad in c("", " ", NA_character_, "a\034b")) {
    d <- f$data; d$bin[1] <- bad
    expect_error(registered_call(d, f$registry), "Keys must")
    r <- f$registry; r$bin[1] <- bad
    expect_error(registered_call(f$data, r), "Keys must")
  }
  for (bad in list(factor(f$data$bin), structure(f$data$bin, class = "special"),
    matrix(f$data$bin, ncol = 1))) {
    d <- f$data; d$bin <- bad
    expect_error(registered_call(d, f$registry), "Keys must")
  }
  for (bad in list(character(), c("bin", "bin"), NA_character_, "", 1,
    matrix("bin"), structure("bin", class = "special"))) {
    expect_error(CompleteRegisteredValues(f$data, f$registry, bad, "score", 0), "Invalid key")
  }
  for (bad in list(character(), c("score", "score"), NA_character_, "", 1,
    matrix("score"), structure("score", class = "special"))) {
    expect_error(CompleteRegisteredValues(f$data, f$registry, "bin", bad, 0), "Invalid value")
  }
  expect_error(CompleteRegisteredValues(f$data, f$registry, "bin", "bin", 0), "collides")
  for (column in c("score", "observed", "status", "absent_value")) {
    r <- f$registry; r[[column]] <- 0
    expect_error(registered_call(f$data, r), "Registry columns collide")
  }
  expect_error(CompleteRegisteredValues(f$data, f$registry, "bin", "status", 0), "collides")
  d <- f$data; names(d)[3] <- "bin"
  expect_error(registered_call(d, f$registry), "requires columns")
  d <- cbind(f$data, duplicate = f$data$score); names(d)[4] <- "score"
  expect_error(registered_call(d, f$registry), "duplicate columns")
  r <- cbind(f$registry, duplicate = "x"); names(r)[4] <- "bin"
  expect_error(registered_call(f$data, r), "duplicate columns")
  expect_error(registered_call(f$data, f$registry["sample"]), "requires columns")
  expect_error(registered_call(list(), f$registry), "requires columns")
})

test_that("numeric observations and required fill reject ambiguous representations", {
  f <- registered_fixture()
  bad_values <- list(c(Inf, 0), c(NaN, 0), c(1 + 1i, 0i), c(TRUE, FALSE),
    c("1", "0"), factor(c(1, 2)), as.Date(c("2020-01-01", "2020-01-02")),
    as.difftime(c(1, 2), units = "secs"), structure(c(1, 2), class = "integer64"),
    I(c(1, 2)), matrix(c(1, 2), ncol = 1), list(1, 2))
  for (bad in bad_values) {
    d <- f$data; d$score <- bad
    expect_error(registered_call(d, f$registry), "Values must be plain")
  }
  for (bad in list(Inf, NaN, 1i, TRUE, NA, "0", factor("0"),
    as.Date("2020-01-01"), as.difftime(1, units = "secs"),
    structure(1, class = "integer64"), I(0), matrix(0), list(0), numeric(), c(0, 1))) {
    expect_error(registered_call(f$data, f$registry, bad), "Absent value must")
  }
  expect_error(CompleteRegisteredValues(f$data, f$registry, c("bin", "feature"), "score"),
    "missing")
})

test_that("fresh completion feeds summaries without treating observed NA as absence", {
  d <- data.frame(bin = c("a", "b", "c"), feature = "x", score = c(2, NA_real_, 4))
  registry <- data.frame(bin = c("a", "b", "c", "d"), feature = "x", sample = c("s", "s", "t", "t"))
  completed <- registered_call(d, registry)
  expect_identical(sort(completed$status), sort(c("OBSERVED", "OBSERVED_MISSING", "OBSERVED", "ABSENT_FILLED")))
  summary <- SummarizeGroupedValues(completed, c("sample", "feature"), "bin", "score",
    missing = "propagate")
  expect_identical(summary$n_supplied, c(2L, 2L))
  expect_identical(summary$n_available, c(1L, 2L))
  expect_identical(summary$mean, c(NA_real_, 2))
  expect_identical(summary$status, c("PARTIAL", "COMPLETE"))
  completed <- registered_call(d, registry, NA_real_)
  summary <- SummarizeGroupedValues(completed, c("sample", "feature"), "bin", "score")
  expect_true(all(is.na(summary$mean)))
  expect_identical(summary$n_available, c(1L, 1L))
  expect_identical(completed$observed, c(TRUE, TRUE, TRUE, FALSE))
})
