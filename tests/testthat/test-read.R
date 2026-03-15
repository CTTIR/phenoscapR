test_that("ReadAkoya reads a single CSV file", {
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

  obj <- ReadAkoya(tmp)
  expect_s4_class(obj, "AkoyaExperiment")
  expect_equal(NCells(obj), 10L)
  expect_true("DAPI" %in% Markers(obj))
  expect_true("CD3" %in% Markers(obj))
  expect_true("cell_area" %in% names(Meta(obj)))
})

test_that("ReadAkoya reads a directory of CSVs", {
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

  obj <- ReadAkoya(dir)
  expect_equal(NCells(obj), 15L)
  expect_equal(length(unique(Meta(obj)$sample_id)), 3L)
})

test_that("ReadAkoya errors on missing path", {
  expect_error(ReadAkoya("/nonexistent/path"), "does not exist")
})

test_that("ReadAkoya filters markers", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  write.csv(data.frame(
    `Cell ID` = 1:5,
    `Cell X Position` = runif(5),
    `Cell Y Position` = runif(5),
    CD3 = rnorm(5), CD8 = rnorm(5), DAPI = rnorm(5),
    check.names = FALSE
  ), tmp, row.names = FALSE)

  obj <- ReadAkoya(tmp, markers = c("CD3", "CD8"))
  expect_true("CD3" %in% Markers(obj))
  expect_true("CD8" %in% Markers(obj))
  expect_false("DAPI" %in% Markers(obj))
})

test_that("CreateAkoyaObject works from raw data", {
  counts <- matrix(rnorm(30), nrow = 10,
                   dimnames = list(NULL, c("CD3", "CD8", "DAPI")))
  coords <- data.frame(x = runif(10), y = runif(10))
  obj <- CreateAkoyaObject(counts, coords, sample_id = "test")

  expect_s4_class(obj, "AkoyaExperiment")
  expect_equal(NCells(obj), 10L)
  expect_equal(obj@project, "AkoyaProject")
})
