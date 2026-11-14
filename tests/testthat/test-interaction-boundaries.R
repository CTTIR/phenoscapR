.interaction_example <- function() {
  data.table::data.table(sample_id = "s", x = c(0, 1, 100, 101), y = 0,
                         phenotype = c("A", "A", "B", "B"))
}

test_that("complete avoidance retains the documented logarithmic score", {
  dt <- .interaction_example()
  out <- interaction_matrix(dt, 2)
  cross <- out$from != out$to
  expect_equal(out$observed, c(2, 0, 0, 2))
  expect_equal(out$expected, rep(1, 4))
  expect_identical(out$interaction_score[cross], rep(-Inf, 2))
  expect_equal(out$interaction_score[!cross], c(1, 1))
  perm <- .interaction_permutation(dt, 2, 100L, 42L)
  expect_true(all(perm$expected[cross] > 0))
  expect_identical(perm$interaction_score[cross], rep(-Inf, 2))
  dt$sample_id <- c("s1", "s1", "s2", "s2")
  no_expectation <- interaction_matrix(dt, 2)
  expect_equal(no_expectation$expected[cross], c(0, 0))
  expect_equal(no_expectation$interaction_score[cross], c(0, 0))
})

test_that("present sample IDs cannot silently remove interaction contributions", {
  for (bad in list(c("s", NA, "s", "s"), c("s", "", "s", "s"),
                   c("s", " ", "s", "s"))) {
    dt <- .interaction_example(); dt$sample_id <- bad
    expect_error(interaction_matrix(dt, 2), "sample_id")
    expect_error(.interaction_permutation(dt, 2, 10L, 42L), "sample_id")
  }
  malformed <- .interaction_example()
  data.table::setattr(malformed$sample_id, "dim", c(2L, 2L))
  expect_error(interaction_matrix(malformed, 2), "sample_id")
  expect_error(.interaction_permutation(malformed, 2, 10L, 42L), "sample_id")
  dt <- .interaction_example(); dt$sample_id <- factor(dt$sample_id)
  expected <- interaction_matrix(dt, 2)
  dt[, sample_id := NULL]
  expect_equal(interaction_matrix(dt, 2), expected)
  expect_equal(.interaction_permutation(dt, 2, 100L, 42L),
               .interaction_permutation(.interaction_example(), 2, 100L, 42L))
})

test_that("infinite interactions plot at explicit colour endpoints without data loss", {
  out <- interaction_matrix(.interaction_example(), 2)
  before <- data.table::copy(out)
  for (plotter in list(InteractionPlot, plot_interactions)) {
    p <- plotter(out)
    built <- ggplot2::ggplot_build(p)$data[[1L]]
    expect_equal(toupper(built$fill), c("#FF0000", "#0000FF", "#0000FF", "#FF0000"))
    expect_match(p$labels$caption, "Infinite scores")
    expect_identical(p$data$interaction_score, out$interaction_score)
    expect_identical(out, before)
  }
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  utils::write.csv(out, path, row.names = FALSE)
  expect_identical(utils::read.csv(path)$interaction_score, out$interaction_score)
  expect_null(InteractionPlot(transform(as.data.frame(out), interaction_score = 0))$labels$caption)
})


test_that("permutation interactions return typed zero results without sample edges", {
  for (ids in list(c("a", "b"), c("a", "a"))) {
    dt <- data.table::data.table(sample_id = ids, x = c(0, 10), y = 0,
                                phenotype = c("A", "B"))
    out <- .interaction_permutation(dt, 1, 10L, 1L)
    expect_equal(out$observed, rep(0, 4))
    expect_equal(out$expected, rep(0, 4))
    expect_equal(out$interaction_score, rep(0, 4))
    expect_equal(out$z_score, rep(0, 4))
    expect_equal(out$p_value, rep(1, 4))
  }
})


test_that("one phenotype retains the permutation matrix dimensions", {
  for (ids in list(c("s", "s"), c("s1", "s2"))) {
    dt <- data.table::data.table(sample_id = ids, x = c(0, 1), y = 0,
                                phenotype = "A")
    out <- .interaction_permutation(dt, 2, 10L, 1L)
    expected <- if (length(unique(ids)) == 1L) 2 else 0
    expect_equal(out$observed, expected)
    expect_equal(out$expected, expected)
    expect_equal(out$interaction_score, 0)
    expect_equal(out$z_score, 0)
    expect_equal(out$p_value, 1)
  }
})
