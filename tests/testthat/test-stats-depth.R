# Tier 2 statistical-depth additions: Ripley translation correction, Moran's I
# weight schemes + permutation, PCA variance, permutation interaction matrix.

data(phenoscapR_example)
one <- local({
  o <- phenoscapR_example[phenoscapR_example$sample_id == "tonsil_A", ]
  o@meta_data$phenotype <- o@meta_data$phenotype_true
  NormaliseData(o, method = "zscore")
})

test_that("Ripley's K translation correction is finite and edge-corrects", {
  r <- seq(0, 120, length.out = 25)
  none  <- RipleysK(one, r_seq = r, correction = "none")
  trans <- RipleysK(one, r_seq = r, correction = "translation")
  expect_s3_class(trans, "phenoscapR_ripley")
  expect_equal(attr(trans, "correction"), "translation")
  expect_true(all(is.finite(trans$K)))
  # Edge correction lifts K above the naive (downward-biased) estimate at
  # larger radii where edge effects bite.
  expect_gt(mean(trans$K[20:25]), mean(none$K[20:25]))
})

test_that("Ripley translation matches a direct weighted reference (small data)", {
  set.seed(3)
  n <- 250L
  counts <- matrix(rnorm(2 * n), ncol = 2, dimnames = list(NULL, c("A", "B")))
  coords <- data.frame(x = runif(n, 0, 100), y = runif(n, 0, 100))
  obj <- CreateSpatialObject(counts, coords)
  r_seq <- seq(5, 30, length.out = 8)
  got <- RipleysK(obj, r_seq = r_seq, correction = "translation")$K

  xy <- as.matrix(coords)
  Wd <- diff(range(xy[, 1])); Hd <- diff(range(xy[, 2])); A <- Wd * Hd
  d <- as.matrix(dist(xy))
  ref <- vapply(r_seq, function(r) {
    tot <- 0
    for (i in seq_len(n)) for (j in seq_len(n)) {
      if (i != j && d[i, j] <= r) {
        ov <- (Wd - abs(xy[i,1]-xy[j,1])) * (Hd - abs(xy[i,2]-xy[j,2]))
        if (ov > 0) tot <- tot + 1 / ov
      }
    }
    (A^2 / n^2) * tot
  }, numeric(1))
  expect_equal(got, ref, tolerance = 1e-8)
})

test_that("Moran's I supports weight schemes and a permutation p-value", {
  mb <- MoransI(one, feature = "CD20", radius = 40)
  expect_equal(mb$method, "analytic")

  mr <- MoransI(one, feature = "CD20", radius = 40, weights = "row")
  expect_equal(mr$method, "permutation")          # non-binary auto-permutes
  expect_true(is.finite(mr$I) && mr$p_value <= 1)

  mp <- MoransI(one, feature = "CD20", radius = 40, n_perm = 199, seed = 1)
  expect_equal(mp$method, "permutation")
  expect_true(mp$p_value <= 1 && mp$p_value >= 0)

  mi <- MoransI(one, feature = "CD20", radius = 40, weights = "idw", n_perm = 99,
                seed = 1)
  expect_true(is.finite(mi$I))
})

test_that("PCA stores variance and ScreePlot works", {
  o <- RunPCA(one, n_pcs = 6)
  ve <- VarianceExplained(o)
  expect_length(ve, 6L)
  expect_true(all(diff(ve) <= 1e-8))             # non-increasing
  expect_true(sum(ve) > 0 && sum(ve) <= 100 + 1e-6)
  expect_s3_class(ScreePlot(o), "ggplot")
})

test_that("InteractionMatrix permutation adds z and p", {
  im <- InteractionMatrix(one, radius = 40, method = "permutation",
                          n_perm = 99, seed = 1)
  expect_s3_class(im, "phenoscapR_interaction")
  expect_true(all(c("z_score", "p_value") %in% names(im)))
  expect_true(all(im$p_value >= 0 & im$p_value <= 1))
})
