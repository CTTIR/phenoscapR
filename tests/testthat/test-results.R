# Classed result objects: field access is preserved, print/autoplot work, and
# by_sample = TRUE maps single-window statistics across samples.

data(phenoscapR_example)
one <- local({
  o <- phenoscapR_example[phenoscapR_example$sample_id == "tonsil_A", ]
  o@meta_data$phenotype <- o@meta_data$phenotype_true
  o
})

test_that("results carry classes but keep underlying access", {
  rk <- RipleysK(one, r_seq = seq(0, 80, length.out = 15), correction = "border")
  expect_s3_class(rk, "phenoscapR_ripley")
  expect_true(is.data.frame(rk))
  expect_true(all(c("r", "K", "L") %in% names(rk)))   # $ access intact

  mi <- MoransI(one, feature = "CD20", radius = 40)
  expect_s3_class(mi, "phenoscapR_moran")
  expect_true(is.finite(mi$I))

  cnn <- CrossNNDistance(one, from = "T helper", to = "B cell")
  expect_s3_class(cnn, "phenoscapR_crossnn")
  expect_type(unclass(cnn), "double")
  expect_true(all(cnn >= 0))
})

test_that("print and autoplot methods run", {
  skip_if_not_installed("ggplot2")
  rk <- RipleysK(one, r_seq = seq(0, 80, length.out = 15))
  expect_output(print(rk), "Ripley")
  expect_s3_class(ggplot2::autoplot(rk), "ggplot")

  ne <- NeighbourhoodEnrichment(one, radius = 30, n_perm = 49, seed = 1)
  expect_output(print(ne), "enrichment")
  expect_s3_class(ggplot2::autoplot(ne), "ggplot")

  qa <- QuadratAnalysis(one, nx = 4, ny = 4)
  expect_output(print(qa), "Quadrat")
  expect_s3_class(ggplot2::autoplot(qa), "ggplot")
})

test_that("by_sample maps a statistic across all samples", {
  spe <- phenoscapR_example
  spe@meta_data$phenotype <- spe@meta_data$phenotype_true

  res <- RipleysK(spe, r_seq = seq(0, 80, length.out = 12), by_sample = TRUE)
  expect_s3_class(res, "phenoscapR_by_sample")
  expect_setequal(names(res), c("tonsil_A", "tonsil_B"))
  expect_s3_class(res[["tonsil_A"]], "phenoscapR_ripley")

  mi <- MoransI(spe, feature = "CD20", radius = 40, by_sample = TRUE)
  expect_equal(length(mi), 2L)
  expect_true(all(vapply(mi, function(m) is.finite(m$I), logical(1))))
})

test_that("multi-sample without by_sample still errors with guidance", {
  spe <- phenoscapR_example
  spe@meta_data$phenotype <- spe@meta_data$phenotype_true
  expect_error(RipleysK(spe), "single sample")
  expect_error(MoransI(spe, feature = "CD20", radius = 40), "single sample")
})
