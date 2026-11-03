test_that("zero-row logical placeholders become typed empty numeric objects", {
  counts <- matrix(nrow = 0L, ncol = 2L, dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = logical(0), y = logical(0))
  before_counts <- counts
  before_coords <- coords
  expect_no_warning(object <- CreateSpatialObject(counts, coords))
  expect_identical(dim(object@counts), c(0L, 2L))
  expect_identical(typeof(object@counts), "double")
  expect_identical(object@data, object@counts)
  expect_identical(Markers(object), c("CD3", "CD8"))
  expect_identical(object@coords, data.frame(x = numeric(0), y = numeric(0)))
  expect_true(methods::validObject(object))
  expect_identical(counts, before_counts)
  expect_identical(coords, before_coords)
})

test_that("header-only spatial and matrix CSV imports retain valid empty results", {
  path <- withr::local_tempfile(fileext = ".csv")
  writeLines("Cell ID,Cell X Position,Cell Y Position,CD3", path)
  expect_no_warning(spatial <- ReadSpatial(path))
  expect_identical(dim(spatial@counts), c(0L, 0L))
  expect_identical(typeof(spatial@counts), "double")
  expect_identical(spatial@coords, data.frame(x = numeric(0), y = numeric(0)))
  expect_true(methods::validObject(spatial))

  expression <- withr::local_tempfile(fileext = ".csv")
  metadata <- withr::local_tempfile(fileext = ".csv")
  writeLines("cell_id,CD3", expression)
  writeLines("cell_id,x,y", metadata)
  expect_no_warning(paired <- ReadMatrixCoords(expression, metadata, cell_id_col = "cell_id"))
  expect_identical(dim(paired@counts), c(0L, 0L))
  expect_identical(typeof(paired@counts), "double")
  expect_identical(paired@coords, data.frame(x = numeric(0), y = numeric(0)))
  expect_identical(paired@meta_data$sample_id, character(0))
  expect_true(methods::validObject(paired))
})

test_that("empty canonicalization does not accept logical observations or factor coordinates", {
  expect_error(CreateSpatialObject(matrix(TRUE, 1L, 1L), data.frame(x = 1, y = 2)), "real numeric")
  expect_error(CreateSpatialObject(matrix(1, 1L, 1L), data.frame(x = TRUE, y = FALSE)), "real numeric")
  expect_error(CreateSpatialObject(matrix(numeric(0), 0L, 1L),
                                   data.frame(x = factor(character(0)), y = numeric(0))), "real numeric")
  expect_error(ReadMatrixCoords(data.frame(CD3 = numeric(0)),
                               data.frame(x = factor(character(0)), y = numeric(0))), "real numeric")
  expect_error(ReadMatrixCoords(data.frame(CD3 = 1),
                               data.frame(x = TRUE, y = FALSE)), "real numeric")
  # Stored objects still require numeric slots; canonicalization is a constructor boundary.
  object <- methods::new("SpatialCellData")
  object@counts <- object@data <- matrix(logical(0), 0L, 0L)
  expect_error(methods::validObject(object), "real numeric")
})

test_that("zero-marker matrices preserve cells after empty or all-missing input", {
  coords <- data.frame(x = c(1, 2), y = c(3, 4))
  counts <- matrix(nrow = 2L, ncol = 0L)
  expect_no_warning(object <- CreateSpatialObject(counts, coords))
  expect_identical(dim(object@counts), c(2L, 0L))
  expect_identical(typeof(object@counts), "double")
  expect_identical(object@coords, coords)
  expect_identical(NCells(object), 2L)
  expect_true(methods::validObject(object))
  expect_identical(typeof(counts), "logical")

  expect_warning(missing <- CreateSpatialObject(matrix(NA, 2L, 1L), coords), "all-NA")
  expect_identical(dim(missing@counts), c(2L, 0L))
  expect_identical(typeof(missing@counts), "double")
  expect_identical(missing@coords, coords)
  expect_true(methods::validObject(missing))
})

test_that("metadata-only and fully filtered spatial files preserve cell extent", {
  path <- withr::local_tempfile(fileext = ".csv")
  for (with_dapi in c(FALSE, TRUE)) {
    header <- "Cell ID,Cell X Position,Cell Y Position"
    rows <- c("001,1,3", "002,2,4")
    if (with_dapi) {
      header <- paste0(header, ",DAPI")
      rows <- paste0(rows, ",10")
    }
    writeLines(c(header, rows), path)
    expect_no_warning(object <- ReadSpatial(path, sample_id = "0001"))
    expect_identical(dim(object@counts), c(2L, 0L))
    expect_identical(typeof(object@counts), "double")
    expect_identical(object@meta_data$cell_id, c("001", "002"))
    expect_identical(object@meta_data$sample_id, c("0001", "0001"))
    expect_equal(object@coords, data.frame(x = c(1, 2), y = c(3, 4)))
    expect_true(methods::validObject(object))
  }
})
