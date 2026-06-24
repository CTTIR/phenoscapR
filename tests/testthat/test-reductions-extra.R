# Reduction paths the curated test-reductions.R leaves uncovered: variance
# accessors and the scree plot, the DimPlot alias and dark-theme embedding plot,
# the non-PCA embedding input, the Embeddings() error message, the songR install
# hint, and a mocked RunSONG backend.

make_obj <- function(n = 60L, p = 10L, seed = 1L) {
  set.seed(seed)
  counts <- matrix(rnorm(n * p), nrow = n,
                   dimnames = list(NULL, paste0("M", seq_len(p))))
  coords <- data.frame(x = runif(n, 0, 100), y = runif(n, 0, 100))
  CreateSpatialObject(counts, coords)
}

test_that("VarianceExplained returns one percentage per PC", {
  obj <- RunPCA(make_obj(), n_pcs = 5L)
  pv <- VarianceExplained(obj)
  expect_length(pv, 5L)
  expect_named(pv, paste0("PC_", 1:5))
  expect_true(all(pv >= 0))
  expect_lt(sum(pv), 100.0001)
})

test_that("VarianceExplained errors without a PCA reduction", {
  expect_error(VarianceExplained(make_obj()), "Run RunPCA")
})

test_that("VarianceExplained errors when variance info is missing (old PCA)", {
  obj <- RunPCA(make_obj(), n_pcs = 5L)
  emb <- obj@reductions[["pca"]]
  attr(emb, "percent_var") <- NULL
  obj@reductions[["pca"]] <- emb
  expect_error(VarianceExplained(obj), "older version")
})

test_that("ScreePlot returns a ggplot and honours n_pcs", {
  skip_if_not_installed("ggplot2")
  obj <- RunPCA(make_obj(), n_pcs = 8L)
  expect_s3_class(ScreePlot(obj), "gg")
  p <- ScreePlot(obj, n_pcs = 3L)
  expect_s3_class(p, "gg")
  # capped to 3 bars in the underlying data
  expect_equal(nrow(p$data), 3L)
})

test_that("DimPlot is an alias for EmbeddingPlot", {
  skip_if_not_installed("ggplot2")
  obj <- RunPCA(make_obj(), n_pcs = 5L)
  obj <- PhenotypeCells(obj, thresholds = list(M1 = 0))
  p1 <- EmbeddingPlot(obj, reduction = "pca")
  p2 <- DimPlot(obj, reduction = "pca")
  expect_s3_class(p2, "gg")
  expect_equal(p1$labels, p2$labels)
})

test_that("EmbeddingPlot supports a dark theme and errors on missing colour", {
  skip_if_not_installed("ggplot2")
  obj <- RunPCA(make_obj(), n_pcs = 5L)
  obj <- PhenotypeCells(obj, thresholds = list(M1 = 0))
  expect_s3_class(EmbeddingPlot(obj, reduction = "pca", dark_theme = TRUE), "gg")
  expect_error(EmbeddingPlot(obj, reduction = "pca", colour_by = "nope"),
               "not found in meta_data")
})

test_that("Embeddings lists available reductions in its error message", {
  obj <- RunPCA(make_obj(), n_pcs = 5L)
  err <- expect_error(Embeddings(obj, "umap"), "not found")
  expect_match(conditionMessage(err), "pca")
  # And reports 'none' when there are no reductions at all.
  err2 <- expect_error(Embeddings(make_obj(), "pca"), "not found")
  expect_match(conditionMessage(err2), "none")
})

test_that("non-PCA embedding input uses the marker matrix directly", {
  skip_if_not_installed("uwot")
  obj <- make_obj()
  emb_obj <- RunUMAP(obj, use_pca = FALSE, markers = c("M1", "M2", "M3"),
                     seed = 1L)
  expect_equal(dim(Embeddings(emb_obj, "umap")), c(60L, 2L))
})

test_that(".require_pkg gives the r-universe hint for songR", {
  local_mocked_bindings(
    requireNamespace = function(package, ...) !identical(package, "songR"),
    .package = "base"
  )
  err <- expect_error(RunSONG(make_obj()), "requires the 'songR' package")
  expect_match(conditionMessage(err), "cttir.r-universe.dev")
})

test_that("RunSONG stores a 2D embedding with a mocked backend", {
  obj <- make_obj(n = 30L)
  local_mocked_bindings(
    requireNamespace = function(...) TRUE,
    .package = "base"
  )
  fake_song <- function(x, ...) list(embedding = matrix(seq_len(nrow(x) * 2L),
                                                        ncol = 2L))
  local_mocked_bindings(song = fake_song, .package = "songR")
  res <- RunSONG(obj, seed = 1L)
  emb <- Embeddings(res, "song")
  expect_equal(dim(emb), c(30L, 2L))
  expect_equal(colnames(emb), c("SONG_1", "SONG_2"))
})
