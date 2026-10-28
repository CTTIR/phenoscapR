# Text templates filled from plot data.

test_that("templates are filled from data with figure formats", {
  d <- data.frame(k = 11, n = 12, p = 0.00146, q = 4.9e-4, x = -3.42, share = 51.2, big = 63921, txt = "a")
  expect_identical(FormatTemplate("{k|d}/{n|d} patients; p = {p|p}", d), "11/12 patients; p = 0.0015")
  expect_identical(FormatTemplate("q = {q|p}", d), "q = 4.9e-04")
  expect_identical(FormatTemplate("{x|sf1} ({share|f0}%); {big|comma}; {txt}", d), "−3.4 (51%); 63,921; a")
  expect_identical(FormatTemplate("{p|pfixed} {share|pfixed}", data.frame(p = 0.0039, share = 0.01953125)), "0.0039 0.020")
  expect_identical(FormatTemplate("{x|sf1}", data.frame(x = 0.02)), "0.0")
  expect_identical(FormatTemplate("n = {v|d}", data.frame(v = c(1, 2))), c("n = 1", "n = 2"))
  expect_identical(FormatTemplate(c("a {v|d}", "b {v|d}"), data.frame(v = c(1, 2))), c("a 1", "b 2"))
  expect_identical(FormatTemplate(c("a {v|d}", "b {v|d}"), data.frame(v = 5)), c("a 5", "b 5"))
  expect_identical(FormatTemplate("plain"), "plain")
  expect_identical(FormatTemplate("{v|p}", data.frame(v = NA_real_)), "n.e.")
  expect_identical(FormatTemplate("{v}", data.frame(v = NA_real_)), "n.e.")
  expect_error(FormatTemplate("{zz}", d), "missing column")
  expect_error(FormatTemplate("{txt|d}", d), "numeric")
  expect_error(FormatTemplate("{k|zz}", d), "Unknown template format")
  expect_error(FormatTemplate(c("a", "b", "c"), data.frame(v = 1:2)), "fewer rows")
})

test_that("sprintf formats, plurals, thousands and column names with separators", {
  v <- list(n = 12345, s = 37.6, k = 1)
  expect_identical(FormatTemplate("{n} cells; {s:%.0f}% of {k~cell~cells}", v), "12,345 cells; 38% of cell")
  expect_identical(FormatTemplate("{g} ({k~cell~cells})", data.frame(g = "x", k = 2)), "x (cells)")
  expect_identical(FormatTemplate("{s}", v), "37.6")
  w <- data.frame(`pct|Tumor cells` = 42.25, check.names = FALSE)
  expect_identical(FormatTemplate("{pct|Tumor cells} / {pct|Tumor cells|f1}", w), "42.25 / 42.2")
  expect_identical(FormatTemplate("{a|b c}", data.frame(a = 1)), "{a|b c}")
})

test_that("grammar texts take the single distinct value of each referenced column", {
  row <- .fig_template_unique("{g}: {n} of {k~cell~cells}", data.frame(g = c("x", "x"), n = c(3, NA), k = 2, z = 1:2))
  expect_identical(row, data.frame(g = "x", n = 3, k = 2))
  expect_null(.fig_template_unique("no placeholders", data.frame(a = 1)))
  expect_error(.fig_template_unique("{zz}", list(a = 1)), "No value")
  expect_error(.fig_template_unique("{a}", list(a = 1:2)), "one distinct")
})
