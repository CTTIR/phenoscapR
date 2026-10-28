test_that("display limits use type-7 quantiles and a margin", {
  d <- data.frame(x = 1:101, y = seq(0, 200, 2), keep = c(rep(TRUE, 100), FALSE))
  l <- EmbeddingLimits(d, filter = list(keep = TRUE), probs = c(0.1, 0.9), pad = 0.5)
  qx <- stats::quantile(1:100, c(0.1, 0.9), names = FALSE)
  expect_equal(l$xmin, qx[1] - 0.5 * diff(qx))
  expect_equal(l$xmax, qx[2] + 0.5 * diff(qx))
  expect_identical(names(l), c("xmin", "xmax", "ymin", "ymax"))
})

test_that("embedding layers keep drawing order and shuffle reproducibly", {
  d <- data.frame(u = 1:20, v = 20:1, type = rep(c("a", "b"), 10), kept = c(rep(TRUE, 15), rep(FALSE, 5)),
                  grp = rep(c("g1", "g2"), each = 10))
  set.seed(99)
  before <- .Random.seed
  l <- EmbeddingLayers(d, "u", "v", carry = "grp", seed = 4, layers = list(
    list(filter = list(kept = TRUE), key = "background"),
    list(filter = list(type = "a"), key_from = "type", shuffle = TRUE, recode = list(a = "A"))))
  expect_identical(.Random.seed, before)
  expect_identical(l$layer, c(rep(1L, 15), rep(2L, 10)))
  expect_identical(l$key[16:25], rep("A", 10))
  expect_setequal(l$x[16:25], d$u[d$type == "a"])
  l2 <- EmbeddingLayers(d, "u", "v", seed = 4, layers = list(list(filter = list(kept = TRUE), key = "background"),
                                                               list(filter = list(type = "a"), key_from = "type", shuffle = TRUE)))
  expect_identical(l$x, l2$x)
  expect_identical(l$grp, d$grp[match(l$x, d$u)])
  expect_error(EmbeddingLayers(d, "u", "v", layers = list(list(key = "x", shuffle = TRUE))), "seed")
})

test_that("cluster labels sit at the median of large clusters", {
  d <- data.frame(x = c(1, 2, 3, 10, 11), y = c(1, 1, 5, 5, 6), cl = c(1, 1, 1, 2, 2), f = TRUE)
  l <- ClusterLabelPositions(d, cluster = "cl", filter = list(f = TRUE), min_points = 3)
  expect_identical(l$label, "1")
  expect_equal(c(l$x, l$y, l$n), c(2, 1, 3))
})

test_that("Gaussian smoothing matches a mirrored direct convolution and keeps the mass", {
  set.seed(5)
  m <- matrix(rpois(30 * 25, 3), 30, 25)
  s <- .figb_gaussian_smooth(m, sigma = 2, truncate = 4)
  r <- 8L
  k <- exp(-0.5 * (-r:r)^2 / 4)
  k <- k / sum(k)
  mirror <- function(i, n) ifelse(i < 1, 1 - i, ifelse(i > n, 2 * n + 1 - i, i))
  pad <- m[mirror(seq(1 - r, 30 + r), 30), mirror(seq(1 - r, 25 + r), 25)]
  direct <- matrix(0, 30, 25)
  for (i in seq_len(30)) for (j in seq_len(25)) {
    direct[i, j] <- sum(outer(k, k) * pad[i:(i + 2 * r), j:(j + 2 * r)])
  }
  expect_equal(s, direct, tolerance = 1e-12)
  expect_equal(sum(s), sum(m), tolerance = 1e-12)
})

test_that("density levels enclose the requested share of the smoothed mass", {
  set.seed(6)
  d <- data.frame(x = c(rnorm(500), rnorm(400, 3)), y = c(rnorm(500), rnorm(400, 2)),
                  g = rep(c("p1", "p2"), c(500, 400)), cl = rep(c("A", "B"), c(500, 400)))
  lim <- data.frame(xmin = -4, xmax = 7, ymin = -4, ymax = 6)
  cont <- DensityLevelContour(d, group = "g", limits = lim, bins = 40, carry = "cl", slot_within = "cl",
                              label_from = "g", label_sub = c("^p", "#"))
  expect_true(all(c("g", "slot", "label", "cl", "kind", "piece", "x", "y", "level", "n") %in% names(cont)))
  expect_setequal(unique(cont$kind), c("band", "line"))
  expect_identical(unique(cont$label), c("#1", "#2"))
  expect_identical(unique(cont$slot), 1L)
  # brute force for one group
  m <- d$g == "p1"
  xe <- seq(-4, 7, length.out = 41)
  ye <- seq(-4, 6, length.out = 41)
  h <- table(factor(findInterval(d$x[m], xe, rightmost.closed = TRUE), levels = 1:40),
             factor(findInterval(d$y[m], ye, rightmost.closed = TRUE), levels = 1:40))
  z <- .figb_gaussian_smooth(unclass(h) * 1, 2, 4)
  v <- sort(as.vector(z), decreasing = TRUE)
  t <- v[which(cumsum(v) >= 0.9 * sum(v))[1]]
  expect_equal(unique(cont$level[cont$g == "p1"]), t)
  expect_gte(sum(z[z >= t]), 0.9 * sum(z))
  expect_lt(sum(z[z > t]), 0.9 * sum(z) + t + 1e-9)
  expect_identical(unique(cont$n[cont$g == "p2"]), 400L)
  expect_error(DensityLevelContour(d, group = "g", limits = lim, carry = "x"), "reuse")
})

test_that("values on nested row subsets are looked up per sample", {
  d <- data.frame(s = c("a", "a", "b", "b"), r = c(0, 2, 1, 0))
  out <- LookupNestedRows(d, "s", "r", samples = c("a", "b"),
                          outer = list(list(counted = c(TRUE, FALSE, TRUE)), c(TRUE, TRUE)),
                          inner = list(list(defined_rows = c(TRUE, TRUE), cn = c(5L, 6L)),
                                       list(defined_rows = c(FALSE, TRUE), cn = 7L)), to = "cn")
  expect_identical(out$cn, c(5L, 6L, 7L, -1L))
  expect_error(LookupNestedRows(d, "s", "r", samples = c("a", "b"), outer = list(TRUE), inner = list(TRUE)), "one entry")
  expect_error(LookupNestedRows(d[1, ], "s", "r", samples = "a", outer = list(c(TRUE, TRUE)), inner = list(TRUE),
                                values = list(1L)), "does not match")
})
