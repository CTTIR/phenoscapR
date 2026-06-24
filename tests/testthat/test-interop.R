# Ecosystem converters: Seurat (installed here, full round-trip) and
# SpatialExperiment (Bioconductor; error/skip paths). Missing-package and
# unsupported-input branches are checked by mocking requireNamespace().

data(phenoscapR_example)
one <- local({
  o <- phenoscapR_example[phenoscapR_example$sample_id == "tonsil_A", ]
  o@meta_data$phenotype <- o@meta_data$phenotype_true
  o
})

test_that("as_Seurat() errors when Seurat is unavailable", {
  local_mocked_bindings(
    requireNamespace = function(package, ...) !identical(package, "Seurat"),
    .package = "base"
  )
  expect_error(as_Seurat(one), "requires the 'Seurat' package")
})

test_that("as_SpatialExperiment() errors when the package is unavailable", {
  local_mocked_bindings(
    requireNamespace = function(package, ...)
      !identical(package, "SpatialExperiment"),
    .package = "base"
  )
  expect_error(as_SpatialExperiment(one),
               "requires the 'SpatialExperiment' package")
})

test_that("as_SpatialCellData() rejects unsupported input", {
  expect_error(as_SpatialCellData(list(a = 1)),
               "supports Seurat and SpatialExperiment")
  expect_error(as_SpatialCellData(data.frame(x = 1)),
               "supports Seurat and SpatialExperiment")
})

test_that("as_Seurat() builds an object carrying counts, data and coords", {
  skip_if_not_installed("Seurat")
  skip_if_not_installed("SeuratObject")
  se <- as_Seurat(one)
  expect_s4_class(se, "Seurat")
  expect_equal(ncol(se), NCells(one))
  expect_true(all(c("x", "y") %in% colnames(se[[]])))
  expect_true("spatial" %in% SeuratObject::Reductions(se))
  emb <- SeuratObject::Embeddings(se, "spatial")
  expect_equal(nrow(emb), NCells(one))
})

test_that("as_SpatialCellData() imports a Seurat object via x/y metadata", {
  skip_if_not_installed("Seurat")
  se <- as_Seurat(one)
  back <- as_SpatialCellData(se)
  expect_s4_class(back, "SpatialCellData")
  expect_equal(NCells(back), NCells(one))
  expect_setequal(Markers(back), Markers(one))
  # Coordinates survive the round trip.
  expect_equal(unname(Coords(back)$x), unname(Coords(one)$x), tolerance = 1e-6)
})

test_that("as_SpatialCellData() falls back to the spatial reduction", {
  skip_if_not_installed("Seurat")
  skip_if_not_installed("SeuratObject")
  se <- as_Seurat(one)
  # Drop the x/y metadata so the 'spatial' reduction path is used instead.
  se@meta.data$x <- NULL
  se@meta.data$y <- NULL
  back <- as_SpatialCellData(se)
  expect_s4_class(back, "SpatialCellData")
  expect_equal(NCells(back), NCells(one))
})

test_that("as_SpatialCellData() errors on a Seurat object with no coords", {
  skip_if_not_installed("Seurat")
  skip_if_not_installed("SeuratObject")
  se <- as_Seurat(one)
  se@meta.data$x <- NULL
  se@meta.data$y <- NULL
  se@reductions[["spatial"]] <- NULL
  expect_error(as_SpatialCellData(se), "No coordinates found")
})

test_that("as_SpatialExperiment() round-trips when the package is present", {
  skip_if_not_installed("SpatialExperiment")
  skip_if_not_installed("SummarizedExperiment")
  spe <- as_SpatialExperiment(one)
  expect_s4_class(spe, "SpatialExperiment")
  expect_equal(ncol(spe), NCells(one))
  back <- as_SpatialCellData(spe)
  expect_s4_class(back, "SpatialCellData")
  expect_equal(NCells(back), NCells(one))
})
