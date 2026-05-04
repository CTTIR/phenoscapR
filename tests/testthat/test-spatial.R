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
