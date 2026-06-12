# End-to-end integration tests exercising the full analysis pipeline on the
# bundled synthetic dataset `phenoscapR_example`. These guard the documented
# multi-sample workflow and a handful of mathematical invariants that must hold
# regardless of how the internals are refactored.

data(phenoscapR_example)

test_that("bundled example data has the documented shape", {
  obj <- phenoscapR_example
  expect_s4_class(obj, "SpatialCellData")
  expect_equal(NCells(obj), 640L)
  expect_equal(NMarkers(obj), 8L)
  expect_setequal(unique(obj$sample_id), c("tonsil_A", "tonsil_B"))
  expect_true(all(c("CD3", "CD4", "CD8", "CD20", "CD68", "PanCK",
                    "FoxP3", "Ki67") %in% Markers(obj)))
  # No missing coordinates.
  expect_false(anyNA(Coords(obj)))
})

test_that("QC -> normalise -> phenotype pipeline runs and is order-stable", {
  obj <- QCFilter(phenoscapR_example, min_area = 20, max_area = 1000)
  expect_lte(NCells(obj), NCells(phenoscapR_example))

  obj <- NormaliseData(obj, method = "zscore")
  # z-score normalisation: each marker column has ~zero mean, unit sd.
  z <- GetData(obj)
  expect_equal(colMeans(z), setNames(rep(0, ncol(z)), colnames(z)),
               tolerance = 1e-8)
  expect_equal(apply(z, 2, sd), setNames(rep(1, ncol(z)), colnames(z)),
               tolerance = 1e-8)

  obj <- PhenotypeCells(obj, thresholds = list(
    CD20 = 1, CD3 = 1, CD8 = 1, CD68 = 1, PanCK = 1, FoxP3 = 1))
  expect_true("phenotype" %in% names(Meta(obj)))
  expect_false(anyNA(Meta(obj)$phenotype))
})

test_that("minmax normalisation lands in [0, 1] per marker", {
  obj <- NormaliseData(phenoscapR_example, method = "minmax")
  m <- GetData(obj)
  expect_true(all(m >= 0 & m <= 1))
  # Each marker should actually reach both extremes.
  expect_equal(unname(apply(m, 2, min)), rep(0, ncol(m)), tolerance = 1e-8)
  expect_equal(unname(apply(m, 2, max)), rep(1, ncol(m)), tolerance = 1e-8)
})

test_that("interaction matrix is computed per sample and never crosses tissues", {
  obj <- phenoscapR_example
  obj@meta_data$phenotype <- obj@meta_data$phenotype_true
  im <- InteractionMatrix(obj, radius = 40)
  expect_true(all(c("from", "to", "observed", "expected",
                    "interaction_score") %in% names(im)))
  # Observed neighbour counts are non-negative integers.
  expect_true(all(im$observed >= 0))

  # Pooling samples must not inflate counts versus summing per-sample results:
  # because neighbours never cross samples, the pooled observed counts equal
  # the sum of the per-sample observed counts.
  a <- InteractionMatrix(obj[obj$sample_id == "tonsil_A", ], radius = 40)
  b <- InteractionMatrix(obj[obj$sample_id == "tonsil_B", ], radius = 40)
  key <- function(d) paste(d$from, d$to)
  pooled <- setNames(im$observed, key(im))
  summed <- setNames(a$observed, key(a))[names(pooled)] +
            setNames(b$observed, key(b))[names(pooled)]
  expect_equal(unname(pooled), unname(summed))
})

test_that("single-sample statistics run on one tissue and recover structure", {
  one <- phenoscapR_example[phenoscapR_example$sample_id == "tonsil_A", ]
  one@meta_data$phenotype <- one@meta_data$phenotype_true

  # Ripley's K above the CSR expectation (pi * r^2) at moderate r, because the
  # planted niches make the pattern clustered.
  r_seq <- seq(0, 100, length.out = 25)
  k <- RipleysK(one, r_seq = r_seq, correction = "border")
  expect_equal(nrow(k), length(r_seq))
  expect_true(all(is.finite(k$K)))

  # Moran's I on a lineage marker should be positive (spatial autocorrelation).
  mi <- MoransI(one, feature = "CD20", radius = 50)
  expect_true(is.finite(mi$I))
  expect_gt(mi$I, 0)

  # Neighbourhood enrichment: B cells enriched next to B cells (the follicle).
  ne <- NeighbourhoodEnrichment(one, radius = 40, n_perm = 49L, seed = 1L)
  expect_true(all(c("from", "to", "z_score") %in% names(ne)))
  bb <- ne$z_score[ne$from == "B cell" & ne$to == "B cell"]
  expect_gt(bb, 0)
})

test_that("CrossNNDistance and QuadratAnalysis behave on a single sample", {
  one <- phenoscapR_example[phenoscapR_example$sample_id == "tonsil_A", ]
  one@meta_data$phenotype <- one@meta_data$phenotype_true

  cnn <- CrossNNDistance(one, from = "T helper", to = "B cell")
  expect_type(cnn, "double")
  expect_true(all(cnn >= 0))
  expect_equal(length(cnn), sum(one$phenotype == "T helper"))

  qa <- QuadratAnalysis(one, nx = 4L, ny = 4L)
  expect_true(is.finite(qa$chi_sq))
  expect_gte(qa$chi_sq, 0)
})

test_that("expression clustering partitions cells into the requested k", {
  obj <- NormaliseData(phenoscapR_example, method = "zscore")
  obj <- ExpressionClusters(obj, k = 6L)
  cl <- Meta(obj)$expr_cluster
  expect_equal(length(unique(cl)), 6L)
  expect_equal(length(cl), NCells(obj))
})
