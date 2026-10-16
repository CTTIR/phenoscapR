count_fraction_fixture <- function() {
  data.frame(sample = c("s", "s"), arm = c("A", "A"), id = c("a", "b"),
    positive = c(1, 2), total = c(3, 7))
}
count_fraction_call <- function(d, ...) {
  SummarizeGroupedCountFractions(d, c("sample", "arm"), "id", "positive", "total", ...)
}

test_that("exact count fractions differ from averaging rounded fractions", {
  d <- count_fraction_fixture()
  r <- count_fraction_call(d)
  expect_identical(r$fraction, 0.3)
  expect_identical(r$numerator_total, 3)
  expect_identical(r$denominator_total, 10)
  expect_identical(r$n_supplied, 2L)
  expect_identical(r$n_available, 2L)
  expect_identical(r$n_unavailable, 0L)
  expect_identical(r$status, "COMPLETE")
  expect_identical(r$missing_policy, "propagate")
  expect_false(identical(r$fraction, weighted.mean(c(.33, .29), d$total)))
  expect_identical(r, count_fraction_call(d[2:1, ]))
  d$positive <- c(0L, 0L)
  expect_identical(count_fraction_call(d)$fraction, 0)
  d$positive <- d$total
  expect_identical(count_fraction_call(d)$fraction, 1)
})

test_that("missing pairs propagate and zeros remain distinct", {
  d <- count_fraction_fixture()
  for (column in c("positive", "total")) {
    x <- d
    x[[column]][1] <- NA_real_
    r <- count_fraction_call(x)
    expect_identical(r$n_supplied, 2L)
    expect_identical(r$n_available, 1L)
    expect_identical(r$n_unavailable, 1L)
    expect_identical(r$status, "PARTIAL")
    expect_true(all(is.na(r[c("numerator_total", "denominator_total", "fraction")])))
    x[[column]][] <- NA_real_
    expect_identical(count_fraction_call(x)$status, "UNAVAILABLE")
  }
  d$positive <- c(NA_real_, 2)
  d$total <- c(3, NA_real_)
  expect_identical(count_fraction_call(d)$n_available, 0L)
  expect_identical(count_fraction_call(d)$status, "UNAVAILABLE")
  d$positive <- d$total <- c(0, 0)
  r <- count_fraction_call(d)
  expect_identical(r$status, "ZERO_DENOMINATOR")
  expect_identical(r$denominator_total, 0)
  expect_identical(r$numerator_total, 0)
  expect_identical(r$n_available, 2L)
  expect_identical(r$fraction, NA_real_)
})

test_that("exact range is checked before each sum in either order", {
  d <- count_fraction_fixture()
  maximum <- 2^53 - 1
  for (order in list(1:2, 2:1)) {
    d$positive <- d$total <- c(maximum - 1, 1)[order]
    r <- count_fraction_call(d)
    expect_identical(r$numerator_total, maximum)
    expect_identical(r$denominator_total, maximum)
    expect_identical(r$fraction, 1)
    d$positive <- c(0, 0)
    d$total <- c(maximum, 1)[order]
    expect_error(count_fraction_call(d), "Exact count total range")
    d$positive <- c(maximum, 1)[order]
    d$total <- c(NA_real_, NA_real_)
    expect_error(count_fraction_call(d), "Exact count total range")
  }
})

test_that("malformed count vectors and invalid subset counts fail", {
  d <- count_fraction_fixture()
  malformed <- list(c(-1, 0), c(.5, 1), c(Inf, 0), c(NaN, 0), c(2^53, 0),
    c(1 + 1i, 0i), c(TRUE, FALSE), c("1", "0"), factor(c(1, 2)),
    as.Date(c("2020-01-01", "2020-01-02")), as.difftime(c(1, 2), units = "secs"),
    structure(c(1, 2), class = "integer64"), I(c(1, 2)), matrix(c(1, 2), ncol = 1))
  for (column in c("positive", "total")) {
    for (value in malformed) {
      x <- d
      x[[column]] <- value
      expect_error(count_fraction_call(x), "Counts must be plain")
    }
  }
  d$positive <- c(4, NA_real_)
  expect_error(count_fraction_call(d), "Numerator exceeds denominator")
  d$positive <- c(1, 2)
  d$total <- c(0, 7)
  expect_error(count_fraction_call(d), "Numerator exceeds denominator")
})

test_that("compound groups and duplicate guards preserve observed keys", {
  d <- count_fraction_fixture()
  x <- d
  x$arm <- "B"
  x$positive <- c(0, 1)
  all <- rbind(x, d)
  r <- count_fraction_call(all)
  expect_identical(r$arm, c("A", "B"))
  expect_identical(r$fraction, c(.3, .1))
  expect_identical(r, count_fraction_call(all[c(4, 2, 3, 1), ]))
  expect_error(count_fraction_call(rbind(d, d[1, ])), "Duplicate observation")
  for (key in c("sample", "arm", "id")) {
    for (bad in c("", " ", NA_character_, "a\034b")) {
      x <- d
      x[[key]][1] <- bad
      expect_error(count_fraction_call(x), "Keys must")
    }
  }
  x <- d
  x$id <- factor(x$id)
  expect_error(count_fraction_call(x), "Keys must")
  expect_error(SummarizeGroupedCountFractions(d, character(), "id", "positive", "total"),
    "Invalid group")
  expect_error(SummarizeGroupedCountFractions(d, "sample", "id", NULL, "total"),
    "Invalid selected")
  expect_error(SummarizeGroupedCountFractions(d, "sample", "id", "total", "total"),
    "distinct")
  expect_error(SummarizeGroupedCountFractions(d, "status", "id", "positive", "total"),
    "distinct")
  expect_error(count_fraction_call(d[c("sample", "arm", "id", "positive")]), "requires columns")
  x <- d
  names(x)[5] <- "positive"
  expect_error(count_fraction_call(x), "requires columns")
  x <- cbind(d, d["positive"])
  names(x)[6] <- "positive"
  expect_error(count_fraction_call(x), "duplicate columns")
})

test_that("empty inputs are typed and absent groups belong to the paired registry", {
  d <- count_fraction_fixture()
  r <- count_fraction_call(d[0, ])
  expect_identical(nrow(r), 0L)
  expect_identical(vapply(r, typeof, character(1)), c(sample = "character", arm = "character",
    n_supplied = "integer", n_available = "integer", n_unavailable = "integer",
    numerator_total = "double", denominator_total = "double", fraction = "double",
    status = "character", missing_policy = "character"))
  observed <- count_fraction_call(d)
  paired <- AssemblePairedSummaries(observed, data.frame(sample = c("s", "absent")),
    "sample", "arm", "fraction", "n_supplied", "denominator_total",
    contrast = "first", min_count = 2)
  expect_identical(paired$value, c(.3, NA_real_))
  expect_identical(paired$status, c("COMPLETE", "MISSING_SIDE"))
  expect_identical(paired$first_weight_sum, c(10, NA_real_))
})
