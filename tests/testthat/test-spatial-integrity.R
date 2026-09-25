spatial_integrity_fixture <- function() {
  CreateSpatialObject(
    matrix(seq_len(12), ncol = 2, dimnames = list(NULL, c("A", "B"))),
    data.frame(x = c(0, 0.2, 2, 2.2, 0, 0.2),
               y = c(0, 0.2, 0, 0.2, 2, 2.2)),
    meta_data = data.frame(cell_id = 1:6, sample_id = rep(c("a", "b"), 3),
                           phenotype = rep(c("P", "Q"), 3),
                           arm = rep(c("control", "treated"), 3)))
}

test_that("Delaunay edges remain within independent sample coordinate frames", {
  skip_if_not_installed("deldir")
  obj <- spatial_integrity_fixture()
  edges <- DelaunayNetwork(obj)@spatial$delaunay_edges
  expect_equal(nrow(edges), 6L)
  expect_true(all(obj$sample_id[edges$from] == obj$sample_id[edges$to]))
  expect_setequal(paste(edges$from, edges$to),
                  c("1 3", "1 5", "3 5", "2 4", "2 6", "4 6"))
  expect_equal(sort(edges$distance), sort(rep(c(2, 2, sqrt(8)), 2)))
  limited <- DelaunayNetwork(obj, max_edge = 2.1)@spatial$delaunay_edges
  expect_equal(nrow(limited), 4L)
})

test_that("Delaunay validates sample identities and small sample groups", {
  obj <- spatial_integrity_fixture()
  obj@meta_data$sample_id[1] <- NA_character_
  expect_error(DelaunayNetwork(obj), "sample_id")
  obj@meta_data$sample_id[1] <- ""
  expect_error(DelaunayNetwork(obj), "sample_id")
  obj <- spatial_integrity_fixture()
  obj@meta_data$sample_id <- c("a", "a", "b", "b", "c", "c")
  expect_error(DelaunayNetwork(obj), "at least 3 cells.*sample")
})

test_that("cell indexing invalidates spatial results and local neighbour metadata", {
  obj <- spatial_integrity_fixture()
  obj@spatial <- list(delaunay_edges = data.frame(from = 1L, to = 6L),
                      nn_distances = 1:6, neighbourhood_composition = diag(2))
  obj@meta_data$nn_distance <- 1:6
  obj@meta_data$density <- 6:1
  obj@meta_data$neighbourhood <- "CN1"
  obj@meta_data$domain <- "D1"
  obj@meta_data$cluster <- "1"
  obj@meta_data$expr_cluster <- "E1"
  obj@reductions$pca <- matrix(1:12, nrow = 6)
  for (i in list(c(6, 2, 4), c(TRUE, FALSE, TRUE, FALSE, TRUE, FALSE),
                 integer(), 6:1, c(1, 1, 2))) {
    sub <- obj[i, ]
    expect_length(sub@spatial, 0L)
    expect_false(any(c("nn_distance", "density") %in% names(Meta(sub))))
    for (label in c("neighbourhood", "domain", "cluster")) {
      expect_equal(sub[[label]], obj[[label]][i])
    }
    expect_equal(sub$phenotype, obj$phenotype[i])
    expect_equal(sub$expr_cluster, obj$expr_cluster[i])
    expect_equal(sub@reductions$pca, obj@reductions$pca[i, , drop = FALSE])
    expect_equal(sub$cell_id, obj$cell_id[i])
  }
  expect_identical(obj[, "A"]@spatial, obj@spatial)
  expect_identical(obj[,]@spatial, obj@spatial)
})

test_that("differential abundance rejects conflicting or missing conditions", {
  obj <- spatial_integrity_fixture()
  obj@meta_data$arm[3] <- "treated"
  expect_error(DifferentialAbundance(obj, "arm"), "constant within.*sample")
  for (missing in list(NA_character_, "", "  ")) {
    obj <- spatial_integrity_fixture()
    obj@meta_data$arm[3] <- missing
    expect_error(DifferentialAbundance(obj, "arm"), "non-missing.*condition")
  }
  obj <- spatial_integrity_fixture()
  obj@meta_data$sample_id[1] <- NA_character_
  expect_error(DifferentialAbundance(obj, "arm"), "sample_id")
})

test_that("valid differential abundance does not depend on cell row order", {
  obj <- spatial_integrity_fixture()
  original <- suppressWarnings(DifferentialAbundance(obj, "arm"))
  shuffled <- suppressWarnings(DifferentialAbundance(obj[6:1, ], "arm"))
  expect_equal(original, shuffled)
  expect_equal(original$mean_control, c(1, 0))
  expect_equal(original$mean_treated, c(0, 1))
})


test_that("frozen spatial labels retain original scope across subsets and refits", {
  obj <- spatial_integrity_fixture()
  obj@meta_data$neighbourhood <- "CN1"
  obj@meta_data$domain <- "D1"
  obj@meta_data$cluster <- "1"
  sub <- obj[1:5, ]
  frozen <- attr(Meta(sub), "frozen_spatial_labels")
  expect_named(frozen, c("neighbourhood", "domain", "cluster"))
  expect_equal(frozen$cluster, list(scope = "original_fit", source_n_cells = 6L))
  expect_identical(attr(Meta(sub[1:4, ]), "frozen_spatial_labels"), frozen)
  refit <- SpatialClusters(sub, k = 2)
  expect_null(attr(Meta(refit), "frozen_spatial_labels")$cluster)
  expect_equal(attr(Meta(refit), "frozen_spatial_labels")$domain, frozen$domain)
  refit <- CellularNeighbourhoods(refit, n_neighbourhoods = 2, k = 1, seed = 1)
  expect_null(attr(Meta(refit), "frozen_spatial_labels")$neighbourhood)
  refit <- SpatialDomains(refit, n_domains = 2, k = 1, seed = 1)
  expect_null(attr(Meta(refit), "frozen_spatial_labels"))
})
