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

test_that("whole-number format writes every digit", {
  # Outputs for these values are unchanged.
  v <- c(0, 7, -3, 12.4, 99999, 123456, -98765.4, 2.5)
  expect_identical(FormatTemplate("{n|d}", data.frame(n = v)),
                   c("0", "7", "−3", "12", "99999", "123456", "−98765", "2"))
  expect_identical(FormatTemplate("{n|d} cells", data.frame(n = c(1e5, 2e6, -2e5, 3e10))),
                   c("100000 cells", "2000000 cells", "−200000 cells", "30000000000 cells"))
  expect_identical(FormatTemplate("{n|d}", data.frame(n = -0.2)), "0")
})

test_that("plain and comma formats write whole numbers beyond the integer range", {
  big <- c(2^31, -2^31, 3e9, -1234567890123)
  expected <- c("2,147,483,648", "−2,147,483,648", "3,000,000,000", "−1,234,567,890,123")
  expect_silent(plain <- FormatTemplate("{n}", data.frame(n = big)))
  expect_identical(plain, expected)
  expect_silent(comma <- FormatTemplate("{n|comma}", data.frame(n = big + 0.2)))
  expect_identical(comma, expected)
  # Outputs inside the integer range are unchanged.
  expect_identical(FormatTemplate("{n} / {n|comma}", data.frame(n = c(0, -0.3, 1234, -2147483647))),
                   c("0 / 0", "−0.3 / 0", "1,234 / 1,234", "−2,147,483,647 / −2,147,483,647"))
})

test_that("infinite values in plain placeholders are not evaluable", {
  expect_identical(FormatTemplate("{r}", data.frame(r = c(Inf, -Inf, NaN, NA, 2))), c("n.e.", "n.e.", "n.e.", "n.e.", "2"))
  expect_identical(FormatTemplate("{r|f1}", data.frame(r = Inf)), "n.e.")
})
