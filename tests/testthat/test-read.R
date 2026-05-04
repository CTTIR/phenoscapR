# ---------------------------------------------------------------------------
# Tests for read_spatial() -- all three input formats
# ---------------------------------------------------------------------------

# --- Flat format ------------------------------------------------------------

test_that("read_spatial reads flat-format CSV", {
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

  dt <- read_spatial(tmp)
  expect_s3_class(dt, "data.table")
  expect_true(all(c("cell_id", "x", "y", "sample_id") %in% names(dt)))
  expect_equal(nrow(dt), 10L)
})

test_that("read_spatial reads a directory of CSVs", {
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

  dt <- read_spatial(dir)
  expect_equal(nrow(dt), 15L)
  expect_equal(length(unique(dt$sample_id)), 3L)
})

test_that("read_spatial errors on missing path", {
  expect_error(read_spatial("/nonexistent/path"), "does not exist")
})

test_that("read_spatial selects markers when specified", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  write.csv(data.frame(
    `Cell ID` = 1:5,
    `Cell X Position` = runif(5),
    `Cell Y Position` = runif(5),
    CD3 = rnorm(5), CD8 = rnorm(5), DAPI = rnorm(5),
    check.names = FALSE
  ), tmp, row.names = FALSE)

  dt <- read_spatial(tmp, markers = c("CD3", "CD8"))
  expect_true("CD3" %in% names(dt))
  expect_true("CD8" %in% names(dt))
  expect_false("DAPI" %in% names(dt))
})

# --- QuPath Full format -----------------------------------------------------

test_that("read_spatial reads QuPath full-format CSV", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  df <- data.frame(
    Image = rep("FL_01_Scan1.er.qptiff - resolution #1", 5),
    `Object ID` = paste0("uuid-", 1:5),
    `Object type` = "Cell",
    Name = "",
    Classification = c("T cell", "", "B cell", NA, "T cell"),
    Parent = "Annotation",
    ROI = "Polygon",
    `Centroid X um` = runif(5, 0, 1000),
    `Centroid Y um` = runif(5, 0, 1000),
    `Nucleus: Area` = runif(5, 10, 50),
    `Cell: Area` = runif(5, 50, 200),
    `Nucleus: CD3e mean` = rnorm(5, 500, 100),
    `Cell: CD3e mean` = rnorm(5, 400, 80),
    `Cytoplasm: CD3e mean` = rnorm(5, 300, 60),
    `Nucleus: CD3e sum` = rnorm(5, 5000, 500),
    `Cell: CD3e sum` = rnorm(5, 4000, 400),
    `Cytoplasm: CD3e sum` = rnorm(5, 3000, 300),
    `Nucleus: CD8 mean` = rnorm(5, 200, 50),
    `Cell: CD8 mean` = rnorm(5, 180, 40),
    `Cytoplasm: CD8 mean` = rnorm(5, 160, 30),
    `Nucleus: CD8 sum` = rnorm(5, 2000, 200),
    `Cell: CD8 sum` = rnorm(5, 1800, 180),
    `Cytoplasm: CD8 sum` = rnorm(5, 1600, 160),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  write.csv(df, tmp, row.names = FALSE)

  dt <- read_spatial(tmp)

  expect_s3_class(dt, "data.table")
  expect_true(all(c("cell_id", "x", "y", "sample_id") %in% names(dt)))
  expect_true("CD3e" %in% names(dt))
  expect_true("CD8" %in% names(dt))
  expect_true("classification" %in% names(dt))
  expect_true("cell_area" %in% names(dt))
  expect_equal(nrow(dt), 5L)
  # Sample ID parsed from Image column
  expect_true(all(grepl("FL_01_Scan1", dt$sample_id)))
})

test_that("read_spatial extracts Nucleus compartment when requested", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  df <- data.frame(
    `Object ID` = paste0("id-", 1:3),
    `Centroid X um` = runif(3),
    `Centroid Y um` = runif(3),
    `Nucleus: DAPI mean` = c(100, 200, 300),
    `Cell: DAPI mean` = c(80, 160, 240),
    `Cytoplasm: DAPI mean` = c(60, 120, 180),
    `Nucleus: DAPI sum` = c(1000, 2000, 3000),
    `Cell: DAPI sum` = c(800, 1600, 2400),
    `Cytoplasm: DAPI sum` = c(600, 1200, 1800),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  write.csv(df, tmp, row.names = FALSE)

  dt <- read_spatial(tmp, compartment = "Nucleus", statistic = "mean")
  expect_true("DAPI" %in% names(dt))
  expect_equal(dt$DAPI, c(100, 200, 300))
})

# --- QuPath Minimal format --------------------------------------------------

test_that("read_spatial reads QuPath minimal-format CSV", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  df <- data.frame(
    `Centroid X um` = runif(5, 0, 1000),
    `Centroid Y um` = runif(5, 0, 1000),
    `DAPI: Cell: Mean` = rnorm(5, 500, 100),
    `CD34: Cell: Mean` = rnorm(5, 300, 80),
    `CD3e: Cell: Mean` = rnorm(5, 200, 60),
    check.names = FALSE
  )
  write.csv(df, tmp, row.names = FALSE)

  dt <- read_spatial(tmp)

  expect_s3_class(dt, "data.table")
  expect_true(all(c("cell_id", "x", "y") %in% names(dt)))
  expect_true("DAPI" %in% names(dt))
  expect_true("CD34" %in% names(dt))
  expect_true("CD3e" %in% names(dt))
  expect_equal(nrow(dt), 5L)
})

# --- Semicolon delimiter detection ------------------------------------------

test_that("read_spatial auto-detects semicolon delimiter", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  lines <- c(
    "Cell ID;Cell X Position;Cell Y Position;CD3",
    "1;10.5;20.3;100",
    "2;30.2;40.1;200"
  )
  writeLines(lines, tmp)

  dt <- read_spatial(tmp)
  expect_equal(nrow(dt), 2L)
  expect_true("CD3" %in% names(dt))
})

# --- ReadSpatial S4 wrapper -------------------------------------------------

test_that("ReadSpatial returns SpatialCellData", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  write.csv(data.frame(
    `Cell ID` = 1:5,
    `Cell X Position` = runif(5, 0, 1000),
    `Cell Y Position` = runif(5, 0, 1000),
    CD3 = rnorm(5, 300, 80),
    CD8 = rnorm(5, 200, 60),
    check.names = FALSE
  ), tmp, row.names = FALSE)

  obj <- ReadSpatial(tmp, filter = NA)
  expect_s4_class(obj, "SpatialCellData")
  expect_equal(NCells(obj), 5L)
})

test_that("ReadSpatial filters DAPI by default", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp))

  write.csv(data.frame(
    `Cell ID` = 1:5,
    `Cell X Position` = runif(5),
    `Cell Y Position` = runif(5),
    DAPI = rnorm(5), CD3 = rnorm(5), CD8 = rnorm(5),
    check.names = FALSE
  ), tmp, row.names = FALSE)

  obj <- ReadSpatial(tmp)
  expect_false("DAPI" %in% Markers(obj))
  expect_true("CD3" %in% Markers(obj))
})
