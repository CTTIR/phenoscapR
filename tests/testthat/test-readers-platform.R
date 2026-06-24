# Platform readers built on ReadMatrixCoords(): the general matrix+coords
# reader (all input shapes and error paths) plus the Xenium / CosMx / MERSCOPE
# convenience wrappers.

make_expr_meta <- function(n = 8L) {
  expr <- data.frame(
    cell_id = seq_len(n),
    fov = 1L,
    CD3 = as.numeric(seq_len(n)),
    CD8 = as.numeric(rev(seq_len(n))),
    label = letters[seq_len(n)]   # non-numeric column, must be dropped
  )
  meta <- data.frame(
    cell_id = seq_len(n),
    x = as.numeric(seq_len(n)),
    y = as.numeric(rev(seq_len(n)))
  )
  list(expr = expr, meta = meta)
}

test_that("ReadMatrixCoords drops non-numeric and id columns", {
  d <- make_expr_meta()
  obj <- ReadMatrixCoords(d$expr, d$meta, cell_id_col = "cell_id",
                          id_cols = "fov")
  expect_s4_class(obj, "SpatialCellData")
  expect_setequal(Markers(obj), c("CD3", "CD8"))
  expect_equal(NCells(obj), 8L)
})

test_that("ReadMatrixCoords accepts a numeric matrix directly", {
  m <- matrix(as.numeric(1:40), nrow = 10,
              dimnames = list(NULL, c("CD3", "CD8", "CD20", "PanCK")))
  meta <- data.frame(x = runif(10), y = runif(10))
  obj <- ReadMatrixCoords(m, meta)
  expect_equal(NCells(obj), 10L)
  expect_setequal(Markers(obj), c("CD3", "CD8", "CD20", "PanCK"))
})

test_that("ReadMatrixCoords transposes markers-by-cells input", {
  m <- matrix(as.numeric(1:40), nrow = 4,
              dimnames = list(c("CD3", "CD8", "CD20", "PanCK"), NULL))
  meta <- data.frame(x = runif(10), y = runif(10))
  obj <- ReadMatrixCoords(m, meta, transpose = TRUE)
  expect_equal(NCells(obj), 10L)
  expect_equal(NMarkers(obj), 4L)
})

test_that("ReadMatrixCoords reads CSV file paths via fread", {
  d <- make_expr_meta(6L)
  ef <- withr::local_tempfile(fileext = ".csv")
  mf <- withr::local_tempfile(fileext = ".csv")
  write.csv(d$expr, ef, row.names = FALSE)
  write.csv(d$meta, mf, row.names = FALSE)
  obj <- ReadMatrixCoords(ef, mf, cell_id_col = "cell_id", id_cols = "fov")
  expect_equal(NCells(obj), 6L)
  expect_setequal(Markers(obj), c("CD3", "CD8"))
})

test_that("ReadMatrixCoords matches rows on a shared cell id", {
  d <- make_expr_meta(6L)
  # Shuffle metadata rows; matching on cell_id must restore alignment.
  d$meta <- d$meta[c(6, 1, 4, 2, 5, 3), ]
  obj <- ReadMatrixCoords(d$expr, d$meta, cell_id_col = "cell_id",
                          id_cols = "fov")
  expect_equal(NCells(obj), 6L)
})

test_that("ReadMatrixCoords errors on missing coordinate columns", {
  d <- make_expr_meta()
  bad <- d$meta
  names(bad)[names(bad) == "x"] <- "X_centroid"
  expect_error(
    ReadMatrixCoords(d$expr, bad, cell_id_col = "cell_id", id_cols = "fov"),
    "Coordinate columns"
  )
})

test_that("ReadMatrixCoords errors on unmatchable cell ids", {
  d <- make_expr_meta(6L)
  d$meta$cell_id <- d$meta$cell_id + 100L  # none present in expression
  expect_error(
    ReadMatrixCoords(d$expr, d$meta, cell_id_col = "cell_id", id_cols = "fov"),
    "absent from the expression"
  )
})

test_that("ReadMatrixCoords errors on a row-count mismatch without an id", {
  expr <- matrix(as.numeric(1:20), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8")))
  meta <- data.frame(x = runif(8), y = runif(8))  # 8 != 10
  expect_error(ReadMatrixCoords(expr, meta), "provide cell_id_col")
})

test_that("ReadXenium presets the centroid coordinate columns", {
  expr <- data.frame(cell_id = 1:5, GeneA = as.numeric(1:5),
                     GeneB = as.numeric(5:1))
  cells <- data.frame(cell_id = 1:5, x_centroid = runif(5),
                      y_centroid = runif(5))
  obj <- ReadXenium(expr, cells)
  expect_s4_class(obj, "SpatialCellData")
  expect_equal(NCells(obj), 5L)
  expect_setequal(Markers(obj), c("GeneA", "GeneB"))
})

test_that("ReadCosMx presets the global-pixel columns and drops fov/cell_ID", {
  expr <- data.frame(fov = 1L, cell_ID = 1:5, GeneA = as.numeric(1:5),
                     GeneB = as.numeric(5:1))
  meta <- data.frame(cell_ID = 1:5, CenterX_global_px = runif(5),
                     CenterY_global_px = runif(5))
  obj <- ReadCosMx(expr, meta)
  expect_equal(NCells(obj), 5L)
  expect_setequal(Markers(obj), c("GeneA", "GeneB"))
})

test_that("ReadMERSCOPE presets the center_x/center_y columns", {
  expr <- data.frame(cell = 1:5, GeneA = as.numeric(1:5),
                     GeneB = as.numeric(5:1))
  meta <- data.frame(cell = 1:5, center_x = runif(5), center_y = runif(5))
  obj <- ReadMERSCOPE(expr, meta)
  expect_equal(NCells(obj), 5L)
  expect_setequal(Markers(obj), c("GeneA", "GeneB"))
})
