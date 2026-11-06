test_that("CellMap returns ggplot", {
  counts <- matrix(rnorm(40), nrow = 20,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(20), y = runif(20))
  obj <- CreateSpatialObject(counts, coords)
  obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0))

  p <- CellMap(obj)
  expect_s3_class(p, "gg")
})

test_that("DensityPlot returns ggplot", {
  counts <- matrix(rnorm(40), nrow = 20,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(20), y = runif(20))
  obj <- CreateSpatialObject(counts, coords)
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
  obj <- CreateSpatialObject(counts, coords, meta)

  p <- MarkerHeatmap(obj)
  expect_s3_class(p, "gg")
})

test_that("CellMap errors on missing column", {
  counts <- matrix(rnorm(10), nrow = 5,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = 1:5, y = 1:5)
  obj <- CreateSpatialObject(counts, coords)

  expect_error(CellMap(obj, colour_by = "missing"), "not found")
})

test_that("a numeric colour column gets a continuous scale", {
  set.seed(1)
  o <- CreateSpatialObject(matrix(rnorm(20), 10, 2, dimnames = list(NULL, c("CD3", "CD8"))),
                           data.frame(x = runif(10), y = runif(10)),
                           data.frame(cell_id = 1:10, sample_id = "s", cell_area = runif(10, 10, 50),
                                      phenotype = rep(c("A", "B"), 5)))
  b <- ggplot2::ggplot_build(CellMap(o, colour_by = "cell_area"))
  expect_true(b$plot$scales$get_scales("colour")$is_discrete() == FALSE)
  expect_length(unique(b$data[[1]]$colour), 10L)
  expect_true(ggplot2::ggplot_build(CellMap(o))$plot$scales$get_scales("colour")$is_discrete())
})

test_that("tissue maps draw y downward like image coordinates by default", {
  # Cell coordinates follow the image convention (origin at the top left, y
  # increasing downward; cellspecR, QuPath), so the maps reverse the y scale
  # and look like the tissue image. y_down = FALSE keeps y pointing up.
  set.seed(1)
  counts <- matrix(rnorm(40), nrow = 20, dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(20, 0, 100), y = runif(20, 0, 100))
  obj <- CreateSpatialObject(counts, coords)
  obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0))
  obj@meta_data$density <- seq_len(20)
  obj <- DelaunayNetwork(obj)
  dt <- data.table::data.table(x = coords$x, y = coords$y,
                               phenotype = obj@meta_data$phenotype,
                               density = seq_len(20))
  drawn_y <- function(p) {
    d <- ggplot2::layer_data(p, length(p$layers))
    d$y[order(d$x)]
  }
  y_true <- coords$y[order(coords$x)]
  maps <- list(
    CellMap = function(...) CellMap(obj, ...),
    FeaturePlot = function(...) FeaturePlot(obj, features = "CD3", ...),
    DensityPlot = function(...) DensityPlot(obj, ...),
    SpatialNetworkPlot = function(...) SpatialNetworkPlot(obj, ...),
    plot_cell_map = function(...) plot_cell_map(dt, ...),
    plot_density = function(...) plot_density(dt, ...)
  )
  for (nm in names(maps)) {
    expect_equal(drawn_y(maps[[nm]]()), -y_true, info = nm)
    expect_equal(drawn_y(maps[[nm]](y_down = FALSE)), y_true, info = nm)
  }
})
