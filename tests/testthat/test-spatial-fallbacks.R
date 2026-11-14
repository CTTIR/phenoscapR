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

# Hide only the requested backend; do not invent other optional installations.
mock_no <- function(pkg) function(package, ...) {
  !identical(package, pkg) && base::requireNamespace(package, ...)
}

test_that("CellDensity matches between RANN and the pure-R fallback", {
  obj <- make_obj()
  fast <- CellDensity(obj, radius = 30)
  local_mocked_bindings(requireNamespace = mock_no("RANN"))
  slow <- CellDensity(obj, radius = 30)
  expect_equal(slow, fast)
})

test_that("FindNeighbours falls back to the exact kNN search", {
  obj <- make_obj()
  local_mocked_bindings(requireNamespace = mock_no("RANN"))
  slow <- FindNeighbours(obj, k = 3L)
  expect_equal(NCells(slow), NCells(obj))
})

test_that("CrossNNDistance fallback agrees with the kd-tree result", {
  obj <- make_obj()
  fast <- CrossNNDistance(obj, from = "A", to = "B")
  local_mocked_bindings(requireNamespace = mock_no("RANN"))
  slow <- CrossNNDistance(obj, from = "A", to = "B")
  expect_equal(as.numeric(slow), as.numeric(fast), tolerance = 1e-8)
})

test_that("RipleysK fallback sweep agrees with the kd-tree sweep", {
  obj <- make_obj(n = 60L)
  r_seq <- seq(0, 40, length.out = 15)
  fast <- RipleysK(obj, r_seq = r_seq)
  local_mocked_bindings(requireNamespace = mock_no("RANN"))
  slow <- RipleysK(obj, r_seq = r_seq)
  expect_equal(slow$K, fast$K, tolerance = 1e-8)
})

test_that("DelaunayNetwork warns and falls back without deldir", {
  obj <- make_obj(n = 20L)
  local_mocked_bindings(requireNamespace = mock_no("deldir"))
  expect_warning(net <- DelaunayNetwork(obj), "deldir")
  edges <- net@spatial$delaunay_edges
  expect_true(all(c("from", "to", "distance") %in% names(edges)))
  expect_gt(nrow(edges), 0L)
})

test_that("targeted queries exclude self but retain coincident other cells", {
  dt <- data.table::data.table(
    sample_id = c("s1", "s2", "s1", "s1", "s2"),
    cell_id = letters[1:5], x = c(0, 0, 0, 2, 3), y = 0,
    phenotype = c("A", "A", "B", "A", "B")
  )
  # Independent references enumerate cell identities within each sample.
  oracle <- function(target, k = 1L, radius = 3) {
    lapply(seq_len(nrow(dt)), function(i) {
      other <- which(dt$sample_id == dt$sample_id[i] &
                       dt$phenotype == target & seq_len(nrow(dt)) != i)
      distances <- sqrt((dt$x[other] - dt$x[i])^2 + (dt$y[other] - dt$y[i])^2)
      c(density = sum(distances <= radius),
        distance = if (length(distances)) mean(head(sort(distances), k)) else NA_real_)
    })
  }
  verify <- function() {
    for (target in c("A", "B", "absent")) {
      for (k in c(1L, 2L, 10L)) {
        reference <- do.call(rbind, oracle(target, k))
        expect_equal(cell_density(dt, 3, target)$density,
                     unname(reference[, "density"]))
        expect_equal(nearest_neighbours(dt, target, k)$nn_distance,
                     unname(reference[, "distance"]))
      }
    }
    expect_equal(cell_density(dt, 3, "A")$density +
                   cell_density(dt, 3, "B")$density,
                 cell_density(dt, 3)$density)
    reordered <- dt[c(5L, 3L, 1L, 4L, 2L)]
    back <- match(dt$cell_id, reordered$cell_id)
    expect_equal(nearest_neighbours(reordered, "A", 2L)$nn_distance[back],
                 nearest_neighbours(dt, "A", 2L)$nn_distance)
    expect_equal(cell_density(reordered, 3, "A")$density[back],
                 cell_density(dt, 3, "A")$density)
  }
  verify()
  local_mocked_bindings(requireNamespace = mock_no("RANN"))
  verify()
})

test_that("duplicate-coordinate kNN fallback excludes identities too", {
  coords <- rbind(c(0, 0), c(0, 0), c(1, 0))
  fast <- phenoscapR:::.knn_index(coords, 2L)
  local_mocked_bindings(requireNamespace = mock_no("RANN"))
  slow <- phenoscapR:::.knn_index(coords, 2L)
  for (i in seq_len(nrow(coords))) {
    expect_setequal(fast$idx[i, ], setdiff(seq_len(nrow(coords)), i))
    expect_setequal(slow$idx[i, ], setdiff(seq_len(nrow(coords)), i))
    expect_equal(sort(slow$dist[i, ]), sort(fast$dist[i, ]))
  }
})
