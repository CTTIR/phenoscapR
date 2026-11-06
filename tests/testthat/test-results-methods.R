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

test_that("results without a defined statistic print as not evaluable", {
  m <- structure(list(I = NaN, expected = -0.1, z_score = NaN, p_value = NaN), class = "phenoscapR_moran")
  expect_output(print(m), "not evaluable")
  q <- structure(list(counts = matrix(5, 1, 1), chi_sq = 0, p_value = NA_real_, VMR = NA_real_),
                 class = "phenoscapR_quadrat")
  expect_output(print(q), "not evaluable")
})

test_that("column subsets of data-frame results print as plain data frames", {
  # `[` keeps the result class on a column subset, but the summaries need
  # particular columns. A subset that lost them must print as the plain data
  # frame it is: no error, no warning and no summary built on missing columns.
  im <- InteractionMatrix(one, radius = 30)
  ne <- NeighbourhoodEnrichment(one, radius = 30, n_perm = 9, seed = 1)
  rk <- RipleysK(one, r_seq = seq(0, 80, length.out = 8))
  pc <- PairCorrelation(one, r_seq = seq(5, 80, length.out = 8))
  both <- phenoscapR_example
  both@meta_data$phenotype <- both@meta_data$phenotype_true
  both@meta_data$arm <- ifelse(both$sample_id == "tonsil_A", "ctrl", "treat")
  expect_warning(da <- DifferentialAbundance(both, condition = "arm"),
                 "fewer than 2 samples")

  subsets <- list(
    interaction = im[, c("from", "to")],
    enrichment = ne[, c("from", "to")],
    ripley = rk[, "r", drop = FALSE],
    pcf = pc[, "r", drop = FALSE],
    diffabund = da[, 1:2]
  )
  for (nm in names(subsets)) {
    x <- subsets[[nm]]
    expect_true(inherits(x, paste0("phenoscapR_", nm)), info = nm)
    expect_no_warning(out <- capture.output(print(x)), message = NULL)
    expect_identical(out, capture.output(print(as.data.frame(x))), info = nm)
  }
})

test_that("results that keep their columns still print their summary", {
  im <- InteractionMatrix(one, radius = 30)
  expect_output(print(im[1:3, ]), "strongest attractions")
})
