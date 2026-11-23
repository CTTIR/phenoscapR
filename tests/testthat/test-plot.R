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

# --- Legibility of the rendered plots ----------------------------------------

legible_object <- function(n = 60) {
  set.seed(11)
  counts <- matrix(rnorm(n * 2), nrow = n, dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(n, 0, 500), y = runif(n, 0, 500))
  meta <- data.frame(cell_id = seq_len(n), sample_id = "s1",
                     cell_area = runif(n, 10, 500),
                     phenotype = rep(c("B cell", "Macrophage", "T cytotoxic"), length.out = n))
  CreateSpatialObject(counts, coords, meta)
}

legend_override <- function(p) p$guides$guides$colour$params$override.aes

test_that("point maps draw readable legend keys for small points", {
  obj <- legible_object()
  key <- legend_override(CellMap(obj))
  expect_identical(key$size, 3)
  expect_identical(key$alpha, 1)
  # A larger point size is kept in the key.
  expect_identical(legend_override(CellMap(obj, pt_size = 5))$size, 5)
  expect_identical(legend_override(QCPlot(obj, "cell_area", "cell_id",
                                          colour_by = "phenotype"))$alpha, 1)
  # Continuous colours keep their colour bar.
  expect_null(CellMap(obj, colour_by = "cell_area")$guides$guides$colour)
  expect_null(QCPlot(obj, "cell_area", "cell_id")$guides$guides$colour)
})

test_that("violin and box plots rotate the group labels", {
  obj <- legible_object()
  for (p in list(ViolinPlot(obj, c("CD3", "CD8")), BoxPlot(obj, c("CD3", "CD8")))) {
    expect_identical(p$theme$axis.text.x$angle, 45)
    expect_identical(p$theme$axis.text.x$hjust, 1)
  }
})

test_that("automatic colours stay visible on the dark background", {
  skip_if_not_installed("deldir")
  lightness <- function(cols) {
    grDevices::convertColor(t(grDevices::col2rgb(cols)) / 255, from = "sRGB", to = "Lab")[, 1L]
  }
  obj <- DelaunayNetwork(legible_object())
  dark <- unique(ggplot2::ggplot_build(SpatialNetworkPlot(obj))$data[[2]]$colour)
  light <- unique(ggplot2::ggplot_build(SpatialNetworkPlot(obj, dark_theme = FALSE))$data[[2]]$colour)
  expect_length(dark, 3L)
  expect_true(all(lightness(dark) >= 40))
  # The light theme keeps the full palette, including its dark end.
  expect_setequal(light, PaletteDiscrete(3L))
  expect_true(min(lightness(light)) < 40)
  map <- unique(ggplot2::ggplot_build(CellMap(obj, dark_theme = TRUE))$data[[1]]$colour)
  expect_true(all(lightness(map) >= 40))
  # Explicit colours are used as given.
  given <- c(`B cell` = "#000080", Macrophage = "#FF0000", `T cytotoxic` = "#00FF00")
  own <- unique(ggplot2::ggplot_build(SpatialNetworkPlot(obj, colours = given))$data[[2]]$colour)
  expect_setequal(own, unname(given))
  expect_identical(phenoscapR:::.palette_discrete_dark(0L), character(0))
  expect_length(phenoscapR:::.palette_discrete_dark(1L), 1L)
})

test_that("categories keep their colours between the light and the dark theme", {
  skip_if_not_installed("deldir")
  lab <- function(cols) {
    grDevices::convertColor(t(grDevices::col2rgb(cols)) / 255, from = "sRGB", to = "Lab")
  }
  category_colours <- function(p, layer) {
    built <- ggplot2::ggplot_build(p)$data[[layer]]
    tapply(built$colour, obj$phenotype, unique)
  }
  set.seed(3)
  n <- 100L
  obj <- CreateSpatialObject(
    matrix(rnorm(n), nrow = n, dimnames = list(NULL, "CD3")),
    data.frame(x = runif(n, 0, 500), y = runif(n, 0, 500)),
    data.frame(cell_id = seq_len(n), sample_id = "s1",
               phenotype = rep(c("B cell", "Macrophage", "T cytotoxic", "T helper", "Tumour"),
                               length.out = n)))
  obj <- DelaunayNetwork(obj)
  light <- category_colours(CellMap(obj), 1L)
  dark <- category_colours(SpatialNetworkPlot(obj), 2L)
  expect_identical(names(dark), names(light))
  expect_identical(anyDuplicated(dark), 0L)
  # Colours that can be seen against black are the same in both plots.
  visible <- lab(light)[, 1L] >= 40
  expect_true(sum(visible) >= 3L)
  expect_identical(dark[visible], light[visible])
  # A colour too dark for the black background is only drawn lighter: it
  # keeps its hue and stays closest to its own category.
  dark_lab <- lab(dark)
  light_lab <- lab(light)
  expect_true(all(dark_lab[!visible, 1L] >= 40))
  hue <- function(m) atan2(m[, 3L], m[, 2L])
  expect_equal(hue(dark_lab)[!visible], hue(light_lab)[!visible], tolerance = 0.1)
  nearest <- vapply(seq_len(nrow(dark_lab)), function(i) {
    which.min(colSums((t(light_lab) - dark_lab[i, ])^2))
  }, integer(1L))
  expect_identical(nearest, seq_len(nrow(dark_lab)))
  expect_identical(category_colours(CellMap(obj, dark_theme = TRUE), 1L), dark)
})

test_that("discrete colour vectors set with SetPalette() are used as given on dark maps", {
  skip_if_not_installed("deldir")
  okabe_ito <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2",
                 "#D55E00", "#CC79A7", "#000000")
  old <- SetPalette(okabe_ito)
  on.exit(SetPalette(old), add = TRUE)
  expect_identical(phenoscapR:::.palette_discrete_dark(5L), okabe_ito[1:5])
  obj <- DelaunayNetwork(legible_object())
  for (p in list(CellMap(obj, dark_theme = TRUE), SpatialNetworkPlot(obj))) {
    built <- ggplot2::ggplot_build(p)$data
    expect_setequal(unique(built[[length(built)]]$colour), okabe_ito[1:3])
  }
  named <- c(`B cell` = "#0072B2", Macrophage = "#D55E00", `T cytotoxic` = "#009E73",
             Other = "#CC79A7")
  SetPalette(named)
  built <- ggplot2::ggplot_build(CellMap(obj, dark_theme = TRUE))$data[[1L]]
  expect_identical(as.vector(tapply(built$colour, obj$phenotype, unique)),
                   unname(named[1:3]))
  expect_identical(built$colour, ggplot2::ggplot_build(CellMap(obj))$data[[1L]]$colour)
  # A gradient ending in black cannot be lightened without merging colours.
  expect_identical(phenoscapR:::.palette_discrete_dark(6L, c("white", "black")),
                   PaletteDiscrete(6L, c("white", "black")))
})

test_that("network plots colour nodes by numeric columns", {
  skip_if_not_installed("deldir")
  obj <- DelaunayNetwork(legible_object())
  p <- SpatialNetworkPlot(obj, colour_by = "cell_area")
  built <- ggplot2::ggplot_build(p)$data[[2L]]
  expect_gt(length(unique(built$colour)), 3L)
  expect_null(p$guides$guides$colour)
})

test_that("network edges are drawn visibly by default", {
  skip_if_not_installed("deldir")
  obj <- DelaunayNetwork(legible_object())
  expect_identical(formals(SpatialNetworkPlot)$edge_alpha, 0.5)
  edges <- ggplot2::ggplot_build(SpatialNetworkPlot(obj))$data[[1]]
  expect_true(all(edges$alpha == 0.5))
})
