test_that("FindNeighbours computes distances", {
  counts <- matrix(rnorm(20), nrow = 10,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = seq(0, 90, by = 10), y = rep(0, 10))
  obj <- CreateAkoyaObject(counts, coords)

  result <- FindNeighbours(obj, k = 1)
  nn <- Meta(result)$nn_distance
  expect_true(all(nn == 10))
})

test_that("CellDensity counts neighbours", {
  counts <- matrix(rnorm(10), nrow = 5,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = c(0, 1, 2, 100, 101), y = rep(0, 5))
  obj <- CreateAkoyaObject(counts, coords)

  result <- CellDensity(obj, radius = 5)
  dens <- Meta(result)$density
  expect_equal(dens[1], 2)  # cells at 1 and 2 are within radius
})

test_that("SpatialClusters returns k clusters", {
  set.seed(42)
  counts <- matrix(rnorm(80), nrow = 40,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(
    x = c(rnorm(20, 0, 2), rnorm(20, 50, 2)),
    y = c(rnorm(20, 0, 2), rnorm(20, 50, 2))
  )
  obj <- CreateAkoyaObject(counts, coords)

  result <- SpatialClusters(obj, k = 2)
  expect_true("cluster" %in% names(Meta(result)))
  expect_equal(length(unique(Meta(result)$cluster)), 2L)
})

test_that("InteractionMatrix returns correct structure", {
  set.seed(42)
  counts <- matrix(rnorm(100), nrow = 50,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
  obj <- CreateAkoyaObject(counts, coords)
  obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0))

  result <- InteractionMatrix(obj, radius = 30)
  expect_true(all(c("from", "to", "observed", "expected",
                     "interaction_score") %in% names(result)))
})
