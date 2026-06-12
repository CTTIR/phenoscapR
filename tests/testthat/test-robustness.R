# Reader / object-construction robustness: duplicate marker names, all-NA
# columns, and missing names must be handled gracefully rather than producing a
# malformed object downstream.

test_that("duplicate marker names are rejected (not silently renamed)", {
  counts <- matrix(rnorm(30), nrow = 10,
                   dimnames = list(NULL, c("CD3", "CD3", "CD8")))
  coords <- data.frame(x = runif(10), y = runif(10))
  expect_error(CreateSpatialObject(counts, coords), "duplicat")
})

test_that("all-NA marker columns are dropped with a warning", {
  counts <- matrix(rnorm(30), nrow = 10,
                   dimnames = list(NULL, c("CD3", "Empty", "CD8")))
  counts[, "Empty"] <- NA_real_
  coords <- data.frame(x = runif(10), y = runif(10))
  expect_warning(obj <- CreateSpatialObject(counts, coords), "all-NA")
  expect_false("Empty" %in% Markers(obj))
  expect_equal(NMarkers(obj), 2L)
})

test_that("unnamed marker matrices get default names", {
  counts <- matrix(rnorm(20), nrow = 10)
  coords <- data.frame(x = runif(10), y = runif(10))
  obj <- CreateSpatialObject(counts, coords)
  expect_equal(Markers(obj), c("M1", "M2"))
})

test_that("clean inputs construct silently", {
  counts <- matrix(rnorm(20), nrow = 10,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(10), y = runif(10))
  expect_silent(CreateSpatialObject(counts, coords))
})

test_that("ReadSpatial inherits the same robustness", {
  tmp <- tempfile(fileext = ".csv")
  df <- data.frame(
    `Cell ID` = 1:6,
    `Cell X Position` = runif(6, 0, 100),
    `Cell Y Position` = runif(6, 0, 100),
    CD3 = rnorm(6, 300, 50),
    Ghost = NA_real_,
    check.names = FALSE
  )
  utils::write.csv(df, tmp, row.names = FALSE)
  on.exit(unlink(tmp))
  # The all-NA "Ghost" column is non-numeric, so the reader's marker filter
  # already excludes it upstream; construction still succeeds cleanly.
  obj <- ReadSpatial(tmp, filter = NA)
  expect_false("Ghost" %in% Markers(obj))
  expect_true("CD3" %in% Markers(obj))
})
