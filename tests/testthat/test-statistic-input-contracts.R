# Input contracts of the object-level spatial statistics, clustering helpers,
# quality-control thresholds and marker selections: malformed controls are
# rejected with a clear message before any computation or random draw, and
# undefined statistics are reported as unavailable rather than as neutral.

contract_object <- function(n = 60L, seed = 11L) {
  withr::local_seed(seed)
  counts <- matrix(abs(stats::rnorm(n * 3L)), nrow = n,
                   dimnames = list(NULL, c("CD3", "CD8", "CD20")))
  meta <- data.frame(cell_id = as.character(seq_len(n)), sample_id = "s1",
                     phenotype = rep(c("A", "B", "C"), length.out = n),
                     cell_area = seq(10, 100, length.out = n))
  CreateSpatialObject(counts, data.frame(x = stats::runif(n, 0, 100),
                                         y = stats::runif(n, 0, 100)), meta)
}

random_state <- function() {
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
    get(".Random.seed", envir = globalenv(), inherits = FALSE)
  } else {
    NULL
  }
}

test_that("neighbourhood enrichment validates controls before random draws", {
  obj <- contract_object()
  set.seed(42)
  before <- random_state()
  expect_error(NeighbourhoodEnrichment(obj, radius = -1, n_perm = 5, seed = 1),
               "radius must be one finite nonnegative number")
  expect_error(NeighbourhoodEnrichment(obj, radius = NA_real_, n_perm = 5),
               "radius must be one finite nonnegative number")
  expect_error(NeighbourhoodEnrichment(obj, radius = "a", n_perm = 5),
               "radius must be one finite nonnegative number")
  for (bad in list(0, 1, 2.5, NA_integer_, "3", c(5, 6))) {
    expect_error(NeighbourhoodEnrichment(obj, radius = 10, n_perm = bad, seed = 1),
                 "n_perm must be one integer of at least 2")
  }
  expect_error(NeighbourhoodEnrichment(obj, radius = 10, n_perm = 5, seed = "a"),
               "seed must be NULL or one signed integer")
  incomplete <- obj
  incomplete@meta_data$phenotype[3L] <- NA
  expect_error(NeighbourhoodEnrichment(incomplete, radius = 10, n_perm = 5, seed = 1),
               "phenotype must be a complete, nonblank vector")
  blank <- obj
  blank@meta_data$phenotype[3L] <- " "
  expect_error(NeighbourhoodEnrichment(blank, radius = 10, n_perm = 5, seed = 1),
               "phenotype must be a complete, nonblank vector")
  expect_identical(random_state(), before)
})

test_that("constant permutation counts are neutral only when they match the observation", {
  # One neighbour edge joins the only two A cells; every other cell is isolated.
  n <- 400L
  coords <- data.frame(x = c(0, 1, 100 * seq_len(n - 2L)), y = 0)
  meta <- data.frame(cell_id = as.character(seq_len(n)), sample_id = "s1",
                     phenotype = c("A", "A", rep("B", n - 2L)))
  obj <- CreateSpatialObject(matrix(1, n, 1L, dimnames = list(NULL, "m")), coords, meta)
  res <- as.data.frame(NeighbourhoodEnrichment(obj, radius = 5, n_perm = 3L, seed = 1L))
  key <- paste(res$from, res$to)
  # The three sampled relabellings all place B on both ends of the edge.
  expect_identical(res$mean_expected[key == "A A"], 0)
  expect_identical(res$mean_expected[key == "B B"], 2)
  expect_equal(res$observed[key == "A A"], 2)
  # Observed differs from a constant null: undefined, formerly z = 0 and p = 1.
  expect_true(is.na(res$z_score[key == "A A"]))
  expect_true(is.na(res$p_value[key == "A A"]))
  expect_true(is.na(res$z_score[key == "B B"]))
  # Observed equals the constant null: neutral.
  expect_identical(res$z_score[key == "A B"], 0)
  expect_identical(res$p_value[key == "A B"], 1)
  # The heatmap keeps finite colour limits when some or all z-scores are NA.
  expect_no_warning(built <- ggplot2::ggplot_build(ggplot2::autoplot(
    NeighbourhoodEnrichment(obj, radius = 5, n_perm = 3L, seed = 1L))))
  expect_s3_class(built, "ggplot_built")
})

test_that("neighbourhood enrichment keeps its results for valid input", {
  obj <- contract_object(120L)
  res <- NeighbourhoodEnrichment(obj, radius = 15, n_perm = 19L, seed = 3L)
  again <- NeighbourhoodEnrichment(obj, radius = 15, n_perm = 19, seed = 3)
  expect_identical(res, again)
  d <- as.data.frame(res)
  expect_identical(nrow(d), 9L)
  expect_true(all(is.finite(d$z_score)))
  expect_equal(d$p_value, 2 * stats::pnorm(-abs(d$z_score)))
})

test_that("quadrat analysis validates the grid and counts cells in one pass", {
  obj <- contract_object(200L)
  for (bad in list(0, 2.5, NA_integer_, "3", c(2, 3), -1)) {
    expect_error(QuadratAnalysis(obj, nx = bad), "nx must be one whole number >= 1")
    expect_error(QuadratAnalysis(obj, ny = bad), "ny must be one whole number >= 1")
  }
  expect_error(QuadratAnalysis(obj, target = "missing"),
               "at least one retained cell; no cell has the target phenotype")
  expect_error(QuadratAnalysis(obj[integer(0), ]), "at least one retained cell")

  qa <- QuadratAnalysis(obj, nx = 4, ny = 3)
  xy <- as.matrix(Coords(obj)[, c("x", "y")])
  xb <- findInterval(xy[, 1], seq(min(xy[, 1]), max(xy[, 1]), length.out = 5L),
                     all.inside = TRUE)
  yb <- findInterval(xy[, 2], seq(min(xy[, 2]), max(xy[, 2]), length.out = 4L),
                     all.inside = TRUE)
  reference <- matrix(0L, nrow = 3L, ncol = 4L)
  for (i in seq_len(nrow(xy))) {
    reference[yb[i], xb[i]] <- reference[yb[i], xb[i]] + 1L
  }
  expect_identical(qa$counts, reference)
  expect_identical(sum(qa$counts), 200L)
  expect_equal(qa$VMR, stats::var(as.vector(reference)) / mean(reference))

  # One cell in 25 quadrats has a variance-to-mean ratio of one up to rounding.
  expect_output(print(QuadratAnalysis(obj[1L, ])), "random \\(VMR = 1\\)")
})

test_that("Ripley's K and the pair correlation function validate radii", {
  obj <- contract_object(150L)
  expect_error(RipleysK(obj, r_seq = c(1, NA, 3)), "finite nonnegative radii")
  expect_error(RipleysK(obj, r_seq = c(-1, 1)), "finite nonnegative radii")
  expect_error(RipleysK(obj, r_seq = "a"), "finite nonnegative radii")
  expect_error(RipleysK(obj, r_seq = numeric(0)), "finite nonnegative radii")
  expect_error(RipleysK(obj, r_seq = Inf), "finite nonnegative radii")
  expect_identical(RipleysK(obj, r_seq = 0)$K, 0)

  expect_error(PairCorrelation(obj, r_seq = c(0, 1, 2)), "finite positive radii")
  expect_error(PairCorrelation(obj, r_seq = c(1, NA)), "finite positive radii")
  expect_error(PairCorrelation(obj, r_seq = c(5, 10), dr = 0),
               "dr must be NULL or one finite positive ring width")
  expect_error(PairCorrelation(obj, r_seq = c(5, 10), dr = -1),
               "dr must be NULL or one finite positive ring width")
  expect_error(PairCorrelation(obj, r_seq = c(5, 10), dr = c(1, 2)),
               "dr must be NULL or one finite positive ring width")
  expect_error(PairCorrelation(obj, r_seq = c(5, 5)),
               "dr must be NULL or one finite positive ring width")
  # A descending grid keeps its values: the ring width is a magnitude.
  up <- PairCorrelation(obj, r_seq = c(5, 10, 15))
  down <- PairCorrelation(obj, r_seq = c(15, 10, 5))
  expect_equal(rev(down$g), up$g)
})

test_that("the automatic pair-correlation grid is ascending in small windows", {
  withr::local_seed(5)
  n <- 150L
  small <- CreateSpatialObject(
    matrix(1, n, 1L, dimnames = list(NULL, "m")),
    data.frame(x = stats::runif(n, 0, 2), y = stats::runif(n, 0, 2)))
  pcf <- PairCorrelation(small)
  limit <- min(diff(range(Coords(small)$x)), diff(range(Coords(small)$y))) / 4
  expect_identical(nrow(pcf), 50L)
  expect_true(all(diff(pcf$r) > 0))
  expect_true(all(pcf$r > 0 & pcf$r <= limit + 1e-12))
  expect_true(all(is.finite(pcf$g)))

  # Windows larger than four units keep the grid that starts at one unit.
  large <- contract_object(150L)
  expect_identical(PairCorrelation(large)$r[1L], 1)
})

test_that("result summaries print without warnings when values are unavailable", {
  obj <- contract_object(80L)
  far <- RipleysK(obj, r_seq = c(1000, 2000), correction = "border")
  expect_true(all(is.na(far$L)))
  expect_no_warning(expect_output(print(far), "not available at any radius"))

  pcf <- PairCorrelation(obj, r_seq = c(5, 10))
  pcf$g <- NA_real_
  expect_no_warning(expect_output(print(pcf), "not available at any radius"))

  solo <- obj
  solo@meta_data$phenotype[1L] <- "solo"
  alone <- CrossNNDistance(solo, "solo", "solo")
  expect_true(is.na(as.numeric(alone)))
  expect_no_warning(expect_output(print(alone), "1 without another target cell"))
  expect_output(print(CrossNNDistance(obj, "A", "B")), "median")

  none <- structure(list(), names = character(), class = c("phenoscapR_by_sample", "list"))
  expect_output(print(none), "0 samples")
})

test_that("cluster counts and edge limits are validated", {
  obj <- contract_object()
  for (bad in list(0, NA, 2.5, "2", c(2, 3))) {
    expect_error(SpatialClusters(obj, k = bad), "k must be one whole number of at least 1")
    expect_error(ExpressionClusters(obj, k = bad), "k must be one whole number of at least 1")
  }
  expect_error(SpatialClusters(obj[1:3, ], k = 4), "exceeds the number of cells")
  expect_error(SpatialClusters(obj[integer(0), ], k = 1), "exceeds the number of cells")
  expect_error(ExpressionClusters(obj[1:3, ], k = 4), "exceeds the number of cells")
  incomplete <- obj
  incomplete@counts[1L, 1L] <- NA
  incomplete@data[1L, 1L] <- NA
  expect_error(ExpressionClusters(incomplete, k = 2), "complete marker values")
  expect_warning(
    expect_error(ExpressionClusters(obj, k = 2, markers = "nope"),
                 "No markers available for expression clustering"),
    "Ignoring markers not found in the data: nope")

  dt <- data.table::data.table(x = c(0, 1, 50, 51), y = c(0, 1, 50, 51))
  expect_error(spatial_clusters(dt, k = 0), "k must be one whole number of at least 1")
  expect_error(spatial_clusters(dt, k = 5), "exceeds the number of cells")
  expect_error(spatial_clusters(data.table::data.table(a = 1:3), k = 2),
               "dt must be a data.table with x and y columns")
  expect_error(spatial_clusters(data.table::data.table(x = c(1, NA), y = 1:2), k = 1),
               "finite numeric")
  withr::local_seed(1)
  clustered <- spatial_clusters(dt, k = 2)
  expect_identical(clustered$cluster[1:2], rep(clustered$cluster[1L], 2L))
  expect_false(identical(clustered$cluster[1L], clustered$cluster[3L]))
  expect_false("cluster" %in% names(dt))

  for (bad in list(NA, "a", -1, c(1, 2))) {
    expect_error(DelaunayNetwork(obj, max_edge = bad),
                 "max_edge must be NULL or one nonnegative number")
  }
  skip_if_not_installed("deldir")
  edges <- DelaunayNetwork(obj, max_edge = 20)@spatial$delaunay_edges
  expect_true(all(edges$distance <= 20))
})
