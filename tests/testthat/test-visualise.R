test_that("plot_cell_map returns ggplot", {
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:20,
    x = runif(20), y = runif(20),
    phenotype = sample(c("A", "B"), 20, replace = TRUE)
  )
  p <- plot_cell_map(dt)
  expect_s3_class(p, "gg")
})

test_that("plot_density returns ggplot", {
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:20,
    x = runif(20), y = runif(20),
    density = rpois(20, 5)
  )
  p <- plot_density(dt)
  expect_s3_class(p, "gg")
})

test_that("plot_interactions returns ggplot", {
  interactions <- data.table::data.table(
    from = rep(c("A", "B"), each = 2),
    to = rep(c("A", "B"), 2),
    observed = c(10, 5, 5, 10),
    expected = rep(7.5, 4),
    interaction_score = log2(c(10, 5, 5, 10) / 7.5)
  )
  p <- plot_interactions(interactions)
  expect_s3_class(p, "gg")
})

test_that("plot_heatmap returns ggplot", {
  dt <- data.table::data.table(
    sample_id = "s1", cell_id = 1:40,
    x = runif(40), y = runif(40),
    CD3 = c(rnorm(20, 1), rnorm(20, 0)),
    CD8 = c(rnorm(20, 0), rnorm(20, 1)),
    phenotype = rep(c("A", "B"), each = 20)
  )
  p <- plot_heatmap(dt)
  expect_s3_class(p, "gg")
})

test_that("plot_cell_map errors on missing column", {
  dt <- data.table::data.table(x = 1, y = 1)
  expect_error(plot_cell_map(dt, colour_by = "missing"), "not found")
})
