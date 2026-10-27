test_that("the manuscript style can be read and partly overridden", {
  s <- ManuscriptStyle()
  expect_s3_class(s, "phenoscapR_style")
  expect_identical(s$family, "DejaVu Sans")
  expect_identical(s$size$letter, 8)
  t <- ManuscriptStyle(size = list(base = 7), page = list(dpi = 300))
  expect_identical(t$size$base, 7)
  expect_identical(t$size$letter, 8)
  expect_identical(t$page$dpi, 300)
  expect_error(ManuscriptStyle(size = list(huge = 3)), "Unknown size")
  expect_error(ManuscriptStyle(nonsense = 1), "named entries")
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", unlist(ManuscriptPalettes()))))
  expect_equal(PtLinewidth(0.75 * ggplot2::.pt), 1)
})

test_that("P values follow the two-digit and power-of-ten rule", {
  expect_identical(
    FormatP(c(0.0039, 0.055, 0.5, 0.001, 4.9e-4, 1e-10, NA, Inf)),
    c("0.0039", "0.055", "0.5", "0.001", "4.9e-04", "1.0e-10", "n.e.", "n.e.")
  )
  expect_error(FormatP("0.1"), "numeric")
  expect_identical(FormatStatistic(0.0015, k = 11, n = 12), "11/12 patients; p = 0.0015")
  expect_identical(FormatStatistic(0.021, q = 0.18, estimate = -3.42), "−3.4; p = 0.021; q = 0.18")
  expect_identical(FormatStatistic(NA_real_, k = 0, n = 0, unit = ""), "0/0; p = n.e.")
  expect_error(FormatStatistic(0.1, k = 3), "both")
})

test_that("labels are typeset as rich text or plain Unicode", {
  rich <- TypesetLabel(c("p = 4.9e-04; q < 0.05", "Tregs and CD8+ cells, CD4 T", "log2 (mm2), 20 um, TP53",
                         "A\nB", NA), rich = TRUE)
  expect_identical(rich[1], "<i>P</i> = 4.9 × 10<sup>−4</sup>; <i>q</i> &lt; 0.05")
  expect_identical(rich[2], "T<sub>reg</sub> cells and CD8<sup>+</sup> cells, CD4<sup>+</sup> T")
  expect_identical(rich[3], "log<sub>2</sub> (mm<sup>2</sup>), 20 µm, <i>TP53</i>")
  expect_identical(rich[4], "A<br>B")
  expect_true(is.na(rich[5]))
  plain <- TypesetLabel(c("p = 4.9e-04", "CD8+ T", "log2 mm2"), rich = FALSE)
  expect_identical(plain, c("P = 4.9 × 10⁻⁴", "CD8⁺ T", "log₂ mm²"))
  expect_error(TypesetLabel(1), "character")
})

test_that("figures are composed on an exact page and written as PDF and PNG", {
  skip_if_not(capabilities("cairo"))
  d <- data.frame(patient = rep(c("p1", "p2", "p3"), each = 2), group = rep(c("A", "B", "A"), each = 2),
                  condition = rep(c("x", "y"), 3), value = c(3, 5, 2, 6, 4, 4.5),
                  excluded = rep(c(FALSE, FALSE, TRUE), each = 2))
  p <- PlotPairedPatients(d, excluded = "excluded", group_colours = c(A = "#009E73", B = "#0072B2"),
                          y_label = "Median distance (um)")
  expect_s3_class(p, "ggplot")
  fig <- ComposeFigure(
    list(FigurePanel(p, c(15, 12, 40, 30), letter = "a", heading = "Paired values",
                     note = FormatStatistic(0.03, k = 2, n = 2)),
         FigurePanel(NULL, c(70, 12, 20, 20), letter = "b")),
    height_mm = 60, width_mm = 100,
    texts = list(FigureText("n = 3 patients", c(70, 40)),
                 FigureGrob(LegendKeys(c("A", "B"), c("#009E73", "#0072B2"), shape = "pointline"), c(15, 50)))
  )
  expect_s3_class(fig, "phenoscapR_figure")
  dir <- withr::local_tempdir()
  SaveFigure(fig, pdf = file.path(dir, "f.pdf"), png = file.path(dir, "f.png"), dpi = 100)
  expect_gt(file.size(file.path(dir, "f.pdf")), 1000)
  expect_gt(file.size(file.path(dir, "f.png")), 1000)
  if (requireNamespace("png", quietly = TRUE)) {
    img <- png::readPNG(file.path(dir, "f.png"))
    expect_equal(dim(img)[2], round(100 / 25.4 * 100), tolerance = 1)
  }
  expect_error(FigurePanel("x", c(1, 1, 1, 1)), "ggplot")
  expect_error(FigurePanel(NULL, c(1, 1, 0, 1)), "box")
  expect_error(ComposeFigure(list(1), 10), "FigurePanel")
  expect_error(SaveFigure(fig), "output path")
})

test_that("specifications resolve grammars, data and colour references", {
  skip_if_not(capabilities("cairo"))
  d <- data.frame(patient = rep(c("p1", "p2"), each = 2), group = "g1", condition = rep(c("x", "y"), 2),
                  value = c(1, 2, 2, 3))
  spec <- list(
    height_mm = 50, width_mm = 80,
    panels = list(list(box = c(15, 10, 40, 30), letter = "a", heading = "Spec panel",
                       grammar = "paired_patients", data = "values",
                       args = list(group_colours = c(g1 = "groups/group1")))),
    texts = list(list(label = "note", at = c(60, 20), colour = "muted")),
    legends = list(list(labels = c("Group 1"), colours = c("groups/group1"), at = c(15, 45)))
  )
  fig <- RenderFigure(spec, list(values = d))
  expect_s3_class(fig, "phenoscapR_figure")
  expect_identical(.fig_colour(c("groups/group1", "ink", "#123456"), ManuscriptStyle()),
                   c("#009E73", "#222222", "#123456"))
  expect_identical(.fig_colour(c(a = "groups/group2"), ManuscriptStyle()), c(a = "#D55E00"))
  expect_error(.fig_colour("nopalette/x", ManuscriptStyle()), "Unknown colour")
  bad <- spec
  bad$panels[[1]]$grammar <- "nothing"
  expect_error(RenderFigure(bad, list(values = d)), "Unknown grammar")
  bad <- spec
  bad$panels[[1]]$data <- "absent"
  expect_error(RenderFigure(bad, list(values = d)), "missing data")
  dir <- withr::local_tempdir()
  utils::write.table(d, file.path(dir, "v.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
  WriteFigure(spec, list(values = file.path(dir, "v.tsv")), pdf = file.path(dir, "s.pdf"),
              png = file.path(dir, "s.png"))
  expect_true(file.exists(file.path(dir, "s.pdf")))
  expect_true(all(names(FigureGrammars()) != ""))
})

test_that("page fractions and split specification files are accepted", {
  skip_if_not(capabilities("cairo"))
  dir <- withr::local_tempdir()
  d <- data.frame(patient = rep(c("p1", "p2"), each = 2), group = "g1", condition = rep(c("x", "y"), 2),
                  value = c(1, 2, 2, 3))
  jsonlite::write_json(list(height_mm = 100, width_mm = 100), file.path(dir, "00-page.json"), auto_unbox = TRUE)
  jsonlite::write_json(list(panels = list(list(axes = c(0.1, 0.5, 0.4, 0.3), letter = "a", letter_xy = c(0.01, 0.99),
                                               grammar = "paired_patients", data = "values"))),
                       file.path(dir, "10-a.json"), auto_unbox = TRUE)
  jsonlite::write_json(list(texts = list(list(label = "x", xy = c(0.5, 0.5)))), file.path(dir, "20-b.json"),
                       auto_unbox = TRUE)
  fig <- RenderFigure(dir, list(values = d))
  expect_equal(fig$panels[[1]]$box, c(10, 20, 40, 30))
  expect_equal(fig$panels[[1]]$letter_at, c(1, 1))
  expect_equal(fig$texts[[1]]$at, c(50, 50))
  expect_error(RenderFigure(file.path(dir, "absent.json")), "not found")
})
