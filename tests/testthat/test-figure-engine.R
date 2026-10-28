# Figure engine options: typesetting switches, straight quotes, legends,
# baseline text, box sizes for grammars and the extended grammar options.

draw_page <- function(fig, env = parent.frame()) {
  f <- withr::local_tempfile(fileext = ".png", .local_envir = env)
  SaveFigure(fig, png = f, dpi = 120)
  expect_gt(file.size(f), 1000)
  invisible(f)
}

test_that("every save measures rich text afresh", {
  skip_if_not_installed("gridtext")
  cache <- utils::getFromNamespace("text_info_cache", "gridtext")
  assign("left over from an earlier figure", list(width_pt = 1, ascent_pt = 1), envir = cache)
  fig <- ComposeFigure(list(FigurePanel(NULL, c(10, 10, 40, 20), letter = "a",
                                        heading = "Cell territories in tissue")),
                       height_mm = 40, width_mm = 60)
  draw_page(fig)
  expect_false(exists("left over from an earlier figure", envir = cache, inherits = FALSE))
  expect_gt(length(ls(cache)), 0L)
})

test_that("typesetting keeps straight quotes and can be switched off by rule or entirely", {
  rich <- TypesetLabel(c("Spearman's rho", "patient's \"cells\" -- a ... b", "p ≥ 0.05", "P"), rich = TRUE)
  expect_identical(rich[1], "Spearman&#39;s rho")
  expect_identical(rich[2], "patient&#39;s &quot;cells&quot; -&#45; a &#46;&#46;&#46; b")
  expect_identical(rich[3], "<i>P</i> ≥ 0.05")
  expect_identical(rich[4], "<i>P</i>")
  withr::with_options(list(phenoscapR.typeset = FALSE), {
    expect_identical(TypesetLabel("Treg-like, p = 0.01\nlog2", rich = TRUE), "Treg-like, p = 0.01<br>log2")
    expect_identical(TypesetLabel("Treg cells", rich = FALSE), "Treg cells")
  })
  withr::with_options(list(phenoscapR.typeset = "treg"), {
    expect_identical(TypesetLabel("Treg-like; p = 0.01; log2", rich = TRUE), "Treg-like; <i>P</i> = 0.01; log<sub>2</sub>")
  })
  expect_identical(.fig_typeset_value(list(off = list("treg", "p"))), c("treg", "p"))
  expect_identical(.fig_typeset_value(NULL, FALSE), FALSE)
  expect_identical(.fig_with_typeset(FALSE, getOption("phenoscapR.typeset")), FALSE)
  expect_true(isTRUE(getOption("phenoscapR.typeset", TRUE)))
})

test_that("legend keys fill rows or columns, take marker sizes and all key shapes", {
  skip_if_not(capabilities("cairo"))
  dev <- withr::local_tempfile(fileext = ".png")
  grDevices::png(dev, type = "cairo")
  withr::defer(grDevices::dev.off())
  labs <- c("first", "second", "third", "fourth", "fifth")
  old <- LegendKeys(labs, "#123456", ncol = 2)
  lay <- .fig_legend_layout(old)
  expect_identical(lay$col_of, c(1L, 2L, 1L, 2L, 1L))
  col <- LegendKeys(labs, "#123456", ncol = 2, byrow = FALSE, marker_size = 4, row_mm = 3, text_gap_mm = 0.4,
                    column_gap_mm = 2, shape = c("point", "open", "diamond", "patch", "square"))
  lay2 <- .fig_legend_layout(col)
  expect_identical(lay2$col_of, c(1L, 1L, 1L, 2L, 2L))
  expect_identical(lay2$row_of, c(1L, 2L, 3L, 1L, 2L))
  expect_equal(lay2$row_h, 3)
  expect_error(LegendKeys("a", "red", shape = "star"), "Unknown key shape")
  fig <- ComposeFigure(list(), height_mm = 30, width_mm = 60,
                       texts = list(FigureGrob(col, c(2, 2)), FigureGrob(old, c(30, 2)),
                                    FigureGrob(LegendKeys("line", "#222222", shape = "pointline", linewidth = 1.1),
                                               c(2, 20))))
  draw_page(fig)
})

test_that("figure texts can sit on their baseline and skip typesetting", {
  skip_if_not(capabilities("cairo"))
  t <- FigureText("Treg-like cells", c(5, 10), vjust = "baseline", typeset = FALSE)
  expect_identical(t$vjust, "baseline")
  expect_false(t$typeset)
  expect_error(FigureText("a", c(1, 1), vjust = "top"), "baseline")
  skip_if_not_installed("ragg")
  dev <- withr::local_tempfile(fileext = ".png")
  ragg::agg_png(dev, res = 100)
  expect_gt(.fig_descent_mm(6, "DejaVu Sans"), 0)
  grDevices::dev.off()
  fig <- ComposeFigure(list(FigurePanel(NULL, c(5, 5, 20, 10), heading = "Treg-like", typeset = FALSE)),
                       height_mm = 30, width_mm = 60, texts = list(t, FigureText("p = 0.01", c(5, 20), vjust = "baseline")))
  draw_page(fig)
})

test_that("specifications pass box sizes, typesetting switches and legend layouts", {
  skip_if_not(capabilities("cairo"))
  d <- data.frame(group = rep(c("A", "B"), each = 4), value = c(1, 3, 7, 82, 2, 4, 6, 9))
  spec <- list(height_mm = 60, width_mm = 90, typeset = list(off = list("treg")),
               panels = list(list(box = c(15, 10, 30, 18), grammar = "group_strip", data = "d", heading = "Treg cells",
                                  args = list(y_nbins = "auto", seed = 1))),
               texts = list(list(label = "Treg-like", at = c(50, 20), vjust = "baseline", typeset = TRUE)),
               legends = list(list(labels = c("A", "B"), colours = c("groups/group1", "groups/group2"), ncol = 2,
                                   size = 5, xy = c(0.6, 0.9), mpl = list(markersize = 3.5, loc = "upper right")),
                              list(labels = c("x", "y", "z"), colours = "ink", shape = "patch", ncol = 2, byrow = FALSE,
                                   at = c(50, 40))))
  fig <- RenderFigure(spec, list(d = d))
  expect_identical(fig$panels[[1]]$typeset, "treg")
  b <- ggplot2::ggplot_build(fig$panels[[1]]$plot)
  expect_equal(b$layout$panel_params[[1]]$y$breaks[!is.na(b$layout$panel_params[[1]]$y$breaks)], c(0, 25, 50, 75))
  l <- .fig_mpl_legend(list(size = 5, mpl = list(loc = "upper right", markersize = 3.5)), ManuscriptStyle())
  expect_equal(l$marker_size, 4.5)
  expect_identical(l$hjust, 1)
  expect_false(l$byrow)
  draw_page(fig)
})

test_that("grammar options for references, ties, colours, open markers, bar labels and rule tables", {
  skip_if_not(capabilities("cairo"))
  k <- data.frame(k = rep(4:8, 2), v = c(5:1, 6:2), a = rep(c("main", "all"), each = 5))
  p <- PlotScatterGroups(k, x = "k", y = "v", group = "a", id = "a", connect = TRUE,
                         group_colours = c(main = "#222222", all = "#8A8A8A"),
                         reference = data.frame(n = c(6, 7), a = c("main", "all")), reference_x = "n",
                         reference_group = "a", y_nbins = "auto", box_mm = c(30, 30))
  b <- ggplot2::ggplot_build(p)
  vl <- b$data[vapply(b$data, function(d) "xintercept" %in% names(d), logical(1))][[1]]
  expect_equal(vl$xintercept, c(6, 7))
  expect_identical(vl$colour, c("#222222", "#8A8A8A"))
  tie <- data.frame(id = c("p2", "p4", "p7", "p5"), g = c("A", "A", "B", "C"), x = c("0", "0", "1", "8"),
                    y = c(0, 0, 0, 0.2), short = c("2", "4", "7", "5"))
  pt <- PlotScatterGroups(tie, x = "x", y = "y", group = "g", id = "id", x_order = c("0", "1", "8"), label = "short",
                          ties = TRUE, group_colours = c(A = "#009E73", B = "#D55E00", C = "#0072B2"))
  bt <- ggplot2::ggplot_build(pt)
  labs <- unlist(lapply(bt$data, function(d) if (!is.null(d$label)) as.character(d$label)))
  expect_setequal(labs, c("2, 4", "7", "5"))
  pts <- bt$data[[which(vapply(bt$data, function(d) "shape" %in% names(d) && !"label" %in% names(d), logical(1)))[1]]]
  expect_equal(sort(pts$x[pts$y == 0])[1:2], c(1 - 0.08, 1 + 0.08))
  s <- PlotGroupStrip(data.frame(geno = rep(c("x", "y"), each = 3), v = 1:6, clin = c("U", "R", "U", "R", "U", "U")),
                      value = "v", group = "geno", colour_by = "clin", point_colours = c(U = "#009E73", R = "#0072B2"))
  sb <- ggplot2::ggplot_build(s)
  expect_setequal(unique(sb$data[[1]]$colour), c("#009E73", "#0072B2"))
  t <- data.frame(endpoint = c("e1", "e2", "e3"), d = c(0.7, -0.2, -0.8), p = c(0.02, 0.4, 0.03))
  gd <- PlotGroupDifferences(t, row = "endpoint", estimate = "d", q = "p", marker = "open", label = "{p|p}",
                             label_title = "P", x_limits = c(-1.08, 1.08), y_limits = c(0.3, 3.7), grid = "x",
                             significant_colour = "ink")
  gb <- ggplot2::ggplot_build(gd)
  # one open (P >= 0.05) and two filled points, three segments
  expect_true(all(c(1L, 2L, 3L) %in% vapply(gb$data, nrow, integer(1))))
  expect_equal(gb$layout$panel_params[[1]]$x.range, c(-1.08, 1.08))
  sbar <- PlotStackedBars(data.frame(x = rep(c("p1", "p2"), each = 2), stack = rep(c("a", "b"), 2), value = c(1, 2, 5, 9),
                                     k = rep(c(27.081, 85.18), each = 2)),
                          top_text = "k", top_format = "%.0fk", top_offset = 0.35, nbins = 9)
  sbb <- ggplot2::ggplot_build(sbar)
  tops <- sbb$data[[which(vapply(sbb$data, function(d) "label" %in% names(d), logical(1)))[1]]]
  expect_identical(tops$label, c("27k", "85k"))
  expect_equal(tops$y, c(3.35, 14.35))
  hb <- PlotBars(data.frame(s = c("a", "b"), v = c(58770, 3444)), x = "s", y = "v", series = "s", horizontal = TRUE,
                 bar_label = "{v|comma}", bar_label_d = 0, bar_label_scale = 0.03, value_expand = 1.35,
                 value_breaks = c(0, 20000, 40000, 60000), value_labels = c("0", "20k", "40k", "60k"))
  hbb <- ggplot2::ggplot_build(hb)
  expect_equal(hbb$layout$panel_params[[1]]$x.range, c(0, 58770 * 1.35))
  expect_identical(hbb$layout$panel_params[[1]]$x$get_labels(), c("0", "20k", "40k", "60k"))
  cells <- PlotDataTableCells(data.frame(a = c("A", "B"), s = c(0.47, 0.36), p = c(0.018, 1)), "a",
                              row_labels = c("Score", "Test"), templates = c("{s|f2}", "p = {p|p}"))
  expect_identical(cells$label, c("", "A", "B", "Score", "0.47", "0.36", "Test", "p = 0.018", "p = 1"))
  tb <- PlotTextBlock(cells, layout = "table", borders = "rules", align = "left", widths = c(0.5, 0.25, 0.25))
  fig <- ComposeFigure(list(FigurePanel(p, c(10, 5, 30, 20)), FigurePanel(pt, c(50, 5, 30, 20)),
                            FigurePanel(gd, c(100, 5, 30, 20)), FigurePanel(tb, c(10, 40, 80, 20), fill_box = TRUE),
                            FigurePanel(hb, c(110, 40, 20, 20))),
                       height_mm = 70, width_mm = 140)
  draw_page(fig)
})
