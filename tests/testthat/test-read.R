test_that("read_akoya reads a single CSV file", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  write.csv(data.frame(
    `Cell ID` = 1:10,
    `Cell X Position` = runif(10, 0, 1000),
    `Cell Y Position` = runif(10, 0, 1000),
    `Cell Area (px)` = runif(10, 50, 200),
    DAPI = rnorm(10, 500, 100),
    CD3 = rnorm(10, 300, 80),
    check.names = FALSE
  ), tmp, row.names = FALSE)

  dt <- read_akoya(tmp)
  expect_s3_class(dt, "data.table")
  expect_true(all(c("cell_id", "x", "y", "sample_id") %in% names(dt)))
  expect_equal(nrow(dt), 10L)
})

test_that("read_akoya reads a directory of CSVs", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))

  for (i in 1:3) {
    write.csv(data.frame(
      `Cell ID` = 1:5,
      `Cell X Position` = runif(5),
      `Cell Y Position` = runif(5),
      CD3 = rnorm(5),
      check.names = FALSE
    ), file.path(dir, paste0("sample_", i, ".csv")), row.names = FALSE)
  }

  dt <- read_akoya(dir)
  expect_equal(nrow(dt), 15L)
  expect_equal(length(unique(dt$sample_id)), 3L)
})

test_that("read_akoya errors on missing path", {
  expect_error(read_akoya("/nonexistent/path"), "does not exist")
})

test_that("read_akoya selects markers when specified", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  write.csv(data.frame(
    `Cell ID` = 1:5,
    `Cell X Position` = runif(5),
    `Cell Y Position` = runif(5),
    CD3 = rnorm(5), CD8 = rnorm(5), DAPI = rnorm(5),
    check.names = FALSE
  ), tmp, row.names = FALSE)

  dt <- read_akoya(tmp, markers = c("CD3", "CD8"))
  expect_true("CD3" %in% names(dt))
  expect_true("CD8" %in% names(dt))
  expect_false("DAPI" %in% names(dt))
})
