test_that("bootstrap interval from supplied indices is exact", {
  d <- data.frame(v = c(4, 1, 3, 2))
  idx <- rbind(c(0, 0, 0, 0), c(1, 1, 1, 1), c(2, 3, 2, 3), c(0, 1, 2, 3), c(3, 3, 2, 2))
  out <- BootstrapMedianInterval(d, "v", n_boot = 5, conf_level = 0.5, indices = idx,
                                 index_base = 0)
  meds <- c(4, 1, 2.5, 2.5, 2.5)
  q <- stats::quantile(meds, c(0.25, 0.75), type = 7, names = FALSE)
  expect_identical(c(out$lower, out$upper), q)
  expect_identical(out$median, 2.5)
  expect_identical(out$draws, "SUPPLIED")
  expect_error(BootstrapMedianInterval(d, "v", n_boot = 5, indices = idx), "out of range")
})

test_that("seeded bootstrap is reproducible and restores the caller's stream", {
  d <- data.frame(g = rep(c("a", "b"), each = 7), v = c(1:7, (1:7)^2))
  set.seed(5)
  before <- .Random.seed
  a <- BootstrapMedianInterval(d, "v", "g", n_boot = 500, seed = 42)
  expect_identical(.Random.seed, before)
  b <- BootstrapMedianInterval(d, "v", "g", n_boot = 500, seed = 42)
  expect_identical(a, b)
  expect_identical(a$g, c("a", "b"))
  expect_true(all(a$lower <= a$median & a$median <= a$upper))
  # Reseeding per group: the same values give the same interval in each group.
  e <- data.frame(g = rep(c("a", "b"), each = 6), v = rep(c(3, 9, 1, 4, 7, 2), 2))
  r <- BootstrapMedianInterval(e, "v", "g", n_boot = 300, seed = 1)
  expect_identical(r$lower[1], r$lower[2])
})

all_perms <- function(n) {
  if (n == 1) return(matrix(1, 1, 1))
  p <- all_perms(n - 1)
  do.call(rbind, lapply(seq_len(n), function(i) {
    rest <- setdiff(seq_len(n), i)
    cbind(i, matrix(rest[p], nrow = nrow(p)))
  }))
}

test_that("exact permutation correlation equals brute-force enumeration", {
  x <- c(3, 1, 4, 1, 5, 9)
  y <- c(2, 7, 1, 8, 2, 8)
  out <- PermutationCorrelation(data.frame(x = x, y = y), "x", "y", permutations = "exact")
  rx <- rank(x)
  ry <- rank(y)
  rho <- stats::cor(rx, ry)
  perms <- all_perms(6)
  null <- apply(perms, 1, function(p) stats::cor(rx, ry[p]))
  expect_equal(out$estimate, rho)
  expect_equal(out$p_value, mean(abs(null) >= abs(rho) - 1e-12))
  expect_identical(out$n_perm, 720L)
  # Without ties the exact Spearman p agrees with stats::cor.test.
  z <- data.frame(x = 1:6, y = c(2, 1, 4, 3, 6, 5))
  expect_equal(PermutationCorrelation(z, "x", "y", permutations = "exact")$p_value,
               suppressWarnings(stats::cor.test(z$x, z$y, method = "spearman")$p.value))
})

test_that("Monte Carlo permutation p follows (b + 1) / (B + 1) and is seeded", {
  z <- data.frame(g = rep(c("a", "b"), each = 8), x = rep(1:8, 2),
                  y = c(1:8, c(8, 1, 7, 2, 6, 3, 5, 4)))
  a <- PermutationCorrelation(z, "x", "y", "g", n_perm = 999, seed = 3)
  b <- PermutationCorrelation(z, "x", "y", "g", n_perm = 999, seed = 3)
  expect_identical(a, b)
  expect_lt(a$p_value[1], 0.01)
  expect_true(all((a$p_value * 1000) %% 1 < 1e-9))
  small <- PermutationCorrelation(data.frame(x = 1:3, y = 3:1), "x", "y")
  expect_identical(small$status, "UNAVAILABLE")
  expect_error(PermutationCorrelation(data.frame(x = 1:12, y = 12:1), "x", "y",
                                      permutations = "exact"), "limited")
})

test_that("zero-row inputs give typed results without phantom groups", {
  e <- data.frame(g = character(), x = numeric(), y = numeric())
  b <- BootstrapMedianInterval(e, "x", groups = "g", n_boot = 10L)
  expect_identical(nrow(b), 0L)
  expect_type(b$median, "double")
  b1 <- BootstrapMedianInterval(e, "x", n_boot = 10L)
  expect_identical(b1$n, 0L)
  expect_true(is.na(b1$median))
  p <- PermutationCorrelation(e, "x", "y", groups = "g")
  expect_identical(nrow(p), 0L)
  expect_type(p$status, "character")
  p1 <- PermutationCorrelation(e, "x", "y")
  expect_identical(p1$status, "UNAVAILABLE")
})

test_that("min_n below two is refused instead of failing on a single pair", {
  d <- data.frame(g = c("a", "b", "b", "b"), x = c(1, 1, 2, 3), y = c(2, 3, 1, 2))
  expect_error(PermutationCorrelation(d, "x", "y", groups = "g", min_n = 1), "at least 2")
  expect_error(PermutationCorrelation(d, "x", "y", min_n = 2.5), "at least 2")
  r <- PermutationCorrelation(d, "x", "y", groups = "g", min_n = 2, permutations = "exact")
  expect_identical(r$status, c("UNAVAILABLE", "TESTED"))
})
