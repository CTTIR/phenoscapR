test_that("the exact permutation bound is attained and never undercut", {
  expect_equal(ExactPermutationBound(6, 6), 2 / 924)
  expect_equal(ExactPermutationBound(4, 6), 1 / 210)
  expect_equal(ExactPermutationBound(4, 2), 1 / 15)
  exact_p <- function(x, na) {
    obs <- mean(x[seq_len(na)]) - mean(x[-seq_len(na)])
    d <- apply(utils::combn(length(x), na), 2, function(i) mean(x[i]) - mean(x[-i]))
    mean(abs(d) >= abs(obs) - 1e-12)
  }
  x <- c(13, 8, 1, 2, 3, 5)
  expect_equal(exact_p(x, 2), ExactPermutationBound(2, 4))
  expect_equal(exact_p(c(9, 8, 7, 1, 2, 3), 3), ExactPermutationBound(3, 3))
  set.seed(5)
  for (i in 1:20) expect_gte(exact_p(stats::rnorm(7), 3), ExactPermutationBound(3, 4))
  expect_error(ExactPermutationBound(0, 3), "positive")
  t <- data.frame(p = c(0.01, 0.2, NA, 0.04), q = c(0.04, 0.4, NA, 0.2), n_a = c(4, 4, 3, 4), n_b = 2,
                  e = c("a", "b", "c", "a"))
  s <- PlotDataContrastSummary(t, label = "e")
  expect_identical(c(s$tests, s$nominal, s$adjusted, s$n_a, s$n_b, s$endpoints), c(3, 2, 1, 4, 2, 3))
  expect_equal(s$p_bound, 1 / 15)
})

test_that("per-unit tables become text-table cells", {
  d <- data.frame(id = c("1", "2"), a = c(3, 0), b = c(12, 40), g = c("x", "y"))
  cells <- PlotDataTableCells(d, "id", c("a", "b"), c("First", "Second"), header = "Unit", key = "g",
                              highlight_below = 10, zero_text = "0 (NE)")
  expect_identical(nrow(cells), 9L)
  expect_identical(cells$label[cells$row == 1], c("Unit", "1", "2"))
  expect_identical(cells$label[cells$row == 2], c("First", "3", "0 (NE)"))
  expect_identical(cells$highlight[cells$row == 2], c(FALSE, TRUE, TRUE))
  expect_identical(cells$highlight[cells$row == 3], c(FALSE, FALSE, FALSE))
  expect_identical(cells$key[cells$row == 1], c(NA, "x", "y"))
  expect_error(PlotDataTableCells(d, "id", c("a", "b"), "one"), "row_labels")
})
