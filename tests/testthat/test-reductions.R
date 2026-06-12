# ---------------------------------------------------------------------------
# Dimensionality-reduction embeddings: PCA, UMAP, t-SNE, SONG
# ---------------------------------------------------------------------------

make_obj <- function(n = 60L, p = 10L, seed = 1L) {
  set.seed(seed)
  counts <- matrix(rnorm(n * p), nrow = n,
                   dimnames = list(NULL, paste0("M", seq_len(p))))
  coords <- data.frame(x = runif(n, 0, 100), y = runif(n, 0, 100))
  CreateSpatialObject(counts, coords)
}

test_that("RunPCA stores a pca reduction of the requested width", {
  obj <- RunPCA(make_obj(), n_pcs = 5L)
  emb <- Embeddings(obj, "pca")
  expect_equal(nrow(emb), 60L)
  expect_equal(ncol(emb), 5L)
  expect_true("pca" %in% Reductions(obj))
  expect_equal(colnames(emb), paste0("PC_", 1:5))
})

test_that("RunPCA caps the number of PCs at the data rank", {
  obj <- RunPCA(make_obj(n = 60L, p = 4L), n_pcs = 30L)
  expect_lte(ncol(Embeddings(obj, "pca")), 4L)
})

test_that("RunUMAP stores a 2D embedding", {
  skip_if_not_installed("uwot")
  obj <- RunUMAP(make_obj(), seed = 1L)
  emb <- Embeddings(obj, "umap")
  expect_equal(dim(emb), c(60L, 2L))
  expect_equal(colnames(emb), c("UMAP_1", "UMAP_2"))
})

test_that("RunUMAP densmap option works", {
  skip_if_not_installed("uwot")
  skip_if(!exists("densmap", where = asNamespace("uwot")))
  obj <- RunUMAP(make_obj(), densmap = TRUE, seed = 1L)
  expect_equal(dim(Embeddings(obj, "umap")), c(60L, 2L))
})

test_that("RunTSNE stores a 2D embedding and caps perplexity", {
  skip_if_not_installed("Rtsne")
  obj <- RunTSNE(make_obj(n = 40L), seed = 1L)  # perplexity must auto-cap
  emb <- Embeddings(obj, "tsne")
  expect_equal(dim(emb), c(40L, 2L))
  expect_equal(colnames(emb), c("tSNE_1", "tSNE_2"))
})

test_that("RunSONG stores a 2D embedding", {
  skip_if_not_installed("songR")
  # songR's compiled song() segfaults on some platforms (observed on Windows
  # R 4.5.2); only run the live call when explicitly opted in.
  skip_if_not(identical(Sys.getenv("PHENOSCAPR_TEST_SONG"), "true"),
              "set PHENOSCAPR_TEST_SONG=true to run the live SONG embedding")
  obj <- RunSONG(make_obj(), seed = 1L)
  emb <- Embeddings(obj, "song")
  expect_equal(dim(emb), c(60L, 2L))
  expect_equal(colnames(emb), c("SONG_1", "SONG_2"))
})

test_that("Run* functions error clearly when the backend is unavailable", {
  # Force the missing-package path by requesting a backend we know is absent.
  obj <- make_obj()
  expect_error(.require_pkg("definitelyNotInstalled123", "RunFoo"),
               "requires the 'definitelyNotInstalled123' package")
})

test_that("embeddings are subset along with the object", {
  obj <- RunPCA(make_obj(), n_pcs = 5L)
  sub <- obj[1:10, ]
  expect_equal(nrow(Embeddings(sub, "pca")), 10L)
})

test_that("EmbeddingPlot returns a ggplot using the reduction", {
  obj <- RunPCA(make_obj(), n_pcs = 5L)
  obj <- PhenotypeCells(obj, thresholds = list(M1 = 0))
  p <- EmbeddingPlot(obj, reduction = "pca", colour_by = "phenotype")
  expect_s3_class(p, "gg")
})

test_that("EmbeddingPlot errors on a missing reduction", {
  obj <- make_obj()
  expect_error(EmbeddingPlot(obj, reduction = "umap"), "not found")
})
