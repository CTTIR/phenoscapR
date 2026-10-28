# Generic plot-data builders (PlotData*) on small synthetic tables.

test_that("rows and columns are selected, filtered by conditions and ordered", {
  d <- data.frame(type = c("x", "y", "x", "z"), id = c("b", "a", "a", "c"), v = 1:4)
  s <- PlotDataSelect(d, filter = list(type = "x"), order_by = "id", order = c("a", "b"),
                      columns = c("id", "v"), rename = c(value = "v"))
  expect_identical(s, data.frame(id = c("a", "b"), value = c(3L, 1L)))
  expect_identical(nrow(PlotDataSelect(d, order_by = "id", order = c("c"))), 1L)
  expect_error(PlotDataSelect(d, order_by = "id"), "order is required")
  expect_error(PlotDataSelect(list(), filter = list()), "data frame")
  w <- data.frame(id = c("a", "b", "c", "d"), n = c(1, 12, NA, 4), g = c("x", "y", "x", "x"), f = c(TRUE, FALSE, TRUE, NA))
  expect_identical(PlotDataSelect(w, where = list(list(column = "n", op = ">=", value = 10)))$id, "b")
  expect_identical(PlotDataSelect(w, where = list(column = "g", op = "in", value = c("y")))$id, "b")
  expect_identical(PlotDataSelect(w, where = list(list(column = "n", op = "is_na")))$id, "c")
  expect_identical(PlotDataSelect(w, where = list(list(column = "id", op = "not_matches", value = "^[ab]")))$id,
                   c("c", "d"))
  expect_identical(PlotDataSelect(w, where = list(list(column = "g", op = "==", value = "x"),
                                                  list(column = "n", op = "<", value = 2)))$id, "a")
  expect_identical(PlotDataSelect(w, filter = list(f = TRUE), where = list(list(column = "n", op = "not_na")))$id, "a")
  expect_error(PlotDataSelect(w, where = list(list(column = "n", op = "~", value = 1))), "Unknown operator")
  f <- withr::local_tempfile(fileext = ".tsv")
  writeLines(c("patient\tvalue", "p1\t2.5", "p2\t"), f)
  expect_identical(ReadPlotTable(f), data.frame(patient = c("p1", "p2"), value = c(2.5, NA)))
  expect_error(ReadPlotTable(tempfile()), "existing")
})

test_that("wide columns become long rows by name, pattern or exclusion", {
  d <- data.frame(patient = c("p1", "p2"), group = "g", a = 1:2, b = c(3.5, NA))
  l <- PlotDataLonger(d, c("patient", "group"), c("a", "b"), conditions = c("A", "B"))
  expect_identical(names(l), c("patient", "group", "condition", "value"))
  expect_identical(l$condition, c("A", "A", "B", "B"))
  expect_identical(l$value, c(1, 2, 3.5, NA))
  expect_identical(nrow(PlotDataLonger(d, "patient", c("a", "b"), drop_na = TRUE)), 3L)
  expect_error(PlotDataLonger(d, "patient", "zz"), "lacks")
  expect_error(PlotDataLonger(d, "patient", c("a", "b"), conditions = "A"), "match")
  expect_error(PlotDataLonger(d, "patient", "a", pattern = "^a"), "not both")
  w <- data.frame(type = c("a", "b"), `v|p1` = 1:2, `v|p2` = c(3, NA), check.names = FALSE)
  p <- PlotDataLonger(w, "type", pattern = "^v\\|(.*)$", names_to = "unit", drop_na = TRUE)
  expect_identical(p$unit, c("p1", "p1", "p2"))
  expect_identical(p$value, c(1, 2, 3))
  expect_error(PlotDataLonger(w, "type", pattern = "^zz"), "No value")
  cn <- data.frame(id = c("p1", "p2"), "CN1 T" = 1:2, "CN2 V" = 3:4, other = 9, check.names = FALSE)
  k <- PlotDataLonger(cn, "id", pattern = "^CN", names_to = "cn", values_to = "pct")
  expect_identical(unique(k$cn), c("CN1 T", "CN2 V"))
  expect_identical(unique(PlotDataLonger(cn, "id", exclude = "other")$condition), c("CN1 T", "CN2 V"))
})

test_that("joins keep row order and reject duplicated keys", {
  a <- data.frame(id = c("p2", "p1", "p3"), v = 1:3)
  b <- data.frame(id = c("p1", "p2"), group = c("A", "B"), w = c(10, 20))
  expect_identical(PlotDataJoin(a, b, "id", columns = "group")$group, c("B", "A", NA))
  expect_identical(names(PlotDataJoin(a, b, "id")), c("id", "v", "group", "w"))
  expect_identical(PlotDataJoin(a, b, "id", columns = "w", rename = "weight")$weight, c(20, 10, NA))
  other <- data.frame(key = c("p3", "p1"), area = c(6, 12))
  expect_identical(PlotDataJoin(a, other, by = "id", by_other = "key")$area, c(NA, 12, 6))
  expect_error(PlotDataJoin(a, rbind(b, b), "id"), "not unique")
  expect_error(PlotDataJoin(a, b, c("id", "v"), "id"), "same length")
})

test_that("tables are bound by rows with sources, keys and fills, or by columns", {
  b <- PlotDataBindRows(list(a = data.frame(x = 1), b = data.frame(y = 3, z = 2)), names_to = "src",
                        rename = list(b = c(x = "z")))
  expect_identical(names(b), c("x", "src", "y"))
  expect_identical(b$x, c(1, 2))
  expect_identical(b$y, c(NA, 3))
  l <- PlotDataBindRows(list(a = data.frame(k = 1, v = 2), b = data.frame(k = 3, v = 4, w = 0)),
                        columns = c("k", "v"), labels = c("first", "second"), names_to = "set")
  expect_identical(l$set, c("first", "second"))
  expect_identical(names(l), c("k", "v", "set"))
  expect_identical(PlotDataBindRows(list(data.frame(v = 1), data.frame(v = 2)), names_to = "i")$i, 1:2)
  s <- PlotDataBindRows(list(a = data.frame(v = 1), b = data.frame(v = 2:3, w = "x")),
                        keys = list(a = list(batch = "one"), b = list(batch = "two")))
  expect_identical(names(s), c("batch", "v", "w"))
  expect_identical(s$batch, c("one", "two", "two"))
  expect_identical(s$w, c(NA, "x", "x"))
  expect_identical(PlotDataBindRows(data.frame(v = 1:2), keys = list(tag = "t"))$tag, c("t", "t"))
  e <- PlotDataBindRows(list(a = list(table = data.frame(v = 1)), b = list(table = data.frame(v = 2))),
                        element = "table", names_to = "src")
  expect_identical(e$src, c("a", "b"))
  expect_error(PlotDataBindRows(list(a = data.frame(batch = 1)), keys = list(a = list(batch = 2))), "collide")
  expect_error(PlotDataBindRows(list(1)), "list of data frames")
  expect_error(PlotDataBindRows(list(data.frame(v = 1)), labels = c("x", "y")), "one entry")
  expect_identical(PlotDataBindColumns(list(data.frame(n = 9), data.frame(t = "a"))), data.frame(n = 9, t = "a"))
  expect_error(PlotDataBindColumns(list(data.frame(n = 1:2), data.frame(t = "a"))), "same number")
})

test_that("array lists become tables with matrices, masked columns, kept rows and row ids", {
  a <- list(xy = matrix(c(1, 2, 3, 4, 5, 6), 3), label = c("a", "b", "a"), names = c("u", "v"),
            feat = matrix(c(0.5, 1, 2, 3, 4, 5), 3), keep = c(TRUE, FALSE, TRUE),
            cls = c(9L, 7L), has = c(TRUE, FALSE, TRUE))
  t <- PlotDataFromArrays(a, columns = c(cls = "label", "keep"),
                          matrices = list(xy = c("x", "y"), feat = list(names_from = "names", prefix = "f_")))
  expect_identical(names(t), c("cls", "keep", "x", "y", "f_u", "f_v"))
  expect_identical(t$y, c(4, 5, 6))
  expect_identical(t$f_v, c(3, 4, 5))
  expect_identical(names(PlotDataFromArrays(a)), c("label", "keep", "has"))
  m <- PlotDataFromArrays(a, list(type = "label", cls = "cls"), masked = list(cls = "has"), keep = "keep", row_id = "row")
  expect_identical(names(m), c("type", "cls", "row"))
  expect_identical(m$row, c(0L, 2L))
  expect_identical(m$cls, c(9L, 7L))
  first <- PlotDataFromArrays(a, c(type = "label"), keep = "keep", row_id = "source_row", row_base = 1, row_first = TRUE)
  expect_identical(names(first), c("source_row", "type"))
  expect_identical(first$source_row, c(1L, 3L))
  expect_error(PlotDataFromArrays(a, columns = "zz"), "Unknown array")
  expect_error(PlotDataFromArrays(a, "xy"), "one-dimensional")
  expect_error(PlotDataFromArrays(a, matrices = list(xy = "x")), "match")
  expect_error(PlotDataFromArrays(a, list(label = "label"), masked = list(label = "has")), "mask")
  expect_error(PlotDataFromArrays(a, "label", keep = "label"), "logical")
  expect_error(PlotDataFromArrays(list(1, 2)), "named list")
  skip_if_not(requireNamespace("cellspecR", quietly = TRUE))
  skip_if_not("cs_write_npz" %in% getNamespaceExports("cellspecR"))
  f <- withr::local_tempfile(fileext = ".npz")
  cellspecR::cs_write_npz(list(x_um = c(1.5, 2.5, 3.5), label = c("a", "b", "a"), kept = c(TRUE, FALSE, TRUE),
                               grid = matrix(1:6, 3)), f)
  z <- PlotDataFromArrays(f, c(x = "x_um", type = "label"), keep = "kept", row_id = "source_row",
                          row_base = 1, row_first = TRUE)
  expect_identical(z, data.frame(source_row = c(1L, 3L), x = c(1.5, 3.5), type = c("a", "a")))
})

test_that("values are recoded by map, patterns, index, extraction and substitution", {
  d <- data.frame(id = c("p1", "p2", "p3"), grp = c("TME-A x", "TME-B y", "other"), code = c(0, 2, -1))
  expect_identical(PlotDataRecode(d, "grp", map = c(other = "O"), patterns = c("^TME-A" = "1"), default = "2",
                                  into = "g")$g, c("1", "2", "O"))
  expect_identical(PlotDataRecode(d, "code", index = data.frame(n = c("first", "second", "third")),
                                  default = "none", into = "name")$name, c("first", "third", "none"))
  expect_identical(PlotDataRecode(d, "grp", extract = "^TME-(.) .*$", map = c(A = "alpha"), into = "x")$x,
                   c("alpha", "TME-B y", "other"))
  r <- PlotDataRecode(data.frame(e = c("pct|B_cells", "density|B_cells", "x")), "e", map = c(x = "other"),
                      substitute = list(c("_", " "), c("^pct\\|(.*)$", "\\1 (% of cells)"),
                                        c("^density\\|(.*)$", "\\1 (per mm2)")), into = "label")
  expect_identical(r$label, c("B cells (% of cells)", "B cells (per mm2)", "other"))
  expect_error(PlotDataRecode(data.frame(e = "a"), "e", substitute = list("a")), "pattern, replacement")
  s <- PlotDataRecode(data.frame(g = c("low", "<1", "n.a.", NA)), "g", list(low = 1, "<1" = 0.5),
                      keep_unmatched = FALSE, into = "score")
  expect_identical(s$score, c(1, 0.5, NA, NA))
  expect_identical(PlotDataRecode(s, "g", list(low = "L"), default = "-")$g, c("L", "-", "-", "-"))
  expect_identical(PlotDataRecode(data.frame(a = c("x", "y")), "a", list(x = "first"), keep_unmatched = FALSE)$a,
                   c("first", NA))
  expect_identical(PlotDataRecode(data.frame(a = c("x", "y")), "a", list(x = "first"), into = "b")$b,
                   c("first", "y"))
})

test_that("ratios, pair ratios, products, shares and relative values are computed per row", {
  r <- PlotDataRatio(data.frame(a = c(1, 0, 4), b = 2), "a", "b", log_base = 2)
  expect_equal(r$ratio, c(-1, -Inf, 1))
  expect_equal(PlotDataRatio(data.frame(a = 1, b = 3), "a", "b", pseudocount = 1, scale = 100)$ratio, 50)
  d <- data.frame(id = rep(c("p1", "p2", "p3"), c(2, 2, 1)), set = c("x", "ref", "x", "ref", "ref"),
                  v = c(4, 2, 1, 2, 5), w = c(1, 1, 3, 1, 1))
  pr <- PlotDataPairRatio(d, "id", "set", "x", "ref", c("v", "w"), names = c("V", "W"), log_base = 2)
  expect_identical(nrow(pr), 6L)
  expect_equal(pr$ratio[pr$variable == "V"], c(1, -1, NA))
  expect_equal(pr$ratio[pr$variable == "W"], c(0, log2(3), NA))
  expect_error(PlotDataPairRatio(rbind(d, d), "id", "set", "x", "ref", "v"), "not unique")
  p <- PlotDataProduct(data.frame(n = c(44, 5, 3), pct = c(50, 50, 50)), c("n", "pct"), divide = 100, round = TRUE)
  expect_identical(p$value, c(22, 2, 2))
  expect_equal(PlotDataShares(data.frame(a = 1:2, n = c(10, 20)), "a", "n", scale = 1)$a, c(0.1, 0.1))
  expect_equal(PlotDataShares(data.frame(a = 1:2, n = c(10, 20)), "a", "n", suffix = "_pct")$a_pct, c(10, 10))
  expect_equal(PlotDataRelative(data.frame(k = 4:6, v = c(50, 40, 25)), "v", into = "rel")$rel, c(1, 0.8, 0.5))
  expect_equal(PlotDataRelative(data.frame(k = 4:6, v = c(50, 40, 25)), "v", at_column = "k", at = 5)$v,
               c(1.25, 1, 0.625))
  expect_identical(PlotDataDirection(data.frame(n = c(9, 9), up = c(8, 1), e = c(0.5, -0.4)), "n", "up", "e")$k,
                   c(8, 8))
  m <- PlotDataMembership(data.frame(id = c("a", "b", "c")), data.frame(id = "b"), "id", into = "excluded",
                          negate = TRUE)
  expect_identical(m$excluded, c(TRUE, FALSE, TRUE))
  expect_identical(PlotDataConstant(data.frame(x = 1:2), "s", "a")$s, c("a", "a"))
  expect_identical(PlotDataUnite(data.frame(t = "a", r = c(20, 2.5)), c("t", "r"), "key")$key, c("a 20", "a 2.5"))
})

test_that("summaries come in wide or long form, by group, filtered and sorted", {
  d <- data.frame(id = c("a", "b", "c", "d"), n = c(1, 12, NA, 4), g = c("y", "x", "y", "y"), ok = c(TRUE, TRUE, TRUE, FALSE))
  expect_identical(PlotDataSummarise(d, "n", "sum")$n, 17)
  expect_identical(PlotDataSummarise(d, fun = "count", by = "g")$n, c(3L, 1L))
  expect_identical(PlotDataSummarise(d, fun = "count", by = "g")$g, c("y", "x"))
  expect_identical(PlotDataSummarise(d, fun = "count", by = "g", sort = TRUE)$g, c("x", "y"))
  expect_identical(PlotDataSummarise(d, "g", "n_distinct", into = "groups")$groups, 2L)
  expect_identical(PlotDataSummarise(d, "n", "sum", filter = list(ok = TRUE))$n, 13)
  expect_true(is.na(PlotDataSummarise(d, "n", "sum", na_rm = FALSE)$n))
  e <- data.frame(cl = c(2, 2, 1, 1, 1, 3), type = c("b", "b", "a", "a", "c", "c"), v = 1:6, w = 6:1)
  m <- PlotDataSummarise(e, c("v", "w"), "mean", by = "cl", long = TRUE, sort = TRUE)
  expect_identical(names(m), c("cl", "name", "value"))
  expect_equal(m$value, c(4, 1.5, 6, 3, 5.5, 1))
  expect_identical(m$name, rep(c("v", "w"), each = 3))
  m2 <- PlotDataSummarise(e, "v", "sum", by = c("cl", "type"), long = TRUE, values_to = "total")
  expect_equal(m2$total[m2$cl == 1 & m2$type == "a"], 7)
  expect_equal(PlotDataSummarise(e, "v", "sum", long = TRUE)$value, 21)
  expect_error(PlotDataSummarise(d, "n", "mode"), "Unknown summary")
  expect_error(PlotDataSummarise(d, c("n", "id"), "sum", into = "x"), "into must match")
})

test_that("counts, cross shares, quantiles, ranks, dominant categories and key colours", {
  d <- data.frame(g = c("a", "a", "b", "b", "b"), p = c("x", "y", "x", "x", "z"), t = c("T", "U", "T", "T", "U"),
                  f = c(TRUE, TRUE, TRUE, FALSE, TRUE))
  c1 <- PlotDataCount(d, "g", filter = list(f = TRUE), distinct = "p",
                      tally = list(n_t = list(column = "t", values = "T")))
  expect_identical(c1$n, c(2L, 2L))
  expect_identical(c1$n_distinct, c(2L, 2L))
  expect_identical(c1$n_per_distinct, c(1L, 1L))
  expect_identical(c1$n_t, c(1L, 1L))
  expect_equal(c1$share, c(50, 50))
  expect_identical(PlotDataCount(d)$n, 5L)
  e <- data.frame(cl = c(2, 2, 1, 1, 1, 3), type = c("b", "b", "a", "a", "c", "c"), ok = TRUE)
  s <- PlotDataCrossShares(e, "cl", "type", filter = list(ok = TRUE))
  expect_identical(nrow(s), 9L)
  expect_equal(s$share[s$cl == "1" & s$type == "a"], 200 / 3)
  expect_equal(s$total[s$cl == "2"], rep(2, 3))
  r <- PlotDataDominant(s, "cl", "type", columns = c("a", "b", "c"), priority = c("b", "a"))
  # cluster 3 is dominated by a type outside the priority list and comes first
  expect_identical(r$cl, c("3", "2", "1"))
  expect_identical(r$dominant, c("c", "b", "a"))
  tie <- PlotDataCrossShares(data.frame(g = c(1, 1), t = c("x", "y")), "g", "t")
  expect_identical(PlotDataDominant(tie, "g", "t", columns = c("y", "x"))$dominant, "y")
  q <- PlotDataQuantiles(data.frame(type = rep(c("b", "a"), each = 4), x = 1, v = c(1, 2, 3, 10, 4, 4, NA, 8)),
                         c("type", "x"), "v")
  expect_identical(q$type, c("b", "a"))
  expect_equal(q$median, c(2.5, 4))
  expect_equal(q$lower, c(1.75, 4))
  expect_equal(q$upper, c(4.75, 6))
  expect_identical(q$n, c(4L, 3L))
  expect_error(PlotDataQuantiles(q, "type", "median", probs = 0.5), "same length")
  w <- data.frame(id = c("p1", "p2", "p3"), "CN1 Tumour" = c(10, 50, 30), "CN2 Tumour mixed" = c(5, 0, 30),
                  "CN3 Vessel" = c(85, 50, 40), check.names = FALSE)
  expect_identical(PlotDataRankRows(w, "id", pattern = "^CN[0-9]+ Tumour")$id, c("p3", "p2", "p1"))
  expect_identical(PlotDataRankRows(w, "id", columns = "CN3 Vessel", decreasing = FALSE, ids = c("p1", "p2"))$id,
                   c("p2", "p1"))
  expect_error(PlotDataRankRows(w, "id"), "No columns")
  k <- PlotDataKeyColours(data.frame(key = c(3, 1, 22, 0)), palettes = c("tab20", "tab20b"))
  expect_identical(k$key, c("0", "1", "3", "22"))
  expect_identical(k$colour[k$key == "1"], ManuscriptPalettes()$clusters[1])
  expect_identical(k$colour[k$key == "22"], "#5254a3")
  expect_error(PlotDataKeyColours(1:3, palettes = "nothing"), "Unknown categorical")
})

test_that("texts are written per row or collapsed from rows", {
  d <- data.frame(p = c("a", "b"), n = c(27081, 85180), g = c("first", "other"))
  lab <- PlotDataLabels(d, "{n:%.0f}k cells; {g}", id = "p", scales = list(n = 0.001))
  expect_identical(lab, data.frame(p = c("a", "b"), text = c("27k cells; first", "85k cells; other")))
  expect_identical(PlotDataLabels(d[0, ], "{g}")$text, character())
  e <- data.frame(id = c("d", "a"), n = c(4, 1))
  c1 <- PlotDataCollapse(e, "{id}, {n|d}", order_by = "n", into = "few")
  expect_identical(c1$few, "a, 1; d, 4")
  expect_identical(c1$rows, 2L)
  expect_identical(PlotDataCollapse(e[0, ], "{id}")$text, "")
})
