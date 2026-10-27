test_that("wide summaries become long plot data", {
  d <- data.frame(patient = c("p1", "p2"), group = "g", a = 1:2, b = c(3.5, NA))
  l <- PlotDataLonger(d, c("patient", "group"), c("a", "b"), conditions = c("A", "B"))
  expect_identical(names(l), c("patient", "group", "condition", "value"))
  expect_identical(l$condition, c("A", "A", "B", "B"))
  expect_identical(l$value, c(1, 2, 3.5, NA))
  expect_error(PlotDataLonger(d, "patient", "zz"), "lacks")
  expect_error(PlotDataLonger(d, "patient", c("a", "b"), conditions = "A"), "match")
})

test_that("plot data rows and columns are selected and ordered", {
  d <- data.frame(type = c("x", "y", "x", "z"), id = c("b", "a", "a", "c"), v = 1:4)
  s <- PlotDataSelect(d, filter = list(type = "x"), order_by = "id", order = c("a", "b"),
                      columns = c("id", "v"), rename = c(value = "v"))
  expect_identical(s, data.frame(id = c("a", "b"), value = c(3L, 1L)))
  expect_identical(nrow(PlotDataSelect(d, order_by = "id", order = c("c"))), 1L)
  expect_error(PlotDataSelect(d, order_by = "id"), "order is required")
  expect_error(PlotDataSelect(list(), filter = list()), "data frame")
  f <- withr::local_tempfile(fileext = ".tsv")
  writeLines(c("patient\tvalue", "p1\t2.5", "p2\t"), f)
  expect_identical(ReadPlotTable(f), data.frame(patient = c("p1", "p2"), value = c(2.5, NA)))
  expect_error(ReadPlotTable(tempfile()), "existing")
})
