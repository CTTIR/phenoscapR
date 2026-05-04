test_that("qc_filter removes cells by area", {
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:10,
    x = runif(10), y = runif(10),
    cell_area = c(5, seq(50, 200, length.out = 8), 5000),
    CD3 = rnorm(10, 300, 50)
  )
  result <- qc_filter(dt, min_area = 10, max_area = 1000)
  expect_true(all(result$cell_area >= 10))
  expect_true(all(result$cell_area <= 1000))
  expect_lt(nrow(result), nrow(dt))
})

test_that("normalise_markers z-score has zero mean", {
  set.seed(42)
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:100,
    x = runif(100), y = runif(100),
    CD3 = rnorm(100, 500, 100)
  )
  norm <- normalise_markers(dt, method = "zscore")
  expect_equal(mean(norm$CD3), 0, tolerance = 1e-10)
})

test_that("normalise_markers minmax is in [0, 1]", {
  set.seed(42)
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:50,
    x = runif(50), y = runif(50),
    CD3 = rnorm(50, 500, 100)
  )
  norm <- normalise_markers(dt, method = "minmax")
  expect_true(all(norm$CD3 >= 0 & norm$CD3 <= 1))
})

test_that("phenotype_cells assigns correct phenotypes", {
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:4,
    x = runif(4), y = runif(4),
    CD3 = c(0.8, 0.1, 0.9, 0.1),
    CD8 = c(0.1, 0.8, 0.7, 0.1)
  )
  result <- phenotype_cells(dt, thresholds = list(CD3 = 0.5, CD8 = 0.5))
  expect_true("phenotype" %in% names(result))
  expect_equal(result$phenotype[1], "CD3+")
  expect_equal(result$phenotype[2], "CD8+")
  expect_equal(result$phenotype[3], "CD3+/CD8+")
  expect_equal(result$phenotype[4], "Negative")
})

test_that("summarise_phenotypes computes proportions", {
  dt <- data.table::data.table(
    sample_id = rep("s1", 100),
    phenotype = sample(c("A", "B"), 100, replace = TRUE)
  )
  result <- summarise_phenotypes(dt)
  expect_true(all(c("count", "proportion") %in% names(result)))
  expect_equal(sum(result$proportion), 1)
})
