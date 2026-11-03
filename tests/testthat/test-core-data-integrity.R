test_that("cell objects reject nonnumeric measurements before threshold comparison", {
  counts <- matrix(c("10", "2", "8"), 3, 1, dimnames = list(NULL, "CD3"))
  coords <- data.frame(x = 1:3, y = 2:4)
  expect_error(CreateSpatialObject(counts, coords), "numeric")
  expect_error(phenotype_cells(data.table::data.table(CD3 = counts[, 1]),
                              thresholds = list(CD3 = 5)), "numeric")
  expect_error(CreateSpatialObject(matrix(c(1, Inf, 3), 3, 1), coords), "infinite")
})

test_that("validity checks align raw and processed axes even without cells", {
  counts <- matrix(1:6, 3, 2, dimnames = list(letters[1:3], c("CD3", "CD8")))
  object <- CreateSpatialObject(counts, data.frame(x = 1:3, y = 2:4))
  bad <- object
  bad@data <- bad@data[, 2:1, drop = FALSE]
  expect_error(methods::validObject(bad), "marker names")
  expect_error(PhenotypeCells(bad, list(CD3 = 3)), "marker names")
  expect_error(NormaliseData(bad), "marker names")
  bad@data <- object@data[3:1, , drop = FALSE]
  expect_error(methods::validObject(bad), "row and marker names")
  bad@data <- matrix(1:3, 3, 1, dimnames = list(NULL, "other"))
  expect_error(methods::validObject(bad), "dimensions")
  expect_error(methods::new("SpatialCellData", counts = matrix(numeric(), 0, 1),
                           data = matrix(1:4, 2, 2), coords = data.frame(x = 1, y = 2),
                           meta_data = data.frame(cell_id = "a", sample_id = "s")),
               "dimensions")
  expect_true(methods::validObject(methods::new("SpatialCellData")))
  expect_identical(object@counts, counts)
})

test_that("empty numeric objects retain typed marker and metadata schemas", {
  counts <- matrix(numeric(), 0, 2, dimnames = list(NULL, c("CD3", "CD8")))
  expect_no_warning(object <- CreateSpatialObject(counts, data.frame(x = numeric(), y = numeric())))
  expect_identical(Markers(object), c("CD3", "CD8"))
  expect_identical(GetData(object), counts)
  expect_true(methods::validObject(object))
  bad <- object
  bad@meta_data <- data.frame(other = character())
  expect_error(methods::validObject(bad), "cell_id and sample_id")
  # Duplicating cells is an explicitly supported subset operation, not a new
  # identity constraint imposed by the numeric/schema validation.
  full <- CreateSpatialObject(matrix(1:4, 2, 2, dimnames = list(NULL, c("A", "B"))),
                              data.frame(x = 1:2, y = 3:4))
  expect_identical(NCells(full[c(1, 1), ]), 2L)
})

test_that("normalisation retains scale-invariant finite z scores", {
  for (unit in c(1, 1e200, 1e-160, 5e-162, 1e-200, 2^-1074)) {
    values <- (1:3) * unit
    dt <- data.table::data.table(M = c(values, NA_real_))
    before <- data.table::copy(dt)
    object <- CreateSpatialObject(as.matrix(dt), data.frame(x = 1:4, y = 0))
    # Three equally spaced observations have sample-standardised values -1,0,1.
    expect_equal(normalise_markers(dt, "zscore", "M")$M,
                 c(-1, 0, 1, NA_real_), tolerance = 1e-14)
    normalized <- NormaliseData(object, "zscore")
    expect_equal(as.vector(GetData(normalized)), c(-1, 0, 1, NA_real_), tolerance = 1e-14)
    expect_identical(GetData(normalized, "counts"), GetData(object, "counts"))
    expect_identical(dt, before)
  }
})

test_that("minmax normalization handles finite opposite-sign endpoints", {
  values <- c(-.Machine$double.xmax, 0, .Machine$double.xmax, NA_real_)
  dt <- data.table::data.table(M = values)
  expect_identical(normalise_markers(dt, "minmax", "M")$M, c(0, 0.5, 1, NA_real_))
  object <- CreateSpatialObject(as.matrix(dt), data.frame(x = 1:4, y = 0))
  expect_identical(as.vector(GetData(NormaliseData(object, "minmax"))), c(0, 0.5, 1, NA_real_))
  expect_identical(GetData(object, "counts")[, 1], values)
})

test_that("ordinary normalization, missing values and invalid infinities stay explicit", {
  x <- c(-7, 2, 5, NA_real_)
  expect_identical(.normalise_vector(x, "zscore"), (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE))
  expect_identical(.normalise_vector(x, "minmax"), (x + 7) / 12)
  for (method in c("zscore", "minmax", "quantile")) {
    expect_identical(.normalise_vector(c(NA_real_, NaN), method), c(NA_real_, NaN))
    expect_identical(.normalise_vector(numeric(), method), numeric())
    expect_error(normalise_markers(data.table::data.table(M = c(1, Inf)), method, "M"), "infinity")
  }
})
