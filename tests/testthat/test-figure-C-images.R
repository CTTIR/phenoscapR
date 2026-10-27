# Image-type plot data and grammars on synthetic cells and images.

synthetic_cells <- function(n = 400, seed = 1) {
  set.seed(seed)
  data.frame(row = seq_len(n) - 1L, x = stats::runif(n, 0, 200), y = stats::runif(n, 0, 200),
             label = sample(c("tum", "a", "b", "c"), n, TRUE, prob = c(.4, .3, .2, .1)),
             stringsAsFactors = FALSE)
}

brute_nearest <- function(px, py, qx, qy) {
  vapply(seq_along(qx), function(i) min(sqrt((px - qx[i])^2 + (py - qy[i])^2)), numeric(1))
}

test_that("per-cell arrays become a table with masked columns and kept rows", {
  a <- list(x = c(1, 2, 3, 4), y = c(5, 6, 7, 8), lab = c("p", "q", "p", "q"), keep = c(TRUE, FALSE, TRUE, TRUE),
            cls = c(9L, 7L), has = c(FALSE, TRUE, FALSE, TRUE), mat = matrix(1:8, 4))
  d <- CellTableFromArrays(a, list(x = "x", y = "y", label = "lab", cls = "cls"), masked = list(cls = "has"), keep = "keep")
  expect_identical(d$row, c(0L, 2L, 3L))
  expect_identical(d$cls, c(NA, NA, 7L))
  expect_identical(names(d), c("x", "y", "label", "cls", "row"))
  expect_error(CellTableFromArrays(a, list(m = "mat")), "one-dimensional")
  expect_error(CellTableFromArrays(a, list(z = "absent")), "lack")
  expect_error(CellTableFromArrays(a, list(cls = "cls"), masked = list(cls = "keep")), "mask")
})

test_that("nearest-label distances equal a brute-force search", {
  d <- synthetic_cells()
  out <- NearestLabelDistance(d, "tum", column = "dt")
  t <- d$label == "tum"
  expect_equal(out$dt[!t], brute_nearest(d$x[t], d$y[t], d$x[!t], d$y[!t]))
  expect_true(all(out$dt[t] == 0))
  own <- NearestLabelDistance(d, "tum", column = "dt", self = NULL)
  i <- which(t)[1]
  expect_equal(own$dt[i], min(sqrt((d$x[t][-1] - d$x[i])^2 + (d$y[t][-1] - d$y[i])^2)))
})

test_that("map fields, interface zones, grid snapping and classes", {
  d <- synthetic_cells()
  m <- CellMapData(d, centre = c(100, 100), size = 60, interface = list(labels = "tum", radius = 8, step = 2),
                   classes = list(column = "label", map = list(tum = "tumour", a = "other"), default = "rest"))
  expect_s3_class(m, "phenoscapR_cellmap")
  expect_true(all(abs(m$cells$x - 100) < 30 & abs(m$cells$y - 100) < 30))
  expect_identical(sort(unique(m$cells$class)), c("other", "rest", "tumour"))
  t <- d$label == "tum"
  dz <- brute_nearest(d$x[t], d$y[t], m$interface$x, m$interface$y)
  expect_true(all(dz <= 8))
  g <- seq(70, 130, by = 2)
  grid <- expand.grid(x = g, y = g)
  inside <- brute_nearest(d$x[t], d$y[t], grid$x, grid$y) <= 8
  expect_identical(nrow(m$interface), sum(inside))
  expect_equal(m$extent, c(70, 130, 70, 130))
  c1 <- CellMapData(d, centre_cell = 5, size = 20)
  expect_equal(c1$centre, c(d$x[6], d$y[6]))
  snap <- FieldCentre(d, centre = c(101, 57), grid = list(step = 10, offset = 5))
  o <- c(min(d$x), min(d$y)) + 5
  expect_equal(c(snap$x, snap$y), o + round((c(101, 57) - o) / 10) * 10)
  expect_equal(FieldCentre(d, centre_cell = 0, offset = c(1, -1), size = 9)$size, 9)
  whole <- CellMapData(d)
  expect_equal(whole$extent, c(range(d$x), range(d$y)))
  expect_error(CellMapData(d, interface = list(labels = "tum")), "field size")
})

test_that("window, partner and ranking helpers follow their rules", {
  d <- data.frame(x = c(1, 2, 15, 16, 17, 31, 32, 33), y = c(1, 2, 5, 6, 7, 1, 1, 2), cn = c(0, 0, 1, 1, NA, 2, 2, 2))
  w <- DensestGridWindow(d, 10)
  expect_identical(c(w$x0, w$y0, w$n), c(10, 0, 3))   # tie (3 cells) resolved by the smaller x index
  w2 <- DensestGridWindow(d, 10, filter = list(cn = c(0, 1, 2)))
  expect_identical(c(w2$x0, w2$n), c(30, 3))
  cells <- data.frame(row = 0:5, x = c(0, 4, 10, 30, 13, 50), y = 0, label = c("f", "p", "f", "p", "p", "f"))
  pr <- NearestPartnerPairs(cells, c(2, 0), "p")
  expect_identical(pr$partner_id, c(4L, 1L))
  expect_equal(pr$distance, c(3, 4))
  expect_equal(pr$mid_x, c(11.5, 2))
  expect_error(NearestPartnerPairs(cells, 99, "p"), "Unknown")
  rk <- FieldCellsRanked(cells, c(10, 0), half = 15, labels = c("f", "p"), order_by = "x", n = 3)
  expect_identical(rk$row, c(0L, 1L, 2L))
  set.seed(4)
  e <- data.frame(x = runif(300, 0, 100), y = runif(300, 0, 100), lab = sample(c("u", "v"), 300, TRUE),
                  d = runif(300, 0, 40))
  b <- BestSubWindow(e, c(50, 50), 100, 30, filter = list(lab = "u"), ranges = list(d = c(0, 20)), step = 10)
  g <- seq(-35, 35, by = 10)
  best <- -1
  for (gy in g) for (gx in g) {
    n <- sum(e$lab == "u" & e$d <= 20 & abs(e$x - (50 + gx)) <= 15 & abs(e$y - (50 + gy)) <= 15)
    if (n > best) { best <- n; bx <- gx; by <- gy }
  }
  expect_identical(c(b$dx, b$dy, b$n), c(bx, by, best))
})

test_that("territory tiles are capped Voronoi cells with classes and drawing order", {
  skip_if_not_installed("deldir")
  d <- synthetic_cells(300)
  tt <- TerritoryTiles(d, c(100, 100), 80, cap = 6, classes = list(tumour = "tum", b = "b"))
  expect_s3_class(tt, "phenoscapR_territories")
  tiles <- tt$tiles
  expect_true(all(tiles$class %in% c("tumour", "b", "other")))
  first <- tiles[!duplicated(tiles$tile), ]
  rank <- match(first$class, c("other", "tumour"))
  rank[is.na(rank)] <- 3
  expect_false(is.unsorted(rank))
  # every vertex lies within the cap of its cell
  pts <- split(tiles, tiles$tile)
  cx <- vapply(pts, function(p) mean(p$x), numeric(1))
  expect_true(all(vapply(pts, function(p) max(sqrt((p$x - mean(p$x))^2 + (p$y - mean(p$y))^2)), numeric(1)) <= 12 + 1e-9))
  expect_gt(length(cx), 50)
})

test_that("composites follow the display-level rules and overlays", {
  img <- matrix(c(0, 50, 100, 150), 2)
  f <- list(channels = list(A = img, B = img * 2), centre = c(1, 1), size = 2, row = data.frame(source = "s1", m = "B"))
  slide <- data.frame(channel = c("A", "B"), lo = c(0, 0), hi = c(100, 200), source = "s1")
  levels <- data.frame(channel = "A", lo = 50, hi = 150)
  out <- CompositeFields(list(f), views = list(
    v1 = list(list(channel = "A", colour = c(1, 0, 0), lo = "slide", hi = "slide")),
    v2 = list(list(column = "m", colour = c(0, 1, 0), lo = "slide", hi = "slide*0.5")),
    v3 = list(list(channel = "A", colour = "#0000FF", lo = "levels", hi = c("levels", "q0.5"))),
    v4 = list(list(channel = "A", colour = c(1, 1, 1), lo = "q0", hi = "q1"),
              list(channel = "B", colour = c(1, 0, 0), lo = "slide", hi = "slide", overlay = TRUE))),
    slide = slide, levels = levels, source = "source", gamma = 1)
  expect_s3_class(out, "phenoscapR_images")
  expect_identical(out$info$view, c("v1", "v2", "v3", "v4"))
  expect_equal(out$images[[1]][, , 1], pmin(img / 100, 1))
  expect_equal(out$images[[2]][, , 2], pmin(img * 2 / 100, 1))
  expect_equal(out$images[[3]][, , 3], pmin(pmax((img - 50) / 100, 0), 1))
  expect_equal(out$images[[4]][2, 2, ], c(1, 0, 0))
  expect_error(CompositeFields(list(f), list(v = list(list(channel = "Z", colour = "red")))), "lacks channel")
  expect_error(CompositeFields(list(f), list(v = list(list(channel = "A", colour = "red", lo = "levels")))), "levels")
})

test_that("labels, shares, bindings, recoding and position lookup", {
  d <- data.frame(p = c("a", "b"), n = c(27081, 85180), g = c("T-A x", "T-B"), s = c(10, 20))
  lab <- PlotDataLabels(d, "{n}k cells; {g}", formats = list(n = "%.0f"), scales = list(n = 0.001),
                        recode = list(g = list("^T-A" = "first", ".*" = "other")), id = "p")
  expect_identical(lab$text, c("27k cells; first", "85k cells; other"))
  expect_equal(PlotDataShares(d, "n", "s", scale = 1)$n, d$n / d$s)
  b <- PlotDataBind(list(d[1, ], d[2, ]), names_to = "src", labels = c("x", "y"))
  expect_identical(b$src, c("x", "y"))
  r <- MapColumnValues(d, "p", list(a = "A"), to = "q", default = ".keep")
  expect_identical(r$q, c("A", "b"))
  ref <- data.frame(img = c("i2", "i1"), row = c(1, 0))
  cells <- list(data.frame(row = 0:1, x = c(1, 2), y = c(3, 4), label = c("u", "v")),
                data.frame(row = 0:1, x = c(5, 6), y = c(7, 8), label = c("w", "z")))
  pos <- CellPositionsFor(ref, cells, labels = c("i1", "i2"), source = "img")
  expect_identical(pos$label, c("z", "u"))
  expect_equal(pos$x, c(6, 1))
  expect_error(CellPositionsFor(data.frame(img = "i9", row = 0), cells, labels = c("i1", "i2"), source = "img"), "No cell table")
})

test_that("schematics fill placeholders from data and lay out flows", {
  v <- data.frame(id = c("a", "b", "c"), grp = c("x", "y", "x"), n = c(1e6, 2e6, 3e5))
  s <- SchematicShapes(flow = list(labels = c("{k} items ({kx} x)", "{tot} M"), x0 = 0, width = 1, gap = 0.5, y = 0.5,
                                   height = 0.8, fill = "#FFFFFF", colour = "#000000", text_size = 5, arrow_gap = c(0, 0),
                                   arrow_colour = "#000000", arrow_linewidth = 0.5, arrow_head = 6),
                       values = v, fill = list(k = list(column = "id", fun = "n", format = "%.0f"),
                                               kx = list(column = "id", fun = "n", format = "%.0f", filter = list(grp = "x")),
                                               tot = list(column = "n", fun = "sum", scale = 1e-6, format = "%.1f")),
                       clouds = list(list(n = 5, x = 0, y = 0, rx = 1, ry = 1, r = 0.1, fill = "#FF0000")),
                       xlim = c(0, 3), ylim = c(0, 1), equal = FALSE, seed = 2)
  expect_s3_class(s, "phenoscapR_shapes")
  expect_true("3 items (2 x)" %in% s$shapes$label)
  expect_true("3.3 M" %in% s$shapes$label)
  expect_identical(sum(s$shapes$type == "arrow"), 1L)
  expect_identical(sum(s$shapes$type == "circle"), 5L)
  s2 <- SchematicShapes(clouds = list(list(n = 5, x = 0, y = 0, rx = 1, ry = 1, r = 0.1, fill = "#FF0000")), seed = 2)
  expect_identical(s2$shapes$x, s$shapes$x[s$shapes$type == "circle"])
})

test_that("image grammars are registered and draw on a composed page", {
  skip_if_not(capabilities("cairo"))
  skip_if_not_installed("ragg")
  g <- FigureGrammars()
  expect_identical(unname(g[c("cell_map", "territories", "fluorescence_field", "image")]),
                   c("PlotCellMap", "PlotTerritories", "PlotFluorescenceField", "PlotImage"))
  d <- NearestLabelDistance(synthetic_cells(), "tum", "dtum")
  m <- CellMapData(d, centre = c(100, 100), size = 80, interface = list(labels = "tum", radius = 6, step = 2))
  p1 <- PlotCellMap(m, layers = list(list(values = "tum", colour = "subsets/tumour", size = 2.5, z = 2),
                                     list(values = "b", colour = "subsets/treg", size = 16, z = 4)),
                    scale_bar = list(length = 20, label = "20 um"), label = "Field", label_colour = "ink",
                    boxes = data.frame(x = 100, y = 100), box_size = 20, point_extra = 0.05)
  whole <- CellMapData(d, classes = list(column = "label", map = list(tum = "tumour"), default = "unassigned"))
  p2 <- PlotCellMap(whole, layers = list(list(column = "class", values = c("tumour", "unassigned"),
                                              colour = list(tumour = "coarse/tumour", unassigned = "coarse/unassigned"), size = .5)),
                    rest = NULL, frame = FALSE, expand = 0.05, title = "P1", subtitle = "400 cells",
                    scale_bar = list(length = 50, label = "50 um", x = 0, y = -0.03, label_offset = -0.015, relative_to = "data"))
  p3 <- PlotTerritories(TerritoryTiles(d, c(100, 100), 60, classes = list(tumour = "tum")),
                        colours = list(tumour = "subsets/tumour_territory", other = "subsets/other_territory"),
                        boxes = data.frame(x = 90, y = 90, colour = "#7B2FBE"), box_size = 20, title = "Group")
  fld <- list(channels = list(A = matrix(stats::runif(400, 0, 100), 20), B = matrix(stats::runif(400, 0, 100), 20)),
              centre = c(10, 10), size = 10)
  marks <- data.frame(x = 9, y = 9, partner_x = 12, partner_y = 11, distance = 3.6)
  p4 <- PlotFluorescenceField(fld, layers = list(list(channel = "A", colour = "fluorescence/cd3e", lo = "q0.01", hi = "q0.99"),
                                                 list(channel = "B", colour = "fluorescence/foxp3", lo = "q0.5", hi = "q1",
                                                      overlay = TRUE)),
                              marks = marks, arrow = list(tip = -1, tail = -4), cross = list(),
                              corner_text = list(column = "distance", format = "%.0f um"),
                              scale_bar = list(length = 5, label = "5 um"))
  imgs <- CompositeFields(lapply(1:4, function(i) c(fld, list(row = data.frame(grp = c("r1", "r1", "r2", "r9")[i], who = paste0("P", i))))),
                          views = list(m = list(list(channel = "A", colour = "#FFFFFF", lo = "q0", hi = "q1")),
                                       n = list(list(channel = "B", colour = "#FF00FF", lo = "q0", hi = "q1"))))
  p5 <- PlotImage(imgs, row = "grp", row_levels = c("r1", "r2"), tile_mm = 8, column_labels = c("M", "N"),
                  row_labels = list(list(column = "grp", x_mm = -10, size = 5)), corner = list(column = "who", view = "m"),
                  scale_bar = list(length = 5, pixel_size = 0.5, view = "m"), title = "Rows (n = {n} of {total})",
                  total = data.frame(a = 1:7))
  p6 <- PlotImage(SchematicShapes(shapes = list(list(type = "roundrect", x = .5, y = .5, w = .8, h = .5, fill = "#EEEEEE",
                                                     colour = "#999999", r = 1),
                                                list(type = "text", x = .5, y = .5, label = "Box"),
                                                list(type = "arrow", x = .1, y = .1, xend = .9, yend = .1, colour = "#000000"))))
  p7 <- PlotImage(array(stats::runif(300), c(10, 10, 3)))
  for (p in list(p1, p2, p3, p4, p5, p6, p7)) expect_true(inherits(p, "grob"))
  fig <- ComposeFigure(list(FigurePanel(p1, c(5, 10, 30, 30), letter = "a"), FigurePanel(p2, c(40, 10, 30, 30)),
                            FigurePanel(p3, c(75, 10, 30, 30)), FigurePanel(p4, c(110, 10, 30, 30)),
                            FigurePanel(p5, c(25, 60, 40, 30)), FigurePanel(p6, c(80, 50, 40, 20)),
                            FigurePanel(p7, c(130, 50, 20, 20))), height_mm = 100)
  dir <- withr::local_tempdir()
  SaveFigure(fig, pdf = file.path(dir, "c.pdf"), png = file.path(dir, "c.png"), dpi = 150)
  expect_gt(file.size(file.path(dir, "c.png")), 5000)
  expect_gt(file.size(file.path(dir, "c.pdf")), 5000)
  expect_error(PlotCellMap(list()), "CellMapData")
  expect_error(PlotTerritories(list(), colours = list()), "TerritoryTiles")
  expect_error(PlotImage("x"), "image array")
})

test_that("the image figure code carries no study identifiers", {
  files <- c(test_path("../../R/figure-data-C-images.R"), test_path("../../R/figure-plots-C-images.R"))
  skip_if(!all(file.exists(files)), "sources not available")
  txt <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  private <- Sys.getenv("CTTIR_PRIVATE_TERMS")
  expect_false(grepl(paste(c("PRJ-2026|qptiff", if (nzchar(private)) private), collapse = "|"), txt))
})
