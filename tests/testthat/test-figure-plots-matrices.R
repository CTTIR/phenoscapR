# Draw a ggplot (or a composed page) on a throw-away device.
draw_off_screen <- function(p, w = 4, h = 3) {
  f <- withr::local_tempfile(fileext = ".png")
  if (requireNamespace("ragg", quietly = TRUE)) {
    ragg::agg_png(f, width = w, height = h, units = "in", res = 100)
  } else if (capabilities("cairo")) {
    grDevices::png(f, width = w, height = h, units = "in", res = 100,
                  type = "cairo")
  } else {
    # Base PDF uses the font fallback registered by ManuscriptStyle().
    f <- withr::local_tempfile(fileext = ".pdf")
    grDevices::pdf(f, width = w, height = h)
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  if (inherits(p, "ggplot")) grid::grid.draw(ggplot2::ggplotGrob(p)) else print(p)
  invisible(TRUE)
}

test_that("colour ramps map values like 256-entry lookup tables", {
  lut <- .figb_ramp("blues")
  expect_length(lut, 256L)
  expect_identical(toupper(lut[c(1, 256)]), c("#F7FBFF", "#08306B"))
  expect_identical(toupper(.figb_ramp("rdbu_r")[c(1, 256)]), c("#053061", "#67001F"))
  v <- .figb_map_colours(c(-1, 0, 40, 80, 100, NA), c(0, 80), lut, missing = "#EEEEEE")
  expect_identical(v[c(1, 2)], lut[c(1, 1)])
  expect_identical(v[3], lut[129])
  expect_identical(v[c(4, 5)], lut[c(256, 256)])
  expect_identical(v[6], "#EEEEEE")
  expect_length(.figb_ramp(c("#000000", "#FFFFFF"), n = 3), 3L)
  expect_error(.figb_ramp("rainbowish"), "Unknown colour scale")
})

test_that("a constant heatmap takes the first colour instead of missing fills", {
  lut <- .figb_ramp("blues")
  expect_identical(.figb_map_colours(c(5, 5, NA), c(5, 5), lut), c(lut[1], lut[1], "#EEEEEE"))
  expect_identical(.figb_map_colours(c(NA, NA), c(NA_real_, NA_real_), lut), c("#EEEEEE", "#EEEEEE"))
  d <- expand.grid(row = c("a", "b"), column = c("x", "y"), stringsAsFactors = FALSE)
  d$value <- 0
  fills <- ggplot2::layer_data(PlotAnnotatedHeatmap(d), 1)$fill
  expect_false(anyNA(fills))
  expect_length(unique(fills), 1L)
})

test_that("annotated heatmaps draw values, boxes, labels and a colour bar", {
  d <- expand.grid(row = c("r1", "r2", "r3"), column = c("c1", "c2", "c3", "c4"), stringsAsFactors = FALSE)
  d$value <- c(85, 9, 9, 0.5, 15, 2, 1, 1, 0, 1, 1, 67)
  p <- PlotAnnotatedHeatmap(d, limits = c(0, 80), drop_columns_below = 2,
                            cell_text = list(min = 1, white_above = 45, size = 4.4),
                            row_colours = data.frame(key = c("r1", "r2"), colour = c("#e34948", "groups/group1")),
                            column_fills = c(c1 = "#1f77b4"), column_angle = 50, x_label = "Columns",
                            row_labels = c(r1 = "Row one"), column_labels = c(c2 = "Second"),
                            colourbar = list(box = c(1.05, 0.2, 0.03, 0.6), title = "Share (%)"),
                            texts = list(list(label = "{n} rows", xy = c(0, 1.1))), values = data.frame(n = 3))
  expect_s3_class(p, "ggplot")
  expect_true(draw_off_screen(p))
  built <- ggplot2::ggplot_build(p)
  expect_identical(sum(built$data[[1]]$xmin == 3.5), 0L)
  counts <- data.frame(row = "a", column = c("x", "y", "z"), value = c(15, 7477, 10236))
  pc <- PlotAnnotatedHeatmap(counts, transform = "log10p1", limits = c(0, 4.5),
                             cell_text = list(format = "count", white_above = 2500))
  labs <- ggplot2::ggplot_build(pc)$data[[2]]
  expect_identical(labs$label, c("15", "7,477", "10k"))
  expect_identical(labs$colour, c("#222222", "white", "white"))
  expect_error(PlotAnnotatedHeatmap(d, value = "nope"), "lacks")
})

test_that("dot matrices size dots by area and drop empty rows", {
  d <- expand.grid(row = c("a", "b", "c"), column = c("m1", "m2"), stringsAsFactors = FALSE)
  d$size <- c(90, NA, 40, 5, NA, 20)
  d$signal <- c(2, 0, 9, -2, 0, 0)
  p <- PlotDotMatrix(d, row_colours = c(a = "#e34948", c = "#2a78d6"),
                     colourbar = list(box = c(1.05, 0.5, 0.03, 0.4), title = "z"),
                     size_key = list(values = c(10, 100), at = c(1.1, 0.3), step = 0.1, title = "Positive",
                                     title_at = c(1.05, 0.4)))
  expect_s3_class(p, "ggplot")
  expect_true(draw_off_screen(p))
  pts <- Filter(function(l) inherits(l$geom, "GeomCustomAnn"), p$layers)
  g <- pts[[1]]$geom_params$grob
  expect_identical(length(g$px), 4L)
  expect_equal(sort(g$diameter), sort(sqrt(2 + 0.55 * c(90, 40, 5, 20))))
  expect_identical(g$colour[g$px == 1 & g$py == 1], .figb_ramp("rdbu_r")[256])
})

test_that("stacked bars stack in order, label categories and print values above", {
  d <- data.frame(x = rep(c("p1", "p2"), each = 3), stack = rep(c("a", "b", "c"), 2),
                  value = c(0.2, 0.5, 0.3, 0.6, 0.1, 0.3), area = rep(c(6.2, 118.4), each = 3))
  p <- PlotStackedBars(d, scale = 100, limits = c(0, 100), x_order = c("p2", "p1"), stacks = c("c", "b", "a"),
                       colours = c(a = "#e34948", b = "#2a78d6", c = "coarse/unassigned"),
                       top_text = "area", top_title = "Area (mm2)", value_label = "Cells (%)",
                       x_label_colours = c(p1 = "groups/group1"), reference = list(value = 50),
                       legend = list(keys = c("a", "b"), shapes = "s", at = c(1.05, 1), title = "Types"))
  expect_true(draw_off_screen(p))
  r <- ggplot2::ggplot_build(p)$data[[1]]
  expect_equal(r$ymax[r$xmin < 1], c(30, 40, 100))
  expect_identical(r$fill[r$xmin < 1][1], "#D9D9D9")
  top <- Filter(function(x) "label" %in% names(x), ggplot2::ggplot_build(p)$data)[[1]]
  expect_identical(top$label, c("118", "6"))
  h <- PlotStackedBars(data.frame(x = c("A", "A", "B"), stack = c("u", "v", "u"), value = c(1, 2, 5)),
                       horizontal = TRUE, limits = c(0, 9.5), breaks = c(0, 2, 4, 6, 8), value_label = "Patients")
  rh <- ggplot2::ggplot_build(h)$data[[1]]
  expect_equal(rh$xmax, c(1, 3, 5))
  expect_equal(rh$ymin[1] > rh$ymin[3], TRUE)
  expect_true(draw_off_screen(h))
})

test_that("alteration matrices fill missing tiles and print row shares", {
  d <- data.frame(row = rep(c("G1", "G2"), each = 3), column = rep(c("s1", "s2", "s3"), 2),
                  value = c("Missense", NA, "Deletion", NA, "Truncating", NA), share = rep(c(67, 33), each = 3),
                  rk = rep(c(2, 1), each = 3))
  p <- PlotAlterationMatrix(d, colours = c(Missense = "alteration/missense", Truncating = "#222222", Deletion = "#2a78d6"),
                            row_order_by = "rk", right_text = "share", right_offset = 0.7, row_italic = TRUE,
                            show_columns = TRUE,
                            legends = list(list(keys = c("Missense", "Deletion"), shapes = "rect", title = "Alteration",
                                                at = c(0, -0.5), ncol = 2)))
  expect_true(draw_off_screen(p))
  b <- ggplot2::ggplot_build(p)
  tiles <- unique(b$data[[1]][, c("group", "fill")])
  expect_identical(nrow(tiles), 6L)
  expect_identical(sum(tiles$fill == "#F0F0F0"), 3L)
  expect_identical(b$data[[2]]$label, c("33%", "67%"))
  tr <- data.frame(track = "T", id = c("a", "b"), colour = c("#111111", "#999999"))
  q <- PlotAlterationMatrix(tr, row = "track", column = "id", value = "colour", fill_column = "colour", radius = 0)
  expect_identical(unique(ggplot2::ggplot_build(q)$data[[1]]$fill), c("#111111", "#999999"))
})

test_that("embeddings rasterise points and keep vector files small", {
  skip_without_cairo()
  skip_if_not_installed("ragg")
  set.seed(7)
  n <- 20000
  d <- data.frame(x = rnorm(n), y = rnorm(n), key = sample(c("a", "b", "D"), n, TRUE), grp = sample(c("g1", "g2"), n, TRUE))
  lab <- data.frame(label = c("1", "2"), x = c(0, 1), y = c(0, 1))
  p <- PlotEmbedding(d, limits = data.frame(xmin = -4, xmax = 4, ymin = -4, ymax = 4), subset = list(grp = "g1"),
                     colours = data.frame(key = c("a", "b"), colour = c("#e34948", "lineage/treg")),
                     sizes = c(a = 0.3, b = 0.5, D = 9), shapes = c(D = "D"), edge_colours = c(D = "white"),
                     edge_widths = c(D = 0.35), labels = lab, axis_style = "arrows",
                     legend = list(keys = c("a", "b", "D"), ncol = 2, at = c(1.02, 1)),
                     texts = list(list(label = "{grp} ({n} cells)", xy = c(0.5, 1.02), hjust = 0.5, vjust = 0)),
                     values = data.frame(grp = c("g1", "g2"), n = c(10, 20)))
  expect_s3_class(p, "ggplot")
  fig <- ComposeFigure(list(FigurePanel(p, c(10, 10, 40, 40))), height_mm = 60, width_mm = 80)
  dir <- withr::local_tempdir()
  SaveFigure(fig, pdf = file.path(dir, "e.pdf"), png = file.path(dir, "e.png"), dpi = 150)
  expect_lt(file.size(file.path(dir, "e.pdf")), 300000)
  vec <- PlotEmbedding(d[1:2000, ], limits = c(-4, 4, -4, 4), raster = FALSE, axis_style = "titles")
  expect_true(draw_off_screen(vec))
  pts <- Filter(function(l) inherits(l$geom, "GeomCustomAnn"), p$layers)[[1]]$geom_params$grob
  expect_identical(length(pts$px), sum(d$grp == "g1"))
  expect_true(all(pts$colour[d$key[d$grp == "g1"] == "b"] == ManuscriptPalettes()$lineage[["treg"]]))
})

test_that("density outlines draw one coloured region per group with a key", {
  set.seed(8)
  d <- data.frame(x = c(rnorm(300), rnorm(300, 2)), y = c(rnorm(300), rnorm(300, 1)),
                  pid = rep(c("p1", "p2"), each = 300), cl = rep(c("A", "B"), each = 300))
  lim <- c(-4, 6, -4, 5)
  cont <- DensityLevelContour(d, group = "pid", limits = lim, bins = 40, carry = "cl")
  p <- PlotDensityOutlines(cont, group = "pid", limits = lim, colours = c("#e34948", "#eda100"),
                           texts = list(list(label = "{cl}", xy = c(0.5, 1.02), hjust = 0.5, vjust = 0)),
                           subset = list(cl = "A"))
  expect_true(draw_off_screen(p))
  b <- ggplot2::ggplot_build(p)
  expect_identical(unique(b$data[[2]]$colour), "#e34948")
  expect_error(PlotDensityOutlines(data.frame(x = 1)), "lacks")
})

test_that("the matrix, bar and embedding grammars work from figure specifications", {
  skip_without_cairo()
  grammars <- FigureGrammars()
  expect_identical(unname(grammars[c("annotated_heatmap", "dot_matrix", "stacked_bars", "embedding",
                                     "density_outlines", "alteration_matrix")]),
                   c("PlotAnnotatedHeatmap", "PlotDotMatrix", "PlotStackedBars", "PlotEmbedding",
                     "PlotDensityOutlines", "PlotAlterationMatrix"))
  hm <- expand.grid(row = c("r1", "r2"), column = c("c1", "c2"), stringsAsFactors = FALSE)
  hm$value <- c(1, 50, 20, 80)
  bars <- data.frame(x = rep(c("p1", "p2"), each = 2), stack = rep(c("a", "b"), 2), value = c(1, 2, 3, 1))
  set.seed(9)
  emb <- data.frame(x = rnorm(300), y = rnorm(300), key = sample(c("a", "b"), 300, TRUE))
  spec <- list(height_mm = 80, width_mm = 120, panels = list(
    list(axes = c(0.1, 0.6, 0.25, 0.3), letter = "a", letter_xy = c(0.01, 0.99), grammar = "annotated_heatmap",
         data = "hm", args = list(limits = c(0, 80), cell_text = list(min = 1), row_colours = c(r1 = "groups/group2"))),
    list(axes = c(0.55, 0.6, 0.3, 0.3), grammar = "stacked_bars", data = "bars",
         args = list(colours = c(a = "groups/group1", b = "groups/group3"))),
    list(axes = c(0.1, 0.1, 0.3, 0.35), grammar = "embedding", data = list(data = "emb", limits = "lim"),
         args = list(colours = c(a = "lineage/tumour", b = "lineage/cd8_t"), axis_style = "arrows"))))
  fig <- RenderFigure(spec, list(hm = hm, bars = bars, emb = emb, lim = EmbeddingLimits(emb)))
  expect_s3_class(fig, "phenoscapR_figure")
  dir <- withr::local_tempdir()
  WriteFigure(spec, list(hm = hm, bars = bars, emb = emb, lim = EmbeddingLimits(emb)),
              pdf = file.path(dir, "s.pdf"), png = file.path(dir, "s.png"))
  expect_gt(file.size(file.path(dir, "s.png")), 1000)
})


test_that("horizontal stacked bars print the top values beyond the bar ends", {
  d <- data.frame(x = rep(c("p1", "p2", "p3"), each = 2), stack = rep(c("A", "B"), 3),
                  value = c(30, 70, 50, 50, 20, 80), area = rep(c(1.5, 2, 3), each = 2))
  top <- function(p) ggplot2::layer_data(p, length(p$layers))
  v <- PlotStackedBars(d, top_text = "area")
  h <- PlotStackedBars(d, horizontal = TRUE, top_text = "area")
  expect_equal(top(v)[, c("x", "y")], data.frame(x = c(1, 2, 3), y = 101.5))
  expect_equal(top(h)[, c("x", "y")], data.frame(x = 101.5, y = c(3, 2, 1)))
  expect_identical(top(h)$label, top(v)$label)
  ht <- PlotStackedBars(d, horizontal = TRUE, top_text = "area", top_title = "Area")
  expect_equal(unlist(top(ht)[, c("x", "y")]), c(x = 101.5, y = 3.6))
})
