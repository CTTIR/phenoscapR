# Large-n correctness guards. Several statistics use n^2 / sum-of-squares terms
# that silently overflow R's 32-bit integers past ~46,000 cells; these tests
# exercise that regime to ensure the maths stays in double precision.

test_that("MoransI stays finite above the integer-overflow threshold", {
  set.seed(1)
  n <- 50000L   # n * n = 2.5e9 > .Machine$integer.max
  counts <- matrix(rnorm(n), ncol = 1, dimnames = list(NULL, "CD31"))
  # Mild spatial gradient so the statistic is well defined and positive.
  coords <- data.frame(x = runif(n, 0, 1000), y = runif(n, 0, 1000))
  counts[, 1] <- counts[, 1] + coords$x / 200
  obj <- CreateSpatialObject(counts, coords)

  mi <- MoransI(obj, feature = "CD31", radius = 20)
  expect_true(is.finite(mi$I))
  expect_true(is.finite(mi$variance))
  expect_true(is.finite(mi$z_score))
  expect_gt(mi$variance, 0)
})

test_that("RipleysK border correction is vectorised yet matches the definition", {
  set.seed(2)
  n <- 400L
  counts <- matrix(rnorm(2 * n), ncol = 2, dimnames = list(NULL, c("A", "B")))
  coords <- data.frame(x = runif(n, 0, 200), y = runif(n, 0, 200))
  obj <- CreateSpatialObject(counts, coords)

  r_seq <- seq(0, 40, length.out = 12)
  got <- RipleysK(obj, r_seq = r_seq, correction = "border")

  # Independent reference straight from the distance matrix.
  xy <- as.matrix(coords)
  d <- as.matrix(dist(xy)); diag(d) <- Inf
  xr <- range(xy[, 1]); yr <- range(xy[, 2])
  area <- diff(xr) * diff(yr); lambda <- n / area
  b <- pmin(xy[, 1] - xr[1], xr[2] - xy[, 1], xy[, 2] - yr[1], yr[2] - xy[, 2])
  ref <- vapply(r_seq, function(r) {
    elig <- which(b >= r)
    if (!length(elig)) return(NA_real_)
    sum(rowSums(d[elig, , drop = FALSE] <= r)) / (length(elig) * lambda)
  }, numeric(1))

  expect_equal(got$K, ref, tolerance = 1e-8)
})
