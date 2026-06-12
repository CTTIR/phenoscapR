test_that("nearest_neighbours computes distances", {
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:10,
    x = seq(0, 90, by = 10), y = rep(0, 10)
  )
  result <- nearest_neighbours(dt)
  expect_true("nn_distance" %in% names(result))
  # All nearest neighbour distances should be 10
  expect_true(all(result$nn_distance == 10))
})

test_that("cell_density counts neighbours within radius", {
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:5,
    x = c(0, 1, 2, 100, 101), y = rep(0, 5)
  )
  result <- cell_density(dt, radius = 5)
  expect_true("density" %in% names(result))
  # Cell 1 at x=0 should have 2 neighbours within radius 5

  expect_equal(result$density[1], 2)
})

test_that("spatial_clusters returns k clusters", {
  set.seed(42)
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:40,
    x = c(rnorm(20, 0, 2), rnorm(20, 50, 2)),
    y = c(rnorm(20, 0, 2), rnorm(20, 50, 2))
  )
  result <- spatial_clusters(dt, k = 2)
  expect_true("cluster" %in% names(result))
  expect_equal(length(unique(result$cluster)), 2L)
})

test_that("interaction_matrix returns correct structure", {
  set.seed(42)
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:50,
    x = runif(50, 0, 100), y = runif(50, 0, 100),
    phenotype = sample(c("A", "B"), 50, replace = TRUE)
  )
  result <- interaction_matrix(dt, radius = 30)
  expect_true(all(c("from", "to", "observed", "expected",
                     "interaction_score") %in% names(result)))
  expect_equal(nrow(result), 4L)  # 2x2 phenotypes
})

test_that("interaction_matrix does not count neighbours across samples", {
  # Two samples occupying the same coordinate space but each containing only a
  # single phenotype. Neighbours must never be counted across samples, so the
  # A<->B cross terms must be exactly zero.
  dt <- data.table::data.table(
    sample_id = rep(c("sA", "sB"), each = 3L),
    cell_id   = 1:6,
    x = c(0, 1, 2, 0.5, 1.5, 2.5),
    y = rep(0, 6),
    phenotype = rep(c("A", "B"), each = 3L)
  )
  result <- interaction_matrix(dt, radius = 5)
  ab <- result[result$from == "A" & result$to == "B", ]$observed
  ba <- result[result$from == "B" & result$to == "A", ]$observed
  expect_equal(ab, 0)
  expect_equal(ba, 0)
  # Within-sample same-phenotype neighbours are still counted (3 cells, each
  # sees the other 2 within radius 5) => 6 per sample, on the diagonal.
  aa <- result[result$from == "A" & result$to == "A", ]$observed
  expect_equal(aa, 6)
})

test_that("DelaunayNetwork builds a planar triangulation, not all pairs", {
  skip_if_not_installed("deldir")
  set.seed(11)
  n <- 12L
  counts <- matrix(rnorm(2 * n), nrow = n,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(n, 0, 100), y = runif(n, 0, 100))
  obj <- CreateSpatialObject(counts, coords)

  obj <- DelaunayNetwork(obj)
  edges <- obj@spatial$delaunay_edges

  expect_true(all(c("from", "to", "distance") %in% names(edges)))
  # A planar triangulation of n points has at most 3n - 6 edges, far fewer
  # than the n(n-1)/2 of an all-pairs graph.
  expect_lte(nrow(edges), 3L * n - 6L)
  expect_lt(nrow(edges), n * (n - 1L) / 2L)
  # Connected: every vertex appears in at least one edge.
  expect_setequal(union(edges$from, edges$to), seq_len(n))
})

test_that("DelaunayNetwork respects max_edge", {
  skip_if_not_installed("deldir")
  set.seed(12)
  n <- 15L
  counts <- matrix(rnorm(2 * n), nrow = n,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(n, 0, 100), y = runif(n, 0, 100))
  obj <- CreateSpatialObject(counts, coords)

  obj <- DelaunayNetwork(obj, max_edge = 20)
  edges <- obj@spatial$delaunay_edges
  expect_true(all(edges$distance <= 20))
})

test_that("RipleysK border correction changes the estimate", {
  set.seed(20)
  n <- 80L
  counts <- matrix(rnorm(2 * n), nrow = n,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(n, 0, 200), y = runif(n, 0, 200))
  obj <- CreateSpatialObject(counts, coords)

  r_seq <- seq(0, 40, length.out = 20)
  none   <- RipleysK(obj, r_seq = r_seq, correction = "none")
  border <- RipleysK(obj, r_seq = r_seq, correction = "border")

  expect_equal(nrow(border), length(r_seq))
  # Border correction must actually be applied: the estimate differs from the
  # uncorrected one at positive radii (edge effects matter near the boundary).
  expect_false(isTRUE(all.equal(none$K, border$K)))
  expect_true(all(is.finite(border$K)))
})

test_that("single-sample spatial statistics reject multi-sample objects", {
  set.seed(7)
  counts <- matrix(rnorm(40), nrow = 20,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(20, 0, 100), y = runif(20, 0, 100))
  meta <- data.frame(cell_id = 1:20,
                     sample_id = rep(c("s1", "s2"), each = 10),
                     phenotype = rep(c("A", "B"), 10))
  obj <- CreateSpatialObject(counts, coords, meta)

  expect_error(RipleysK(obj), "single sample")
  expect_error(MoransI(obj, feature = "CD3", radius = 30), "single sample")
  expect_error(QuadratAnalysis(obj, nx = 2, ny = 2), "single sample")
  expect_error(PairCorrelation(obj), "single sample")
  expect_error(NeighbourhoodEnrichment(obj, radius = 30, n_perm = 5),
               "single sample")
  expect_error(CrossNNDistance(obj, from = "A", to = "B"), "single sample")
})
