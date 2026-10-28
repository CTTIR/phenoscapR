gc3 <- c(A = "#009E73", B = "#D55E00", C = "#0072B2")

# Build plots on a Cairo device so that text is measured with the figure font.
local_cairo <- function(env = parent.frame()) {
  f <- tempfile(fileext = ".png")
  grDevices::png(f, type = "cairo")
  withr::defer({
    grDevices::dev.off()
    unlink(f)
  }, envir = env)
}

built <- function(p) {
  local_cairo()
  expect_s3_class(p, "ggplot")
  g <- ggplot2::ggplotGrob(p)
  expect_s3_class(g, "gtable")
  invisible(ggplot2::ggplot_build(p))
}

layer_text <- function(p) {
  b <- ggplot2::ggplot_build(p)
  unlist(lapply(b$data, function(d) if (!is.null(d$label)) as.character(d$label)))
}

test_that("tick locations follow the automatic locator of common figure code", {
  expect_equal(NiceBreaks(c(0, 100), 9), seq(0, 100, 20))
  expect_equal(NiceBreaks(c(0, 150), 6), seq(0, 150, 25))
  expect_equal(NiceBreaks(c(-1.66, 0.08), 4), seq(-1.5, 0, 0.5))
  expect_equal(NiceBreaks(c(-1.4, 29.4), 3), c(0, 20))
  expect_equal(NiceBreaks(c(-0.2, 4.29), 9), seq(0, 4, 0.5))
  expect_equal(NiceBreaks(c(-3.9, 1.7), 8), -3:1)
  # "auto": axis length over twice (y) or three times (x) the tick label size
  expect_equal(NiceBreaks(c(-3.9, 82), "auto", length_pt = 51.2, tick_size = 5.5), seq(0, 75, 25))
  expect_equal(NiceBreaks(c(-2.6, 2.6), "auto", length_pt = 73.7, tick_size = 5.5, axis = "x"), c(-2, 0, 2))
  expect_equal(NiceBreaks(c(0, 7), "auto"), NiceBreaks(c(0, 7), 9))
  expect_identical(.figA_number_labels(c(-1, -0.5, 0)), c("−1.0", "−0.5", "0.0"))
  expect_equal(.figA_limits(c(0, 10)), c(-0.5, 10.5))
  expect_equal(.figA_limits(c(0, 10), list(NA, 20)), c(-0.5, 20))
})

test_that("lines are clipped at the axes and points outside are dropped", {
  d <- data.frame(x = c(0, 1, 2, 3), y = c(0, 2, 0, 2), id = "a")
  cl <- .figA_clip_path(d, c(0, 3), c(0, 1), group = "id")
  expect_true(all(cl$y <= 1 + 1e-12))
  expect_identical(length(unique(cl$piece)), 2L)
  expect_null(.figA_clip_segment(0, 5, 1, 5, c(0, 1), c(0, 1)))
  expect_equal(.figA_clip_segment(-1, 0.5, 2, 0.5, c(0, 1), c(0, 1)), c(0, 0.5, 1, 0.5))
  expect_identical(.figA_inside(c(0, 2), c(0.5, 0.5), c(0, 1), c(0, 1)), c(TRUE, FALSE))
  r <- .figA_clip_ribbon(c(0, 10, 20), c(0, 5, 10), c(5, 10, 30), c(0, 15), c(0, 20))
  expect_equal(max(r$x), 15)
  expect_equal(max(r$upper), 20)
})

test_that("marker sizes reproduce scatter areas in points", {
  expect_equal(.figA_size_filled(16) * ggplot2::.pt * 0.75, 4)
  e <- .figA_size_edged(16, 0.5)
  expect_equal(0.75 * (e$size * ggplot2::.pt + e$stroke * ggplot2::.stroke / 2), 4)
  expect_equal(0.75 * e$stroke * ggplot2::.stroke / 2, 0.5)
})

test_that("quantile curves draw bands, labels, notes and small multiples", {
  d <- data.frame(series = rep(c("a", "b"), each = 4), x = rep(c(0, 10, 20, 30), 2),
                  median = c(0, 40, 70, 90, 0, 20, 45, 70), lower = c(0, 30, 60, 85, 0, 10, 35, 60),
                  upper = c(0, 50, 80, 95, 0, 30, 55, 80), n = 5)
  p <- PlotQuantileCurves(d, lower = "lower", upper = "upper", colours = c(a = "#7B2FBE", b = "#3B7DD8"),
                          reference_x = 20, labels = c(a = "Series a", b = "Series b"), label_at = 10,
                          note = "Median and IQR\nn = {n|d} units", x_limits = c(0, 25))
  built(p)
  expect_true(all(c("Series a", "Series b", "Median and IQR\nn = 5 units") %in% layer_text(p)))
  f <- data.frame(unit = rep(c("u1", "u2", "u3", "u4"), each = 8), d[rep(1:8, 4), c("series", "x", "median")])
  fd <- data.frame(unit = c("u1", "u2", "u3", "u4"), group = c("A", "A", "B", "C"), n = c(2, 1265, 4, 30))
  p2 <- PlotQuantileCurves(f, facet = "unit", facet_ncol = 2, facet_gap_mm = c(9, 9), facet_data = fd,
                           facet_title = "{unit}", facet_note = "n = {n|comma} cells", facet_group = "group",
                           group_colours = gc3)
  b <- built(p2)
  expect_identical(length(unique(b$layout$layout$PANEL)), 4L)
  expect_true("n = 1,265 cells" %in% layer_text(p2))
  expect_error(PlotQuantileCurves(d, lower = "lower"), "both lower and upper")
})

test_that("band profiles draw empty bands at the floor and interval summaries", {
  d <- data.frame(unit = rep(c("u1", "u2", "u3"), each = 3), group = rep(c("A", "B", "A"), each = 3),
                  band = rep(c("near", "mid", "far"), 3), value = c(1, 0, -1, 2, -Inf, -2, 0.5, 0.2, -0.5))
  p <- PlotBandProfiles(d, series = "unit", x_order = c("near", "mid", "far"), floor = -3, group_colours = gc3,
                        floor_label = "none detected", reference_y = 0)
  b <- built(p)
  tri <- Filter(function(z) any(z$shape == 25), b$data)
  expect_identical(length(tri), 1L)
  expect_equal(tri[[1]]$y, -3)
  expect_error(PlotBandProfiles(d, series = "unit", x_order = c("near", "mid", "far")), "floor")
  q <- PlotDataQuantiles(data.frame(set = rep(c("s1", "s2"), each = 6), band = rep(c("near", "mid", "far"), 4),
                                    v = c(1:6, 3:8)), c("set", "band"), "v")
  built(PlotBandProfiles(q, y = "median", series = "set", lower = "lower", upper = "upper",
                         colours = c(s1 = "#7B2FBE", s2 = "#9E9E9E")))
})

test_that("interval forests, group differences and volcano plots write their statistics", {
  s <- data.frame(row = c("a", "b"), estimate = c(1, -0.5), lower = c(0.2, -1.2), upper = c(1.5, 0.1),
                  k = c(9, 7), n = 9, p = c(0.0039, 0.1))
  pts <- data.frame(row = rep(c("a", "b"), each = 5), value = c(1, 1.2, 0.4, 1.5, 0.9, -1, -0.2, 0, -0.6, -0.4),
                    low = c(TRUE, rep(FALSE, 9)), g = "A", lab = "u1")
  p <- PlotIntervalForest(s, pts, colours = c(a = "#D9730D", b = "#C2378E"), label = "{k|d}/{n|d} patients; p = {p|p}",
                          flag = "low", flag_group = "g", group_colours = gc3, flag_label = "lab",
                          row_labels = c(a = "First", b = "Second"))
  built(p)
  expect_true(all(c("9/9 patients; p = 0.0039", "7/9 patients; p = 0.1", "u1") %in% layer_text(p)))
  t <- data.frame(contrast = c("A vs B", "C vs B"), diff = c(3.2, -1.1), p = c(0.01, 0.4), q_BH = c(0.03, 0.5))
  p2 <- PlotGroupDifferences(t)
  built(p2)
  expect_true("+3.2; p = 0.01; q = 0.03" %in% layer_text(p2))
  v <- data.frame(d = c(-0.9, 0.2, 0.7, -0.1, 0.8), p = c(0.02, 0.6, 0.04, 0.9, 1e-5), name = paste("e", 1:5))
  p3 <- PlotVolcano(v, stats = data.frame(p_bound = 2 / 924), effect = "d", label = "name", top = 2)
  b <- built(p3)
  expect_true(all(c("e 5", "e 1", "Minimum attainable p = 0.0022") %in% layer_text(p3)))
  expect_false("e 3" %in% layer_text(p3))
  pts3 <- Filter(function(z) "shape" %in% names(z) && nrow(z) > 0 && all(z$shape %in% c(16, 21)), b$data)
  expect_true(all(unlist(lapply(pts3, function(z) z$y)) <= 3.2))
})

test_that("group strips, grouped scatter and bars build", {
  gs <- data.frame(group = rep(c("A", "B", "C"), c(5, 2, 4)), value = c(1:5, 2.5, 4, 3:6))
  built(PlotGroupStrip(gs, group_colours = gc3, group_labels = c(A = "a", B = "b", C = "c")))
  pl <- PlotGroupStrip(transform(gs, value = c(0, 2:5, 20, 400, 30, 60, 80, 1000)), group_colours = gc3, log_y = TRUE)
  built(pl)
  expect_true("1 at zero" %in% layer_text(pl))
  cat_d <- data.frame(cat = rep(c("k1", "k2"), each = 11), gs[c(1:11, 1:11), ])
  built(PlotGroupStrip(cat_d, category = "cat", group_colours = gc3))
  pr <- data.frame(id = rep(paste0("u", 1:4), each = 2), group = rep(c("A", "A", "B", "C"), each = 2),
                   cond = rep(c("T", "C"), 4), v = c(40, 30, 20, 25, 0, 95, 60, 40), open = rep(c(FALSE, FALSE, TRUE, FALSE), each = 2))
  p <- PlotScatterGroups(pr, x = "cond", y = "v", id = "id", group_colours = gc3, open = "open", connect = TRUE,
                         summary = TRUE, open_shift_default = 0.025, label = "id", label_only = "open", label_first = TRUE,
                         y_limits = c(-5, 90))
  built(p)
  expect_identical(layer_text(p), "u3")
  built(PlotScatterGroups(transform(pr, v = v + 1), x = "cond", y = "v", id = "id", connect = TRUE, log_y = TRUE, summary = TRUE))
  dr <- data.frame(id = paste0("p", 1:6), group = c("A", "A", "B", "B", "C", "C"), v = c(1, 5, NA, 3, 2, 8))
  p2 <- PlotScatterGroups(dr, x = "v", y = "id", id = "id", group_colours = gc3, separators = TRUE, grid = "x")
  built(p2)
  expect_true("NE" %in% layer_text(p2))
  bd <- data.frame(id = c("p1", "p2", "p3"), v = c(20, 55, 70), g = c("A", "A", "B"), n = c(4, 10, 3))
  p3 <- PlotBars(bd, x = "id", y = "v", tick_group = "g", group_colours = gc3, stats = data.frame(m = 48.4),
                 reference = "m", reference_label = "Mean, {m|f0}%", tick_angle = 50, value_limits = c(0, 100))
  built(p3)
  expect_true("Mean, 48%" %in% layer_text(p3))
  p4 <- PlotBars(bd, x = "id", y = "v", horizontal = TRUE, bar_label = "{n|d}/{v|d}", value_limits = c(0, 125))
  built(p4)
  expect_true("4/20" %in% layer_text(p4))
  st <- data.frame(id = rep(c("p1", "p2"), 2), s = rep(c("x", "y"), each = 2), v = c(10, 200, 50, 5))
  built(PlotBars(st, x = "id", y = "v", series = "s", position = "dodge", log_y = TRUE, value_limits = c(NA, 4e5),
                 stats = data.frame(a = 10), note = "Total {a|comma}"))
  b <- built(PlotBars(st, x = "id", y = "v", series = "s", position = "stack"))
  expect_equal(max(b$data[[1]]$ymax), 205)
})

test_that("text blocks and text tables are drawn on the device", {
  skip_if_not(capabilities("cairo"))
  g <- PlotTextBlock(data.frame(k = 11, n = 12, p = 0.0015), template = "{k|d}/{n|d} patients; p = {p|p}")
  expect_s3_class(g, "phenoscapR_text_block")
  expect_identical(g$lines, "11/12 patients; p = 0.0015")
  g2 <- PlotTextBlock(data.frame(a = 6), template = c("A ({a|d})", "second"), size = c(5.6, 4.6),
                      colour = c("ink", "muted"), bold = c(TRUE, FALSE))
  cells <- PlotDataTableCells(data.frame(id = c("1", "2"), a = c(3, 0), g = c("A", "B")), "id", "a", "Row")
  g3 <- PlotTextBlock(cells, layout = "table", key_colours = gc3)
  expect_error(PlotTextBlock(), "text or a template")
  dir <- withr::local_tempdir()
  fig <- ComposeFigure(list(FigurePanel(g, c(10, 10, 40, 3), heading = "Heading"),
                            FigurePanel(g2, c(10, 20, 40, 6)), FigurePanel(g3, c(10, 30, 60, 10))),
                       height_mm = 50, width_mm = 90)
  SaveFigure(fig, png = file.path(dir, "t.png"), dpi = 100)
  expect_gt(file.size(file.path(dir, "t.png")), 1000)
})

test_that("registered grammar names render from a specification", {
  skip_if_not(capabilities("cairo"))
  d <- data.frame(group = rep(c("A", "B"), each = 3), value = c(1, 2, 3, 2, 3, 5))
  s <- data.frame(k = 3, n = 3, p = 0.25)
  spec <- list(height_mm = 60, width_mm = 90,
               panels = list(list(box = c(15, 15, 30, 30), letter = "a", grammar = "group_strip", data = "values",
                                  args = list(group_colours = list(A = "groups/group1", B = "groups/group2"))),
                             list(box = c(15, 11, 30, 2), heading = "Strip", grammar = "text_block", data = "stat",
                                  args = list(template = "{k|d}/{n|d}; p = {p|p}", colour = "muted"))))
  fig <- RenderFigure(spec, list(values = d, stat = s))
  expect_s3_class(fig, "phenoscapR_figure")
  own <- c("quantile_curves", "band_profiles", "interval_forest", "group_strip", "group_differences", "volcano",
           "scatter_groups", "bars", "text_block")
  for (g in own) expect_true(is.function(get(FigureGrammars()[[g]], envir = asNamespace("phenoscapR"))))
})

test_that("grouped scatter writes a corner note from summary data", {
  d <- data.frame(id = paste0("u", 1:4), group = c("A", "A", "B", "C"), x = c(1, 2, 3, 4), y = c(2, 1, 4, 3))
  p <- PlotScatterGroups(d, id = "id", group_colours = gc3, stats = data.frame(rho = 0.6, p = 0.42),
                         note = "Spearman's rho = {rho|f2}\np = {p|p}")
  built(p)
  expect_true("Spearman's rho = 0.60\np = 0.42" %in% layer_text(p))
})
