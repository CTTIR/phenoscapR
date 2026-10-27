test_that("keyed table comparison reports matches, mismatches and missing keys", {
  obs <- data.frame(id = c("x", "y", "z"), k = 1:3, p = c(0.1, 0.2, NA), s = c("ok", "ok", "ok"))
  ref <- data.frame(key = c("y", "x", "w"), k = c(2, 1, 9), pv = c(0.2 + 1e-12, 0.1, 1),
                    s = c("ok", "no", "ok"))
  out <- CompareTables(obs, ref, keys = c(id = "key"), columns = list(p = "pv", s = "s"),
                       tolerance = c(p = 1e-10), check = "demo")
  expect_identical(nrow(out), 8L)
  st <- stats::setNames(out$status, paste(out$id, out$column))
  expect_identical(unname(st[c("x p", "y p", "x s", "z p", "w s")]),
                   c("MATCH", "MATCH", "MISMATCH", "MISSING_REFERENCE", "MISSING_OBSERVED"))
  strict <- CompareTables(obs, ref, keys = c(id = "key"), columns = list(p = "pv"))
  expect_identical(strict$status[strict$id == "y"], "MISMATCH")
  filled <- CompareTables(obs, ref, keys = c(id = "key"), columns = list(k = "k"),
                          reference_fill = 3, observed_filter = list(id = c("x", "z")),
                          reference_filter = list(key = "x"))
  expect_identical(filled$status, c("MATCH", "MATCH"))
  expect_identical(filled$reference_filled, c(FALSE, TRUE))
  both_na <- CompareTables(data.frame(id = "a", v = NA_real_), data.frame(id = "a", v = NA),
                           "id", "v")
  expect_true(both_na$matches)
  expect_error(CompareTables(rbind(obs, obs), ref, c(id = "key"), list(p = "pv")), "Duplicate keys")
  expect_error(CompareTables(cbind(obs, status = 1), ref, c(id = "key", status = "k"), "s"),
               "collide")
  listed <- CompareTables(list(tests = obs), ref, c(id = "key"), list(p = "pv"),
                          observed_element = "tests", tolerance = 1e-10)
  expect_identical(sum(listed$matches), 2L)
})

test_that("array comparison checks shape and values", {
  obs <- data.frame(a = 1:3, b = c(0L, 1L, 0L), z = c(0.5, 1.5, 2.5))
  ref <- list(counts = cbind(1:3, c(0L, 1L, 0L)), z = c(0.5, 1.5, 2.25), w = 1:2)
  out <- CompareArrays(obs, ref, list(counts = c("a", "b"), z = "z", w = "z"), check = "arr")
  expect_identical(out$status, c("MATCH", "MISMATCH", "SHAPE_MISMATCH"))
  expect_equal(out$n_different[2], 1)
  expect_identical(out$max_difference[2], 0.25)
  skip_if_not(requireNamespace("cellspecR", quietly = TRUE))
  f <- withr::local_tempfile(fileext = ".npz")
  cellspecR::cs_write_npz(list(counts = cbind(1:3, c(0L, 1L, 0L)), z = c(0.5, 1.5, 2.5)), f)
  expect_true(all(CompareArrays(obs, f, list(counts = c("a", "b"), z = "z"))$matches))
})

test_that("comparison summaries pass only complete matching checks", {
  a <- data.frame(g = c("u", "u", "v"), id = c("x", "y", "x"), p = c(0.1, 0.2, 0.3))
  b <- a
  b$p[3] <- 0.4
  cmp <- CompareTables(a, b, c("g", "id"), "p", check = "demo")
  s <- SummarizeComparisons(cmp, by = c("check", "g"), expected_rows = list(demo = 2))
  expect_identical(s$g, c("u", "v"))
  expect_identical(s$status, c("PASS", "FAIL"))
  expect_identical(s$rows, c(2L, 1L))
  arr <- CompareArrays(data.frame(z = 1:2), list(z = 1:2), list(z = "z"))
  t <- SummarizeComparisons(list(named = arr[setdiff(names(arr), "check")]))
  expect_identical(t$check, "named")
  expect_identical(t$values, 2L)
  expect_identical(t$status, "PASS")
})

test_that("stacking adds key columns and recoding maps values", {
  s <- StackTables(list(a = data.frame(v = 1), b = data.frame(v = 2:3, w = "x")),
                   keys = list(a = list(batch = "one"), b = list(batch = "two")), name = "source")
  expect_identical(names(s), c("source", "batch", "v", "w"))
  expect_identical(s$batch, c("one", "two", "two"))
  expect_identical(s$w, c(NA, "x", "x"))
  one <- StackTables(data.frame(v = 1:2), keys = list(tag = "t"))
  expect_identical(one$tag, c("t", "t"))
  expect_error(StackTables(list(a = data.frame(batch = 1)), keys = list(a = list(batch = 2))),
               "collide")
  r <- RecodeValues(data.frame(g = c("low", "<1", "n.a.", NA)), "g",
                    list(low = 1, "<1" = 0.5), to = "score")
  expect_identical(r$score, c(1, 0.5, NA, NA))
  expect_identical(RecodeValues(r, "g", list(low = "L"), default = "-")$g, c("L", "-", "-", "-"))
})
