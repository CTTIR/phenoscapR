# Smoke tests for every exported visualiser, driven by the bundled example
# data. Beyond guarding the plot layer, these exercise the documented end-to-end
# workflow (normalise -> phenotype -> neighbours -> density -> reductions ->
# plot) so the figures in the vignette and README cannot silently break.

data(phenoscapR_example)

# A fully analysed single-sample object reused across the plot tests.
fixture <- local({
  obj <- phenoscapR_example[phenoscapR_example$sample_id == "tonsil_A", ]
  obj@meta_data$phenotype <- obj@meta_data$phenotype_true
  obj <- NormaliseData(obj, method = "zscore")
  obj <- FindNeighbours(obj, k = 1L)
  obj <- CellDensity(obj, radius = 40)
  obj
})

feats <- c("CD3", "CD20", "PanCK")

test_that("spatial maps render", {
  expect_s3_class(CellMap(fixture), "gg")
  expect_s3_class(CellMap(fixture, colour_by = "sample_id"), "gg")
  expect_s3_class(DensityPlot(fixture), "gg")
})

test_that("per-marker distribution plots render", {
  expect_s3_class(FeaturePlot(fixture, features = feats), "gg")
  expect_s3_class(ViolinPlot(fixture, features = feats), "gg")
  expect_s3_class(BoxPlot(fixture, features = feats), "gg")
  expect_s3_class(RidgePlot(fixture, features = feats), "gg")
  expect_s3_class(DotPlot(fixture, features = feats), "gg")
  expect_s3_class(HistogramPlot(fixture, feature = "CD3"), "gg")
  expect_s3_class(HistogramPlot(fixture, feature = "CD3",
                                group_by = "phenotype"), "gg")
})

test_that("summary and QC plots render", {
  expect_s3_class(CompositionPlot(fixture, group_by = "phenotype"), "gg")
  expect_s3_class(MarkerHeatmap(fixture), "gg")
  expect_s3_class(QCPlot(fixture, x = "cell_area", y = "density"), "gg")
})

test_that("interaction and network plots render", {
  fixture@meta_data$phenotype <- fixture@meta_data$phenotype_true
  im <- InteractionMatrix(fixture, radius = 40)
  expect_s3_class(InteractionPlot(im), "gg")

  skip_if_not_installed("deldir")
  net <- DelaunayNetwork(fixture, max_edge = 60)
  expect_s3_class(SpatialNetworkPlot(net), "gg")
})

test_that("dimensionality-reduction embeddings plot", {
  obj <- RunPCA(fixture, n_pcs = 5L)
  expect_s3_class(DimPlot(obj, reduction = "pca"), "gg")
  expect_s3_class(EmbeddingPlot(obj, reduction = "pca"), "gg")

  skip_if_not_installed("uwot")
  obj <- RunUMAP(obj, dims = 5L, n_neighbors = 10L)
  expect_s3_class(DimPlot(obj, reduction = "umap"), "gg")
})

test_that("plot helpers validate their inputs", {
  expect_error(CellMap(fixture, colour_by = "nope"), "not found")
  expect_error(HistogramPlot(fixture, feature = "nope"), "not found")
  expect_error(QCPlot(fixture, x = "nope", y = "density"), "not found")
  expect_error(FeaturePlot(fixture, features = "nope"), "No matching features")
})
