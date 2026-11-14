test_that("complete graph Moran permutation inference is invariant to feature units", {
  x <- c(1.70490321801825928, -0.71203856493175199,
          -0.27798491379015372, -0.11964902211025652)
  coords <- data.frame(x = c(0, 1, 1, 0), y = c(0, 0, 1, 1))
  for (scale in c(1e-8, 1, 1e8)) {
    object <- CreateSpatialObject(matrix(x * scale, ncol = 1,
                                         dimnames = list(NULL, "v")), coords)
    result <- MoransI(object, "v", 10, n_perm = 99, seed = 1)
    expect_equal(result$I, -1 / 3)
    expect_equal(result$p_value, 1)
    expect_equal(result$z_score, 0)
    expect_equal(result$variance, 0)
  }
})

test_that("Moran tails retain theoretical centering and distinguish resolvable values", {
  # One positive and one negative tail exceed the observed deviation from E[I].
  # Two other values fall below it by much more than machine precision.
  expected <- -0.25
  observed <- expected + 0.1
  perm <- expected + c(0.1 - 1e-10, 0.1 + 1e-10, -0.2, 0.03)
  result <- .moran_permutation_summary(observed, perm, expected, 5)
  expect_equal(result$p_value, 3 / 5)
  expect_equal(result$z_score, (observed - mean(perm)) / stats::sd(perm))
  expect_equal(result$variance, stats::var(perm))
  # A genuine constant sampled null different from the observed statistic has
  # unavailable z but a valid Monte Carlo tail, including its +1 correction.
  result <- .moran_permutation_summary(0.5, rep(0, 9), -0.25, 5)
  expect_true(is.na(result$z_score))
  expect_equal(result$variance, 0)
  expect_equal(result$p_value, 1 / 10)
  result <- .moran_permutation_summary(0, rep(0, 9), -0.25, 5)
  expect_equal(result$z_score, 0)
  expect_equal(result$p_value, 1)
})

test_that("constant features and absent edges remain unavailable", {
  coords <- data.frame(x = c(0, 1, 1, 0), y = c(0, 0, 1, 1))
  for (x in list(rep(3, 4), 1:4)) {
    object <- CreateSpatialObject(matrix(x, ncol = 1,
                                         dimnames = list(NULL, "v")), coords)
    for (radius in if (length(unique(x)) == 1) c(0, 10) else 0) {
      result <- MoransI(object, "v", radius, n_perm = 9, seed = 1)
      expect_true(is.na(result$I))
      expect_true(is.na(result$p_value))
      expect_true(is.na(result$z_score))
    }
  }
})
