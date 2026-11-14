.interaction_control_object <- function() {
  CreateSpatialObject(matrix(1, 4, 1, dimnames = list(NULL, "marker")),
    data.frame(x = c(0, 1, 100, 101), y = 0),
    data.frame(sample_id = letters[1:4], cell_id = 1:4,
               phenotype = c("A", "A", "B", "B")))
}

test_that("permutation controls reject invalid values before changing RNG", {
  obj <- .interaction_control_object()
  for (bad in list(0, 1, 1.9, Inf, NA_real_, c(2, 3), matrix(2), "10",
                   -1, 2 + 1i, .Machine$integer.max + 1)) {
    set.seed(321); before <- .Random.seed
    expect_error(InteractionMatrix(obj, 2, "permutation", n_perm = bad, seed = 7),
                 "n_perm")
    expect_identical(.Random.seed, before)
  }
  for (bad in list(1.2, Inf, NA_real_, matrix(1), c(1, 2), "1", 1 + 1i,
                   .Machine$integer.max + 1, -.Machine$integer.max - 1)) {
    set.seed(321); before <- .Random.seed
    expect_error(InteractionMatrix(obj, 2, "permutation", n_perm = 10, seed = bad),
                 "seed")
    expect_identical(.Random.seed, before)
  }
})

test_that("invalid interaction radii cannot bypass checks with singleton samples", {
  obj <- .interaction_control_object()
  dt <- data.table::data.table(sample_id = letters[1:4], x = 1:4, y = 0,
                               phenotype = c("A", "A", "B", "B"))
  for (bad in list(-1, NA_real_, Inf, c(1, 2), matrix(1), "1", 1 + 1i)) {
    set.seed(321); before <- .Random.seed
    expect_error(interaction_matrix(dt, bad), "radius")
    for (method in c("analytic", "permutation")) {
      expect_error(InteractionMatrix(obj, bad, method, n_perm = 10, seed = 7),
                   "radius")
    }
    expect_identical(.Random.seed, before)
  }
  expect_equal(InteractionMatrix(obj, 0)$observed, rep(0, 4))
})

test_that("valid signed seeds and ignored analytic controls retain their behavior", {
  obj <- .interaction_control_object()
  obj@meta_data$sample_id <- rep("s", 4)
  for (seed in c(-9, 0, 9, -.Machine$integer.max, .Machine$integer.max)) {
    a <- InteractionMatrix(obj, 2, "permutation", n_perm = 10, seed = seed)
    b <- InteractionMatrix(obj, 2, "permutation", n_perm = 10L, seed = as.integer(seed))
    expect_identical(a, b)
  }
  set.seed(321); before <- .Random.seed
  expect_identical(InteractionMatrix(obj, 2, n_perm = "unused", seed = "unused"),
                   InteractionMatrix(obj, 2))
  expect_identical(.Random.seed, before)
  obj@meta_data$sample_id[1] <- NA_character_
  expect_error(InteractionMatrix(obj, 2, "permutation", n_perm = 10, seed = 7),
               "sample_id")
  expect_identical(.Random.seed, before)
})
