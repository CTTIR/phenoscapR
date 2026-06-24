# Exercises the exact pure-R fallback paths in spatial.R that are skipped when
# the optional kd-tree (RANN) and triangulation (deldir) packages are present.
# We force them absent by mocking requireNamespace(), then confirm the fallback
# results agree with the fast paths.

make_obj <- function(n = 50L, seed = 1L) {
  set.seed(seed)
  counts <- matrix(rnorm(2 * n), nrow = n,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(n, 0, 100), y = runif(n, 0, 100))
  meta <- data.frame(cell_id = seq_len(n), sample_id = "s1",
                     phenotype = sample(c("A", "B"), n, replace = TRUE))
  CreateSpatialObject(counts, coords, meta)
}

mock_no <- function(pkg) function(package, ...) !identical(package, pkg)

test_that("CellDensity matches between RANN and the pure-R fallback", {
  obj <- make_obj()
  fast <- CellDensity(obj, radius = 30)
  local_mocked_bindings(requireNamespace = mock_no("RANN"), .package = "base")
  slow <- CellDensity(obj, radius = 30)
  expect_equal(slow, fast)
})

test_that("FindNeighbours falls back to the exact kNN search", {
  obj <- make_obj()
  local_mocked_bindings(requireNamespace = mock_no("RANN"), .package = "base")
  slow <- FindNeighbours(obj, k = 3L)
  expect_equal(NCells(slow), NCells(obj))
})

test_that("CrossNNDistance fallback agrees with the kd-tree result", {
  obj <- make_obj()
  fast <- CrossNNDistance(obj, from = "A", to = "B")
  local_mocked_bindings(requireNamespace = mock_no("RANN"), .package = "base")
  slow <- CrossNNDistance(obj, from = "A", to = "B")
  expect_equal(as.numeric(slow), as.numeric(fast), tolerance = 1e-8)
})

test_that("RipleysK fallback sweep agrees with the kd-tree sweep", {
  obj <- make_obj(n = 60L)
  r_seq <- seq(0, 40, length.out = 15)
  fast <- RipleysK(obj, r_seq = r_seq)
  local_mocked_bindings(requireNamespace = mock_no("RANN"), .package = "base")
  slow <- RipleysK(obj, r_seq = r_seq)
  expect_equal(slow$K, fast$K, tolerance = 1e-8)
})

test_that("DelaunayNetwork warns and falls back without deldir", {
  obj <- make_obj(n = 20L)
  local_mocked_bindings(requireNamespace = mock_no("deldir"), .package = "base")
  expect_warning(net <- DelaunayNetwork(obj), "deldir")
  edges <- net@spatial$delaunay_edges
  expect_true(all(c("from", "to", "distance") %in% names(edges)))
  expect_gt(nrow(edges), 0L)
})
