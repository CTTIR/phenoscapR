.interaction_input_fixture <- function() {
  data.table::data.table(sample_id = "s", x = c(0, 1, 100, 101), y = 0,
                         phenotype = c("A", "A", "B", "B"))
}

test_that("missing labels cannot change the interaction frequency denominator", {
  for (labels in list(c("A", NA, "B", "B"), rep(NA_character_, 4),
                      c("A", "", "B", "B"), c("A", " ", "B", "B"))) {
    dt <- .interaction_input_fixture()
    dt$phenotype <- labels
    before <- data.table::copy(dt)
    expect_error(interaction_matrix(dt, 2), "phenotype")
    set.seed(12); rng <- .Random.seed
    expect_error(.interaction_permutation(dt, 2, 10L, 42L), "phenotype")
    expect_identical(.Random.seed, rng)
    expect_identical(dt, before)
  }
})

test_that("interaction geometry is checked before native search or RNG changes", {
  for (bad in list(c(NA, 1, 100, 101), c(Inf, 1, 100, 101),
                   as.character(c(0, 1, 100, 101)), rep(1 + 1i, 4))) {
    for (nm in c("x", "y")) {
      dt <- .interaction_input_fixture()
      dt[[nm]] <- bad
      expect_error(interaction_matrix(dt, 2), "finite real numeric")
      set.seed(12); rng <- .Random.seed
      expect_error(.interaction_permutation(dt, 2, 10L, 42L), "finite real numeric")
      expect_identical(.Random.seed, rng)
    }
  }
  for (nm in c("x", "y", "phenotype")) {
    dt <- .interaction_input_fixture()
    data.table::setattr(dt[[nm]], "dim", c(2L, 2L))
    expect_error(interaction_matrix(dt, 2), "vectors|phenotype")
    expect_error(.interaction_permutation(dt, 2, 10L, 42L), "vectors|phenotype")
  }
  dt <- .interaction_input_fixture()
  dt$x <- as.complex(dt$x)
  expect_error(cell_density(dt, 2), "finite numeric")
  expect_error(nearest_neighbours(dt), "finite numeric")
})

test_that("valid interaction tables preserve labels, sample defaults and empty schema", {
  dt <- .interaction_input_fixture()
  expected <- interaction_matrix(dt, 2)
  expect_equal(sum(expected$observed), 4)
  expect_equal(sum(expected$expected), 4)
  expect_equal(as.data.frame(interaction_matrix(as.data.frame(dt), 2)),
               as.data.frame(expected))
  dt[, sample_id := NULL]
  expect_identical(interaction_matrix(dt, 2), expected)
  dt$phenotype <- factor(dt$phenotype)
  out <- interaction_matrix(dt, 2)
  expect_equal(out$observed, expected$observed)
  expect_equal(out$expected, expected$expected)
  expect_equal(out$interaction_score, expected$interaction_score)
  empty <- dt[0]
  expect_equal(nrow(interaction_matrix(empty, 2)), 0L)
  expect_equal(nrow(.interaction_permutation(empty, 2, 10L, 42L)), 0L)
})
