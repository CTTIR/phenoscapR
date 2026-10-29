# Reference: full enumeration of all 2^n sign vectors over midranks.
enumerated_p <- function(d) {
  d <- d[is.finite(d) & d != 0]
  n <- length(d)
  r <- rank(abs(d))
  signs <- as.matrix(expand.grid(rep(list(c(-1, 1)), n)))
  mean(abs(drop(signs %*% r)) >= abs(sum(sign(d) * r)) - 1e-9)
}

test_that("signed-rank p equals full enumeration, including ties and zeros", {
  set.seed(11)
  for (k in 1:200) {
    n <- sample(1:13, 1)
    d <- round(stats::rnorm(n), sample(0:1, 1))
    if (!any(d != 0)) next
    got <- ExactPairedTests(data.frame(v = d), "v")$p_value
    expect_identical(got, enumerated_p(d))
  }
})

test_that("small exact reference cases", {
  x <- ExactPairedTests(data.frame(v = rep(-1, 12)), "v")
  expect_identical(x$p_value, 2 / 4096)
  expect_identical(x$sign_p_value, stats::binom.test(0, 12)$p.value)
  expect_equal(x$sign_p_value, 2 / 4096)
  expect_identical(ExactPairedTests(data.frame(v = c(-1, 0, 1)), "v")$p_value, 1)
  # n = 3 distinct: ranks 1, 2, 3 all positive -> |T| = 6 attained by 2 of 8 vectors.
  expect_identical(ExactPairedTests(data.frame(v = c(1, 2, 3)), "v")$p_value, 0.25)
  # Ties: |d| = (1, 1, 2) midranks (1.5, 1.5, 3); observed T = 1.5 + 1.5 - 3 = 0.
  expect_identical(ExactPairedTests(data.frame(v = c(1, 1, -2)), "v")$p_value, 1)
  none <- ExactPairedTests(data.frame(v = c(0, 0, NA)), "v")
  expect_true(is.na(none$p_value))
  expect_identical(none$status, "UNAVAILABLE_NO_NONZERO_DIFFERENCE")
  expect_identical(none$n_available, 2L)
})

test_that("sign test, summaries and direction interval follow their definitions", {
  d <- c(-3, -1, -2, -5, 1, -4, 0, NA)
  x <- ExactPairedTests(data.frame(v = d), "v", expected = "less", conf_level = 0.9)
  ok <- d[is.finite(d)]
  nz <- ok[ok != 0]
  expect_identical(x$n_available, 7L)
  expect_identical(x$n_nonzero, 6L)
  expect_identical(x$positive, 1L)
  expect_identical(x$median_difference, stats::median(nz))
  expect_identical(x$sign_p_value, stats::binom.test(1, 6)$p.value)
  expect_identical(x$expected_direction, 5L)
  ci <- stats::binom.test(5, 7, conf.level = 0.9)$conf.int
  expect_identical(c(x$direction_ci_low, x$direction_ci_high), as.numeric(ci))
})

test_that("groups, families, expected column and leave-one-out", {
  d <- data.frame(set = rep(c("s1", "s2"), each = 5), unit = rep(letters[1:5], 2),
                  value = c(-2, -1, -3, 4, -5, 1, 2, 3, -1, 5),
                  dir = rep(c("less", "greater"), each = 5))
  full <- ExactPairedTests(d, "value", groups = "set", id = "unit", expected = "dir",
                           family = "set")
  expect_identical(full$set, c("s1", "s2"))
  expect_identical(full$expected, c("less", "greater"))
  expect_identical(full$expected_direction, c(4L, 4L))
  expect_identical(full$hypothesis_id, c("s1", "s2"))
  expect_identical(full$family_id, c("s1", "s2"))
  loo <- ExactPairedTests(d, "value", groups = "set", id = "unit", omit = "each")
  expect_identical(nrow(loo), 10L)
  expect_identical(loo$omitted, d$unit)
  for (i in seq_len(nrow(loo))) {
    rest <- d$value[d$set == loo$set[i] & d$unit != loo$omitted[i]]
    expect_identical(loo$p_value[i], enumerated_p(rest))
  }
  expect_error(ExactPairedTests(d, "value", omit = "each"), "requires id")
  bad <- d
  bad$dir[1] <- "greater"
  expect_error(ExactPairedTests(bad, "value", groups = "set", expected = "dir"), "constant")
  expect_error(ExactPairedTests(d, "value", groups = "set", id = "set"), "unique")
})

test_that("paired differences from one or several tables", {
  t1 <- data.frame(unit = c("a", "b", "c"), x1 = c(5, 7, 9), x2 = c(6, 6, 10))
  t2 <- data.frame(unit = c("a", "b", "c"), y1 = c(1, 2, NA))
  one <- PairedDifferences(t1, "unit", list(list(name = "x1 - x2", x = "x1", y = "x2")))
  expect_identical(one$difference, c(-1, 1, -1))
  both <- PairedDifferences(list(first = t1, second = t2), "unit", list(
    list(name = "d1", table = "first", x = "x1", y = "x2", expected = "less"),
    list(name = "single", table = "second", x = "y1", tag = "z")))
  expect_identical(both$endpoint, rep(c("d1", "single"), each = 3))
  expect_identical(both$difference[4:6], c(1, 2, NA))
  expect_identical(both$expected, c(rep("less", 3), rep(NA, 3)))
  expect_identical(both$tag, c(rep(NA, 3), rep("z", 3)))
  expect_error(PairedDifferences(list(first = t1), "unit", list(list(name = "a", x = "x1"))),
               "Unknown table")
})

test_that("paired differences of zero-row tables keep their columns", {
  t0 <- data.frame(unit = character(), x1 = numeric(), x2 = numeric())
  for (p in list(list(name = "x1", x = "x1"), list(name = "d", x = "x1", y = "x2"))) {
    out <- PairedDifferences(t0, "unit", list(p))
    expect_identical(nrow(out), 0L)
    expect_identical(names(out), c("endpoint", "unit", "x", "y", "difference"))
    expect_type(out$y, "double")
  }
})

test_that("zero-row inputs give typed results without phantom groups", {
  e <- data.frame(id = character(), g = character(), d = numeric())
  expect_identical(.an_key(e, "g"), character())
  grouped <- ExactPairedTests(e, "d", groups = "g")
  expect_identical(nrow(grouped), 0L)
  expect_type(grouped$p_value, "double")
  expect_type(grouped$hypothesis_id, "character")
  overall <- ExactPairedTests(e, "d")
  expect_identical(overall$n_available, 0L)
  expect_identical(overall$status, "UNAVAILABLE_NO_NONZERO_DIFFERENCE")
  expect_identical(overall$hypothesis_id, "all")
  each <- ExactPairedTests(e, "d", groups = "g", id = "id", omit = "each")
  expect_identical(nrow(each), 0L)
  expect_true("omitted" %in% names(each))
})

test_that("paired differences refuse subject columns named like output columns", {
  for (id in c("x", "y", "difference")) {
    d <- data.frame(s = c("s1", "s2"), a = 1:2, b = 2:3)
    names(d)[1] <- id
    expect_error(PairedDifferences(d, id, list(list(name = "d", x = "a", y = "b"))), "output columns")
  }
  d <- data.frame(s = c("s1", "s2"), a = 1:2, b = 2:3)
  expect_error(PairedDifferences(d, "s", list(list(name = "d", x = "a", y = "b")), name = "y"), "output columns")
  expect_identical(names(PairedDifferences(d, "s", list(list(name = "d", x = "a", y = "b")))),
                   c("endpoint", "s", "x", "y", "difference"))
})
