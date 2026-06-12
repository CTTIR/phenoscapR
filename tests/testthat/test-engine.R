# The spatial-search engine has two interchangeable backends: a kd-tree (RANN)
# and an exact base-R fallback used when RANN is absent. They must return
# identical neighbours, counts, and distances, otherwise results would silently
# depend on which Suggests packages a user happens to have installed.

make_points <- function(n, seed) {
  set.seed(seed)
  cbind(x = runif(n, 0, 100), y = runif(n, 0, 100))
}

# A reference symmetric radius search computed directly from the full distance
# matrix, independent of either production backend.
ref_neighbours <- function(coords, radius) {
  d <- as.matrix(dist(coords))
  lapply(seq_len(nrow(coords)), function(i) {
    j <- which(d[i, ] <= radius & seq_len(nrow(coords)) != i)
    sort(j)
  })
}

test_that("kd-tree and brute-force radius search agree with the reference", {
  skip_if_not_installed("RANN")
  coords <- make_points(300L, seed = 1L)
  radius <- 15

  ref <- ref_neighbours(coords, radius)
  kd  <- phenoscapR:::.radius_neighbours(coords, radius)
  bf  <- phenoscapR:::.radius_neighbours_bruteforce(coords, radius)

  for (i in seq_along(ref)) {
    expect_setequal(kd$idx[[i]], ref[[i]])
    expect_setequal(bf$idx[[i]], ref[[i]])
  }
  # Distances line up with indices.
  expect_equal(sort(kd$dist[[1L]]), sort(bf$dist[[1L]]), tolerance = 1e-9)
})

test_that("radius search bumps k past the initial cap without truncating", {
  skip_if_not_installed("RANN")
  # Tight cluster so many points fall within radius, exceeding the k = 64 start.
  set.seed(7)
  coords <- cbind(x = rnorm(400, 0, 1), y = rnorm(400, 0, 1))
  radius <- 5  # essentially everything
  kd  <- phenoscapR:::.radius_neighbours(coords, radius)
  ref <- ref_neighbours(coords, radius)
  expect_equal(lengths(kd$idx), lengths(ref))
})

test_that("cross-set radius counts match a direct computation", {
  skip_if_not_installed("RANN")
  q <- make_points(120L, seed = 2L)
  d <- make_points(200L, seed = 3L)
  radius <- 20

  got <- phenoscapR:::.cross_radius_count(q, d, radius)
  dm <- as.matrix(dist(rbind(q, d)))[seq_len(nrow(q)), nrow(q) + seq_len(nrow(d))]
  ref <- rowSums(dm <= radius & dm > 0)
  expect_equal(got, as.integer(ref))
})

test_that("knn index matches an order()-based reference", {
  skip_if_not_installed("RANN")
  coords <- make_points(200L, seed = 9L)
  k <- 6L
  kn <- phenoscapR:::.knn_index(coords, k)
  bf <- phenoscapR:::.knn_index(coords[1:1, , drop = FALSE], 0L)  # degenerate guard
  expect_equal(dim(bf$idx), c(1L, 0L))

  d <- as.matrix(dist(coords)); diag(d) <- Inf
  for (i in c(1L, 50L, 137L)) {
    ref <- order(d[i, ])[seq_len(k)]
    expect_setequal(kn$idx[i, ], ref)
  }
  # distances are non-decreasing across the k columns
  expect_true(all(kn$dist[, 1] <= kn$dist[, k]))
})

test_that("radius count sweep matches a brute-force cumulative count", {
  skip_if_not_installed("RANN")
  coords <- make_points(300L, seed = 10L)
  r_eval <- seq(5, 60, length.out = 12)
  got <- phenoscapR:::.radius_count_sweep(coords, r_eval)

  d <- as.matrix(dist(coords)); diag(d) <- Inf
  ref <- vapply(r_eval, function(r) sum(d <= r), numeric(1))
  expect_equal(got, ref, tolerance = 1e-9)
})

test_that("knn mean distance matches a direct computation", {
  skip_if_not_installed("RANN")
  coords <- make_points(150L, seed = 4L)
  k <- 3L

  got <- phenoscapR:::.knn_mean_dist(coords, coords, k = k, drop_self = TRUE)
  d <- as.matrix(dist(coords))
  diag(d) <- Inf
  ref <- vapply(seq_len(nrow(coords)),
                function(i) mean(sort(d[i, ])[seq_len(k)]), numeric(1L))
  expect_equal(got, ref, tolerance = 1e-9)
})
