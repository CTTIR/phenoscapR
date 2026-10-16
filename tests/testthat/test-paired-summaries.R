paired_fixture <- function() {
  data.frame(unit = c("x", "x", "y"), arm = c("A", "B", "A"),
             estimate = c(4, 1, 8), n = c(3, 2, 1), total = c(10, 4, 0))
}
paired_run <- function(data = paired_fixture(), registry = data.frame(unit = c("x", "y", "z")), ...) {
  AssemblePairedSummaries(data, registry, "unit", "arm", "estimate", "n",
                         weight_sum = "total", ...)
}

test_that("registered contrasts preserve values, counts and absent groups", {
  d <- paired_fixture()
  original <- d
  z <- paired_run(d)
  expect_identical(d, original)
  expect_identical(z$unit, c("x", "y", "z"))
  expect_equal(z$value, c(3, NA, NA))
  expect_identical(z$status, c("COMPLETE", "MISSING_SIDE", "MISSING_SIDE"))
  expect_identical(z$first_present, c(TRUE, TRUE, FALSE))
  expect_identical(z$second_present, c(TRUE, FALSE, FALSE))
  expect_equal(z$first_count, c(3, 1, 0))
  expect_equal(z$second_count, c(2, 0, 0))
  expect_equal(z$first_weight_sum, c(10, 0, NA))
  expect_equal(z$second_weight_sum, c(4, NA, NA))
  expect_equal(z$first_value, c(4, 8, NA))
  expect_equal(paired_run(contrast = "first")$value, c(4, 8, NA))
  expect_equal(paired_run(sides = c("B", "A"))$value, c(-3, NA, NA))
})

test_that("thresholds and unknown observations are distinct from absence", {
  d <- paired_fixture()
  expect_identical(paired_run(min_count = 2)$status[1], "COMPLETE")
  expect_identical(paired_run(min_count = 3)$status[1], "INSUFFICIENT_COUNT")
  expect_identical(paired_run(min_count = 1)$status[1], "COMPLETE")
  d$n[1] <- NA_real_
  d$estimate[1] <- NA_real_
  z <- paired_run(d)
  expect_true(z$first_present[1])
  expect_true(is.na(z$first_count[1]))
  expect_identical(z$status[1], "UNKNOWN_COUNT")
  d$n[1] <- 3
  expect_identical(paired_run(d)$status[1], "UNAVAILABLE_VALUE")
  d$n[1] <- 0
  expect_identical(paired_run(d)$status[1], "INSUFFICIENT_COUNT")
  d$n[2] <- NA_real_
  expect_identical(paired_run(d)$status[1], "UNKNOWN_COUNT")
  d$estimate[1] <- 4
  d$n[1] <- 3
  expect_identical(paired_run(d, contrast = "first")$status[1], "COMPLETE")
  d$estimate[] <- NA_real_
  expect_true(all(is.na(paired_run(d)$value)))
})

test_that("permutations preserve keyed values and explicit registry order", {
  a <- paired_run()
  b <- paired_run(paired_fixture()[3:1, ])
  expect_identical(a, b)
  c <- paired_run(registry = data.frame(unit = c("z", "x", "y")))
  expect_equal(c, a[c(3, 1, 2), ], ignore_attr = TRUE)
  d <- paired_fixture()
  d$arm <- ifelse(d$arm == "A", "left", "right")
  z <- paired_run(d, sides = c("left", "right"))
  expect_equal(z$value, a$value)
  expect_identical(unserialize(serialize(a, NULL)), a)
})

test_that("scalar estimators remain upstream and weights never reconstruct counts", {
  d <- data.frame(unit = rep("x", 4), arm = c("A", "A", "B", "B"),
    id = letters[1:4], observation = c(1, 5, 2, 2), weight = c(1, 3, 1, 1))
  s <- SummarizeGroupedValues(d, c("unit", "arm"), "id", "observation", "weight")
  r <- data.frame(unit = "x")
  a <- AssemblePairedSummaries(s, r, "unit", "arm", "mean", "n_available")
  b <- AssemblePairedSummaries(s, r, "unit", "arm", "weighted_mean",
                              "n_weighted_available", "weight_sum")
  expect_equal(a$value, 1)
  expect_equal(b$value, 2)
  expect_equal(b$first_count, 2)
  expect_equal(b$first_weight_sum, 4)
  expect_true(all(is.na(a$first_weight_sum)))
})

test_that("empty registries and wholly absent sides have typed outputs", {
  d <- paired_fixture()[FALSE, ]
  z <- paired_run(d)
  expect_identical(z$status, rep("MISSING_SIDE", 3))
  expect_equal(z$first_count, c(0, 0, 0))
  e <- paired_run(d, data.frame(unit = character()))
  expect_equal(nrow(e), 0L)
  expect_type(e$value, "double")
  expect_type(e$first_count, "double")
  expect_type(e$status, "character")
  expect_type(e$first_present, "logical")
})

test_that("ambiguous keys and malformed schemas fail", {
  d <- paired_fixture()
  expect_error(paired_run(rbind(d, d[1, ])), "Duplicate group and side")
  expect_error(paired_run(registry = data.frame(unit = c("x", "x"))), "Duplicate registry")
  expect_error(paired_run(registry = data.frame(unit = "x")), "Unknown data group")
  d$arm[1] <- "C"
  expect_error(paired_run(d), "Unknown data side")
  for (bad in c("", NA_character_, "a\034b")) {
    d <- paired_fixture(); d$unit[1] <- bad
    expect_error(paired_run(d), "Keys")
  }
  d <- paired_fixture(); d$unit <- factor(d$unit)
  expect_error(paired_run(d), "Keys")
  d <- paired_fixture(); names(d)[2] <- "unit"
  expect_error(paired_run(d), "requires columns|duplicate columns")
  expect_error(paired_run(sides = c("A", "A")), "Invalid side")
  expect_error(paired_run(sides = c("A", "B", "C")), "Invalid side")
  expect_error(paired_run(min_count = 0), "minimum")
  expect_error(paired_run(min_count = 1.5), "minimum")
  expect_error(paired_run(min_count = NA_real_), "minimum")
  expect_error(AssemblePairedSummaries(paired_fixture(), data.frame(unit = "x"),
    "unit", "arm", "estimate", "estimate"), "distinct")
})

test_that("nonfinite and malformed numbers are rejected without suppression", {
  for (column in c("estimate", "n", "total")) {
    for (bad in c(Inf, -Inf, NaN)) {
      d <- paired_fixture(); d[[column]][1] <- bad
      expect_error(paired_run(d), "finite|whole numbers")
    }
    d <- paired_fixture(); d[[column]] <- as.character(d[[column]])
    expect_error(paired_run(d), "numeric|whole numbers|numbers")
    d <- paired_fixture(); d[[column]] <- matrix(d[[column]], ncol = 1)
    expect_error(paired_run(d), "numeric|whole numbers|numbers")
  }
  d <- paired_fixture(); d$n[1] <- -1
  expect_error(paired_run(d), "whole numbers")
  d$n[1] <- 1.5
  expect_error(paired_run(d), "whole numbers")
  d <- paired_fixture(); d$total[1] <- -1
  expect_error(paired_run(d), "nonnegative")
  d <- paired_fixture(); d$estimate[1:2] <- c(.Machine$double.xmax, -.Machine$double.xmax)
  expect_error(paired_run(d), "Numerical range")
})


test_that("complex numbers cannot silently lose their imaginary component", {
  for (column in c("estimate", "n", "total")) {
    d <- paired_fixture(); d[[column]][1] <- 2 + 3i
    expect_error(paired_run(d), "numeric|whole numbers|numbers")
  }
  expect_error(paired_run(min_count = 2 + 3i), "minimum")
  expect_error(paired_run(min_count = matrix(2)), "minimum")
})

test_that("compound groups align independently and separator collisions fail", {
  d <- data.frame(unit = c("a", "a", "a", "a"), condition = c("one", "one", "two", "two"),
    arm = c("A", "B", "A", "B"), estimate = c(4, 1, 9, 3), n = rep(2, 4))
  registry <- data.frame(unit = c("a", "a"), condition = c("two", "one"))
  run <- function(d) AssemblePairedSummaries(d, registry, c("unit", "condition"),
                                           "arm", "estimate", "n")
  expect_equal(run(d)$value, c(6, 3))
  expect_identical(run(d), run(d[4:1, ]))
  d$condition[1] <- "one\034two"
  expect_error(run(d), "Keys")
})

test_that("status precedence does not depend on side order", {
  cases <- list(
    list(counts = c(NA, 0), values = c(1, 2), status = "UNKNOWN_COUNT"),
    list(counts = c(0, 2), values = c(1, NA), status = "INSUFFICIENT_COUNT"),
    list(counts = c(2, 2), values = c(1, NA), status = "UNAVAILABLE_VALUE"))
  for (case in cases) {
    d <- paired_fixture()[1:2, ]; d$n <- case$counts; d$estimate <- case$values
    for (sides in list(c("A", "B"), c("B", "A"))) {
      expect_identical(paired_run(d, sides = sides)$status[1], case$status)
      expect_true(is.na(paired_run(d, sides = sides)$value[1]))
    }
  }
  d <- paired_fixture()[1, ]; d$n <- NA_real_
  expect_identical(paired_run(d)$status[1], "MISSING_SIDE")
  expect_identical(paired_run(d, sides = c("B", "A"))$status[1], "MISSING_SIDE")
})


test_that("classed numeric storage cannot silently discard its semantics", {
  classed <- list(factor(c("low", "high", "low")), as.Date("2020-01-01") + 0:2,
    as.difftime(1:3, units = "days"), structure(as.double(1:3), class = "integer64"),
    I(as.double(1:3)))
  for (values in classed) {
    for (column in c("estimate", "n", "total")) {
      d <- paired_fixture(); d[[column]] <- values
      expect_error(paired_run(d), "numeric|whole numbers|numbers")
    }
    scalar <- structure(values[1], class = class(values))
    expect_error(paired_run(min_count = scalar), "minimum")
  }
})
