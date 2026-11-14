test_that("a mismatched zero-variance permutation null has undefined z and p", {
  dt <- data.table::data.table(sample_id = "s", x = c(0, 1, 100), y = 0,
                               phenotype = c("A", "A", "B"))
  out <- .interaction_permutation(dt, 2, 2L, 2L)
  expect_equal(out$observed, c(2, 0, 0, 0))
  expect_equal(out$expected, c(0, 1, 1, 0))
  expect_equal(out$interaction_score, c(0, -Inf, -Inf, 0))
  expect_identical(out$z_score, c(NA_real_, NA_real_, NA_real_, 0))
  expect_identical(out$p_value, c(NA_real_, NA_real_, NA_real_, 1))
})

test_that("deterministic matching positive-count nulls retain compatibility values", {
  dt <- data.table::data.table(sample_id = "s", x = c(0, 0, 0), y = 0,
                               phenotype = c("A", "A", "B"))
  out <- .interaction_permutation(dt, 1, 3L, 1L)
  expect_equal(out$observed, c(2, 2, 2, 0))
  expect_equal(out$expected, out$observed)
  expect_equal(out$z_score, rep(0, 4))
  expect_equal(out$p_value, rep(1, 4))
})

test_that("positive-variance interaction statistics agree with a direct null oracle", {
  dt <- data.table::data.table(sample_id = "s", x = c(0, 1, 100), y = 0,
                               phenotype = c("A", "A", "B"))
  set.seed(1)
  draws <- replicate(20, {
    pair <- sample(c("A", "A", "B"))[1:2]
    c(2 * all(pair == "A"), as.numeric(pair[1] != pair[2]),
      as.numeric(pair[1] != pair[2]), 2 * all(pair == "B"))
  })
  means <- rowMeans(draws)
  stdev <- sqrt(rowSums((draws - means)^2) / 19)
  z <- (c(2, 0, 0, 0)[1:3] - means[1:3]) / stdev[1:3]
  out <- .interaction_permutation(dt, 2, 20L, 1L)
  expect_true(all(stdev[1:3] > 0))
  expect_equal(out$expected, means)
  expect_equal(out$z_score[1:3], z)
  expect_equal(out$p_value[1:3], 2 * stats::pnorm(-abs(z)))
  expect_equal(out$z_score[4], 0)
  expect_equal(out$p_value[4], 1)
})
