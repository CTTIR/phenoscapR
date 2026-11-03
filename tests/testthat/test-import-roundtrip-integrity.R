# Public synthetic fixtures distinguish identity, numeric values, and geometry.
.integrity_qupath <- function(images) {
  data.frame(Image = images, `Object ID` = paste0("cell", seq_along(images)),
             `Centroid X um` = seq_along(images),
             `Centroid Y um` = seq_along(images) * 10,
             `Cell: CD3 mean` = seq_along(images) * 3, check.names = FALSE)
}

.integrity_spatial <- function() {
  counts <- matrix(c(2, 8, 14, 20, 7, 5, 3, 1), 4,
                   dimnames = list(paste0("source", 1:4), c("CD3", "CD8")))
  CreateSpatialObject(counts, data.frame(x = c(1, 7, 2, 9), y = c(6, 3, 11, 4)),
                      data.frame(cell_id = paste0("cell", 1:4), sample_id = "sample"))
}

test_that("coordinate recognition cannot consume a marker ending in y", {
  path <- withr::local_tempfile(fileext = ".csv")
  input <- data.frame(`Cell intensity` = c(400, 500, 600),
                      `Cell X Position` = c(1, 8, 20),
                      `Cell Y Position` = c(2, 12, 25), CD3 = 1:3,
                      check.names = FALSE)
  write.csv(input, path, row.names = FALSE)
  bytes <- readBin(path, "raw", file.info(path)$size)
  actual <- read_spatial(path)
  expect_equal(actual$x, input[["Cell X Position"]])
  expect_equal(actual$y, input[["Cell Y Position"]])
  expect_equal(actual[["Cell intensity"]], input[["Cell intensity"]])
  expect_identical(readBin(path, "raw", file.info(path)$size), bytes)

  input[["Centroid X um"]] <- c(30, 40, 50)
  write.csv(input, path, row.names = FALSE)
  expect_error(read_spatial(path), "Ambiguous x coordinate")
  input$x <- c(100, 200, 300)
  write.csv(input, path, row.names = FALSE)
  expect_equal(read_spatial(path)$x, input$x)
})

test_that("QuPath source images remain exact and cannot pool distinct identities", {
  directory <- withr::local_tempdir()
  path <- file.path(directory, "cells.csv")
  images <- c("scan - roi1", "")
  write.csv(.integrity_qupath(images), path, row.names = FALSE)
  actual <- read_spatial(path, sample_id = "fallback", markers = "CD3")
  expect_identical(actual$sample_id, c("scan", "fallback"))
  expect_identical(actual$source_image, images)
  object <- ReadSpatial(path, sample_id = "fallback", markers = "CD3")
  expect_identical(object@meta_data$source_image, images)
  expect_identical(Markers(object), "CD3")

  write.csv(.integrity_qupath(c("scan - slideA", "scan - slideB")), path,
            row.names = FALSE)
  expect_error(read_spatial(path), "Distinct QuPath Image labels")
  write.csv(.integrity_qupath("scan - slideA"), path, row.names = FALSE)
  write.csv(.integrity_qupath("scan - slideB"), file.path(directory, "other.csv"),
            row.names = FALSE)
  expect_error(read_spatial(directory), "Distinct QuPath Image labels")
})

test_that("matrix readers refuse factor codes and retain matched numeric geometry", {
  expr <- data.frame(cell_id = c("a", "b"), CD3 = c(7, 11))
  meta <- data.frame(cell_id = c("b", "a"), x = factor(c("20", "10")), y = c(4, 9))
  original <- meta
  expect_error(ReadMatrixCoords(expr, meta, cell_id_col = "cell_id"), "real numeric")
  expect_identical(meta, original)
  meta$x <- c(20, 10)
  actual <- ReadMatrixCoords(expr, meta, cell_id_col = "cell_id")
  expect_equal(unname(actual@counts[, "CD3"]), c(11, 7))
  expect_identical(actual@coords$x, c(20, 10))
  expect_identical(actual@coords$y, c(4, 9))
})

test_that("SpatialExperiment retains normalized values and unchanged marker identities", {
  skip_if_not_installed("SpatialExperiment")
  object <- NormaliseData(.integrity_spatial(), method = "minmax")
  colnames(object@counts) <- colnames(object@data) <- c("CD3_high", "CD8")
  original <- object
  converted <- as_SpatialExperiment(object)
  actual <- as_SpatialCellData(converted)
  expect_identical(actual@counts, object@counts)
  expect_identical(actual@data, object@data)
  expect_equal(actual@coords, object@coords, ignore_attr = TRUE)
  expect_identical(actual@meta_data$cell_id, object@meta_data$cell_id)
  expect_identical(Markers(actual), c("CD3_high", "CD8"))
  expect_identical(object, original)
})

test_that("ecosystem import preserves missing features and source cell names", {
  skip_if_not_installed("SpatialExperiment")
  counts <- matrix(c(2, 8, NA_real_, NA_real_), 2,
                   dimnames = list(c("source-b", "source-a"), c("CD3", "missing")))
  normalized <- counts / 8
  spe <- SpatialExperiment::SpatialExperiment(
    assays = list(counts = t(counts), logcounts = t(normalized)),
    spatialCoords = matrix(c(3, 10, 1, 9), 2, dimnames = list(NULL, c("x", "y"))))
  actual <- as_SpatialCellData(spe)
  expect_identical(actual@counts, counts)
  expect_identical(actual@data, normalized)
  expect_identical(actual@meta_data$cell_id, rownames(counts))
  expect_identical(actual@meta_data$sample_id, as.character(SummarizedExperiment::colData(spe)$sample_id))
  SummarizedExperiment::assay(spe, "logcounts") <- NULL
  fallback <- as_SpatialCellData(spe)
  expect_identical(fallback@data, counts)
  expect_true(methods::validObject(fallback))
})

test_that("Seurat retains its actual normalized layer and refuses marker rewrites", {
  skip_if_not_installed("Seurat")
  object <- NormaliseData(.integrity_spatial(), method = "minmax")
  original <- object
  actual <- as_SpatialCellData(as_Seurat(object))
  expect_identical(unname(actual@counts), unname(object@counts))
  expect_identical(unname(actual@data), unname(object@data))
  expect_identical(actual@meta_data$cell_id, object@meta_data$cell_id)
  expect_equal(actual@coords, object@coords, ignore_attr = TRUE)
  expect_identical(object, original)
  colnames(object@counts) <- colnames(object@data) <- c("CD3_high", "CD8")
  expect_error(as_Seurat(object), "as_SpatialExperiment")
})

test_that("Seurat count-only input keeps raw values without fabricating normalization", {
  skip_if_not_installed("Seurat")
  counts <- matrix(c(2, 8, 14, 20, 7, 5, 3, 1), 2,
                   dimnames = list(c("CD3", "CD8"), paste0("cell", 1:4)))
  se <- suppressWarnings(Seurat::CreateSeuratObject(counts = counts,
      meta.data = data.frame(x = 1:4, y = 5:8, row.names = colnames(counts))))
  actual <- as_SpatialCellData(se)
  expect_identical(actual@counts, t(counts))
  expect_identical(actual@data, t(counts))
  expect_identical(actual@meta_data$cell_id, colnames(counts))
})

test_that("partial normalized Seurat layers are refused rather than discarded", {
  skip_if_not_installed("Seurat")
  skip_if_not_installed("SeuratObject", minimum_version = "5.0.0")
  counts <- matrix(1:8 + 0, 2,
                   dimnames = list(c("CD3", "CD8"), paste0("cell", 1:4)))
  assay <- SeuratObject::CreateAssay5Object(counts = Matrix::Matrix(counts, sparse = TRUE))
  assay <- SeuratObject::SetAssayData(assay, layer = "data",
                                      new.data = counts[, 1:2, drop = FALSE] / 8)
  se <- suppressWarnings(Seurat::CreateSeuratObject(counts = assay,
      meta.data = data.frame(x = 1:4, y = 5:8, row.names = colnames(counts))))
  expect_error(as_SpatialCellData(se), "same cells and markers")
})


test_that("CSV identifiers retain leading zeros without changing measurement types", {
  directory <- withr::local_tempdir()
  expression <- file.path(directory, "expression.csv")
  metadata <- file.path(directory, "metadata.csv")
  writeLines(c("cell_id,CD3", "001,010", "1,020"), expression)
  writeLines(c("cell_id,sample_id,x,y", "1,002,030,040", "001,002,010,020"), metadata)
  object <- ReadMatrixCoords(expression, metadata, cell_id_col = "cell_id")
  expect_identical(object@meta_data$cell_id, c("1", "001"))
  expect_identical(object@meta_data$sample_id, c("002", "002"))
  expect_equal(unname(object@counts[, "CD3"]), c(20, 10))
  expect_identical(object@coords$x, c(30L, 10L))
  expect_identical(object@coords$y, c(40L, 20L))

  flat <- file.path(directory, "flat.csv")
  writeLines(c("Cell ID,sample_id,Cell X Position,Cell Y Position,CD3",
               "001,002,010,020,010", "1,002,030,040,020"), flat)
  table <- read_spatial(flat)
  expect_identical(table$cell_id, c("001", "1"))
  expect_identical(table$sample_id, c("002", "002"))
  expect_identical(table$CD3, c(10L, 20L))
  expect_identical(table$x, c(10L, 30L))
  expect_identical(ReadSpatial(flat)@meta_data$cell_id, c("001", "1"))

  qupath <- file.path(directory, "qupath.csv")
  writeLines(c("Image,Object ID,Centroid X um,Centroid Y um,Cell: CD3 mean",
               "001,0002,010,020,030", "1,2,040,050,060"), qupath)
  table <- read_spatial(qupath)
  expect_identical(table$sample_id, c("001", "1"))
  expect_identical(table$source_image, c("001", "1"))
  expect_identical(table$cell_id, c("0002", "2"))
  expect_identical(table$CD3, c(30L, 60L))
})
