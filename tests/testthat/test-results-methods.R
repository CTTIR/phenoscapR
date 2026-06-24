# Additional coverage for the classed result print()/autoplot() S3 methods that
# the curated test-results.R does not exercise: pair-correlation, interaction
# matrix, cross nearest-neighbour autoplot, and the per-sample bundle print.

data(phenoscapR_example)
one <- local({
  o <- phenoscapR_example[phenoscapR_example$sample_id == "tonsil_A", ]
  o@meta_data$phenotype <- o@meta_data$phenotype_true
  o
})

test_that("pair correlation print and autoplot work", {
  skip_if_not_installed("ggplot2")
  pc <- PairCorrelation(one, r_seq = seq(5, 80, length.out = 15))
  expect_s3_class(pc, "phenoscapR_pcf")
  expect_output(print(pc), "Pair correlation")
  expect_output(print(pc), "peak g")
  p <- ggplot2::autoplot(pc)
  expect_s3_class(p, "ggplot")
})

test_that("interaction matrix print and autoplot work", {
  skip_if_not_installed("ggplot2")
  im <- InteractionMatrix(one, radius = 30)
  expect_s3_class(im, "phenoscapR_interaction")
  expect_output(print(im), "interaction matrix")
  expect_output(print(im), "strongest attractions")
  p <- ggplot2::autoplot(im)
  expect_s3_class(p, "ggplot")
})

test_that("cross nearest-neighbour print and autoplot work", {
  skip_if_not_installed("ggplot2")
  cnn <- CrossNNDistance(one, from = "T helper", to = "B cell")
  expect_s3_class(cnn, "phenoscapR_crossnn")
  expect_output(print(cnn), "Cross nearest-neighbour")
  expect_output(print(cnn), "median")
  p <- ggplot2::autoplot(cnn)
  expect_s3_class(p, "ggplot")
  # autoplot uses the from/to attributes in its axis label.
  expect_true(grepl("T helper", p$labels$x))
})

test_that("Moran's I print covers all three verdict branches", {
  mk <- function(I, expected, p) {
    x <- list(I = I, expected = expected, z_score = 1, p_value = p)
    class(x) <- "phenoscapR_moran"
    x
  }
  expect_output(print(mk(0.5, 0, 0.01)), "positive autocorrelation")
  expect_output(print(mk(-0.5, 0, 0.01)), "negative autocorrelation")
  expect_output(print(mk(0.01, 0, 0.9)), "no significant")
})

test_that("quadrat print covers clustered/regular/random branches", {
  mk <- function(vmr) {
    x <- list(counts = matrix(1:16, 4, 4), chi_sq = 5, p_value = 0.3,
              VMR = vmr)
    class(x) <- "phenoscapR_quadrat"
    x
  }
  expect_output(print(mk(2)), "clustered")
  expect_output(print(mk(0.5)), "regular")
  expect_output(print(mk(1)), "random")
})

test_that("per-sample bundle print lists each sample", {
  spe <- phenoscapR_example
  spe@meta_data$phenotype <- spe@meta_data$phenotype_true
  res <- RipleysK(spe, r_seq = seq(0, 80, length.out = 12), by_sample = TRUE)
  expect_s3_class(res, "phenoscapR_by_sample")
  out <- capture.output(print(res))
  expect_true(any(grepl("per-sample results", out)))
  expect_true(any(grepl("tonsil_A", out)))
  expect_true(any(grepl("tonsil_B", out)))
})
