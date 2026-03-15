test_that("CellMap returns ggplot", {
  counts <- matrix(rnorm(40), nrow = 20,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(20), y = runif(20))
  obj <- CreateAkoyaObject(counts, coords)
  obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0))

  p <- CellMap(obj)
  expect_s3_class(p, "gg")
})

test_that("DensityPlot returns ggplot", {
  counts <- matrix(rnorm(40), nrow = 20,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(20), y = runif(20))
  obj <- CreateAkoyaObject(counts, coords)
  obj <- CellDensity(obj, radius = 0.5)

  p <- DensityPlot(obj)
  expect_s3_class(p, "gg")
})

test_that("InteractionPlot returns ggplot", {
  interactions <- data.frame(
    from = rep(c("A", "B"), each = 2),
    to = rep(c("A", "B"), 2),
    observed = c(10, 5, 5, 10),
    expected = rep(7.5, 4),
    interaction_score = log2(c(10, 5, 5, 10) / 7.5)
  )
  p <- InteractionPlot(interactions)
  expect_s3_class(p, "gg")
})

test_that("MarkerHeatmap returns ggplot", {
  counts <- matrix(c(rnorm(20, 1), rnorm(20, 0),
                     rnorm(20, 0), rnorm(20, 1)), ncol = 2,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(40), y = runif(40))
  meta <- data.frame(cell_id = 1:40, sample_id = "s1",
                     phenotype = rep(c("A", "B"), each = 20))
  obj <- CreateAkoyaObject(counts, coords, meta)

  p <- MarkerHeatmap(obj)
  expect_s3_class(p, "gg")
})

test_that("CellMap errors on missing column", {
  counts <- matrix(rnorm(10), nrow = 5,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = 1:5, y = 1:5)
  obj <- CreateAkoyaObject(counts, coords)

  expect_error(CellMap(obj, colour_by = "missing"), "not found")
})
