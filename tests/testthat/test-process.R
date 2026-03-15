test_that("QCFilter removes cells by area", {
  counts <- matrix(rnorm(50, 300, 50), nrow = 10,
                   dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK", "CD20")))
  coords <- data.frame(x = runif(10), y = runif(10))
  meta <- data.frame(cell_id = 1:10, sample_id = "s1",
                     cell_area = c(5, seq(50, 200, length.out = 8), 5000))
  obj <- CreateAkoyaObject(counts, coords, meta)

  result <- QCFilter(obj, min_area = 10, max_area = 1000)
  expect_true(all(Meta(result)$cell_area >= 10))
  expect_true(all(Meta(result)$cell_area <= 1000))
  expect_lt(NCells(result), NCells(obj))
})

test_that("NormaliseData zscore produces zero mean", {
  set.seed(42)
  counts <- matrix(rnorm(100, 500, 100), nrow = 20,
                   dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK", "CD20")))
  coords <- data.frame(x = runif(20), y = runif(20))
  obj <- CreateAkoyaObject(counts, coords)

  norm <- NormaliseData(obj, method = "zscore")
  expect_equal(mean(GetData(norm)[, "CD3"]), 0, tolerance = 1e-10)
})

test_that("NormaliseData minmax is in [0, 1]", {
  set.seed(42)
  counts <- matrix(rnorm(100, 500, 100), nrow = 20,
                   dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK", "CD20")))
  coords <- data.frame(x = runif(20), y = runif(20))
  obj <- CreateAkoyaObject(counts, coords)

  norm <- NormaliseData(obj, method = "minmax")
  vals <- GetData(norm)[, "CD3"]
  expect_true(all(vals >= 0 & vals <= 1))
})

test_that("NormaliseData leaves counts unchanged", {
  counts <- matrix(rnorm(20, 500, 100), nrow = 5,
                   dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK")))
  coords <- data.frame(x = runif(5), y = runif(5))
  obj <- CreateAkoyaObject(counts, coords)
  original_counts <- GetData(obj, slot = "counts")

  norm <- NormaliseData(obj, method = "zscore")
  expect_equal(GetData(norm, slot = "counts"), original_counts)
  expect_false(identical(GetData(norm, slot = "data"),
                         GetData(norm, slot = "counts")))
})

test_that("PhenotypeCells assigns correct phenotypes", {
  counts <- matrix(c(0.8, 0.1, 0.9, 0.1,
                     0.1, 0.8, 0.7, 0.1), ncol = 2,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(4), y = runif(4))
  obj <- CreateAkoyaObject(counts, coords)
  result <- PhenotypeCells(obj, thresholds = list(CD3 = 0.5, CD8 = 0.5))

  phenos <- Meta(result)$phenotype
  expect_equal(phenos[1], "CD3+")
  expect_equal(phenos[2], "CD8+")
  expect_equal(phenos[3], "CD3+/CD8+")
  expect_equal(phenos[4], "Negative")
})

test_that("PhenotypeSummary computes proportions", {
  counts <- matrix(rnorm(200), nrow = 100,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(100), y = runif(100))
  obj <- CreateAkoyaObject(counts, coords)
  obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0))

  result <- PhenotypeSummary(obj)
  expect_true(all(c("count", "proportion") %in% names(result)))
  expect_equal(sum(result$proportion), 1, tolerance = 1e-10)
})
