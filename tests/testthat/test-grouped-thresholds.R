threshold_fixture <- function() {
  list(data = data.frame(group = c("b", "a", "a"), setting = "s",
    id = c("x", "x", "y"), score = c(-2L, 1L, 2L), eligible = TRUE),
    refs = data.frame(group = c("a", "b", "unused"), setting = "s", cutoff = c(1L, -2L, 0L)))
}
threshold_call <- function(d, r) {
  ApplyGroupedThresholds(d, r, c("group", "setting"), "id", "score", "cutoff", "eligible")
}

test_that("strict comparisons preserve identity, order, ties and exact neighbors", {
  f <- threshold_fixture()
  r <- threshold_call(f$data, f$refs)
  expect_identical(r[names(f$data)], f$data)
  expect_identical(r$threshold_value, c(-2, 1, 1))
  expect_identical(r$above_threshold, c(FALSE, FALSE, TRUE))
  expect_identical(r$threshold_status, rep("COMPLETE", 3))
  expect_true(all(r$threshold_available & r$value_available))
  expect_identical(threshold_call(f$data, f$refs[3:1, ]), r)
  expect_identical(threshold_call(f$data[3:1, ], f$refs), r[3:1, ])
  f$data$score <- c(1 - .Machine$double.eps / 2, 1, 1 + .Machine$double.eps)
  f$refs$cutoff <- c(1, 1, 0)
  expect_identical(threshold_call(f$data, f$refs)$above_threshold, c(FALSE, FALSE, TRUE))
  f$data$setting[1] <- "second"
  f$refs$setting[2] <- "second"
  expect_identical(threshold_call(f$data, f$refs)$above_threshold, c(FALSE, FALSE, TRUE))
  names(f$refs)[3] <- "score"
  expect_identical(ApplyGroupedThresholds(f$data, f$refs, c("group", "setting"),
    "id", "score", "score", "eligible")$above_threshold, c(FALSE, FALSE, TRUE))
})

test_that("eligibility precedence never erases independent availability provenance", {
  d <- expand.grid(value_known = c(TRUE, FALSE), threshold_known = c(TRUE, FALSE),
    eligible = c(TRUE, FALSE, NA), KEEP.OUT.ATTRS = FALSE)
  d$group <- as.character(seq_len(nrow(d))); d$id <- "one"
  d$score <- ifelse(d$value_known, 2, NA_real_)
  refs <- data.frame(group = d$group, cutoff = ifelse(d$threshold_known, 1, NA_real_))
  r <- ApplyGroupedThresholds(d, refs, "group", "id", "score", "cutoff", "eligible")
  expect_identical(r$value_available, d$value_known)
  expect_identical(r$threshold_available, d$threshold_known)
  expect_identical(r$above_threshold, c(TRUE, rep(NA, 11)))
  expect_identical(r$threshold_status, c("COMPLETE", "MISSING_VALUE", "MISSING_THRESHOLD",
    "MISSING_VALUE_AND_THRESHOLD", rep("INELIGIBLE", 4), rep("UNKNOWN_ELIGIBILITY", 4)))
  expect_identical(r[names(d)], d)
})

test_that("observation metadata and numeric types survive without mutation", {
  f <- threshold_fixture()
  f$data$score <- c(first = -2L, second = 1L, third = 2L)
  f$data$category <- factor(c("b", "a", "b"))
  f$data$date <- as.Date(c("2020-01-01", NA, "2020-01-03"))
  f$data$duration <- as.difftime(c(1, 2, 3), units = "secs")
  f$data$details <- I(list(1:2, NULL, "entry"))
  original <- unserialize(serialize(f, NULL))
  expect_identical(threshold_call(f$data, f$refs)[names(f$data)], f$data)
  expect_identical(f, original)
  d <- data.table::as.data.table(f$data); refs <- data.table::as.data.table(f$refs)
  before_d <- data.table::copy(d); before_refs <- data.table::copy(refs)
  r <- threshold_call(d, refs)
  expect_false(data.table::is.data.table(r))
  expect_identical(r[names(d)], as.data.frame(before_d))
  expect_identical(d, before_d); expect_identical(refs, before_refs)
  expect_error(threshold_call(r, refs), "collide")
  expect_identical(d, before_d); expect_identical(refs, before_refs)
})

test_that("empty schemas stay typed and group coverage fails closed", {
  f <- threshold_fixture()
  r <- threshold_call(f$data[0, ], f$refs[0, ])
  expect_identical(r[names(f$data)], f$data[0, ])
  expect_identical(vapply(r[setdiff(names(r), names(f$data))], typeof, character(1)),
    c(threshold_value = "double", threshold_available = "logical", value_available = "logical",
      above_threshold = "logical", threshold_status = "character"))
  expect_identical(threshold_call(f$data[0, ], f$refs), r)
  expect_error(threshold_call(f$data, f$refs[0, ]), "Unknown observation group")
  f$data$eligible <- FALSE
  expect_error(threshold_call(f$data, f$refs[1, ]), "Unknown observation group")
  f$data$eligible <- NA
  expect_error(threshold_call(f$data, f$refs[1, ]), "Unknown observation group")
})

test_that("duplicate identities and invalid composite keys cannot multiply rows", {
  f <- threshold_fixture()
  expect_error(threshold_call(rbind(f$data, f$data[1, ]), f$refs), "Duplicate observation")
  expect_error(threshold_call(f$data, rbind(f$refs, f$refs[1, ])), "Duplicate threshold")
  for (bad in c("", " ", NA_character_, "a\034b")) {
    d <- f$data; d$id[1] <- bad
    expect_error(threshold_call(d, f$refs), "Keys must")
    refs <- f$refs; refs$group[1] <- bad
    expect_error(threshold_call(f$data, refs), "Keys must")
  }
  for (bad in list(factor(f$data$group), structure(f$data$group, class = "special"),
    matrix(f$data$group, ncol = 1))) {
    d <- f$data; d$group <- bad
    expect_error(threshold_call(d, f$refs), "Keys must")
    refs <- f$refs; refs$group <- bad
    expect_error(threshold_call(f$data, refs), "Keys must")
  }
  d <- f$data; d$group[1] <- "a\034s"; d$setting[1] <- "b"
  refs <- f$refs; refs$group[1] <- "a"; refs$setting[1] <- "s\034b"
  expect_error(threshold_call(d, refs), "Keys must")
})

test_that("selectors and table schemas are explicit and collision free", {
  f <- threshold_fixture()
  for (bad in list(character(), c("group", "group"), NA_character_, "", 1,
    matrix("group"), structure("group", class = "special"))) {
    expect_error(ApplyGroupedThresholds(f$data, f$refs, bad, "id", "score", "cutoff", "eligible"),
      "Invalid group")
  }
  for (position in 4:7) {
    for (bad in list(character(), c("a", "b"), NA_character_, "", 1,
      matrix("x"), structure("x", class = "special"))) {
      args <- list(f$data, f$refs, c("group", "setting"), "id", "score", "cutoff", "eligible")
      args[[position]] <- bad
      expect_error(do.call(ApplyGroupedThresholds, args), "Invalid scalar")
    }
  }
  expect_error(ApplyGroupedThresholds(f$data, f$refs, "group", "group", "score", "cutoff",
    "eligible"), "roles overlap")
  expect_error(ApplyGroupedThresholds(f$data, f$refs, "group", "id", "score", "group",
    "eligible"), "overlaps groups")
  for (column in c("threshold_value", "threshold_available", "value_available",
    "above_threshold", "threshold_status")) {
    d <- f$data; d[[column]] <- 0
    expect_error(threshold_call(d, f$refs), "collide")
  }
  d <- f$data; names(d)[2] <- "group"
  expect_error(threshold_call(d, f$refs), "requires columns")
  refs <- cbind(f$refs, other = 1); names(refs)[4] <- "group"
  expect_error(threshold_call(f$data, refs), "duplicate columns")
  d <- cbind(f$data, other = 1); names(d)[6] <- ""
  expect_error(threshold_call(d, f$refs), "nonblank")
  refs <- cbind(f$refs, other = 1); names(refs)[4] <- NA_character_
  expect_error(threshold_call(f$data, refs), "nonblank")
  expect_error(threshold_call(list(), f$refs), "requires columns")
  expect_error(threshold_call(f$data, f$refs["group"]), "requires columns")
})

test_that("invalid numbers and eligibility fail even for unused or ineligible rows", {
  f <- threshold_fixture()
  for (bad in list(c(Inf, 0, 0), c(NaN, 0, 0), c(1i, 0i, 0i), c(TRUE, FALSE, NA),
    c("1", "0", "0"), factor(1:3), as.Date(1:3, origin = "1970-01-01"),
    as.difftime(1:3, units = "secs"), structure(1:3, class = "integer64"),
    I(1:3), matrix(1:3, ncol = 1), list(1, 2, 3))) {
    d <- f$data; d$score <- bad; d$eligible <- FALSE
    expect_error(threshold_call(d, f$refs), "plain finite")
    refs <- f$refs; refs$cutoff <- bad
    expect_error(threshold_call(f$data, refs), "plain finite")
  }
  refs <- f$refs; refs$cutoff[3] <- Inf
  expect_error(threshold_call(f$data, refs), "plain finite")
  for (bad in list(1:3, c("TRUE", "FALSE", NA), factor(c(TRUE, FALSE, TRUE)),
    structure(c(TRUE, FALSE, NA), class = "special"), matrix(c(TRUE, FALSE, NA)),
    list(TRUE, FALSE, NA))) {
    d <- f$data; d$eligible <- bad
    expect_error(threshold_call(d, f$refs), "plain logical")
  }
})

test_that("fresh medians and explicit unavailable references drive strict calls", {
  d <- data.frame(group = c("a", "a", "a", "b"), id = c("z", "x", "y", "x"),
    score = c(1, 1, 3, NA_real_), eligible = c(TRUE, TRUE, TRUE, FALSE))
  summary <- SummarizeGroupedValues(d[d$eligible, ], "group", "id", "score")
  registry <- data.frame(group = c("b", "a"))
  refs <- CompleteRegisteredValues(summary, registry, "group", "median", NA_real_)
  expect_identical(refs$observed, c(FALSE, TRUE))
  r <- ApplyGroupedThresholds(d, refs, "group", "id", "score", "median", "eligible")
  expect_identical(r$above_threshold, c(FALSE, FALSE, TRUE, NA))
  expect_identical(r$threshold_status, c(rep("COMPLETE", 3), "INELIGIBLE"))
  expect_identical(r$threshold_available, c(TRUE, TRUE, TRUE, FALSE))
  expect_identical(r$id, d$id)
})
