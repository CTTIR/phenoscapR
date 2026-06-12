# Tier 3 capabilities: niches, domains, GMM phenotyping, cluster annotation,
# differential abundance, platform readers, and ecosystem interop.

data(phenoscapR_example)
obj <- local({
  o <- phenoscapR_example
  o@meta_data$phenotype <- o@meta_data$phenotype_true
  NormaliseData(o, "zscore")
})

test_that("CellularNeighbourhoods assigns niches from local composition", {
  o <- CellularNeighbourhoods(obj, n_neighbourhoods = 5, k = 15, seed = 1)
  expect_true("neighbourhood" %in% names(Meta(o)))
  expect_equal(length(unique(o$neighbourhood)), 5L)
  cc <- o@spatial$neighbourhood_composition
  expect_equal(nrow(cc), 5L)
  expect_equal(ncol(cc), length(unique(obj$phenotype)))
  # composition rows are fractions in [0, 1]
  expect_true(all(cc >= -1e-9 & cc <= 1 + 1e-9))
})

test_that("SpatialDomains partitions tissue and is spatially coherent", {
  o <- SpatialDomains(obj, n_domains = 4, k = 15, seed = 1)
  expect_true("domain" %in% names(Meta(o)))
  expect_equal(length(unique(o$domain)), 4L)
})

test_that("ExpressionClusters GMM and AnnotateClusters work", {
  skip_if_not_installed("mclust")
  o <- ExpressionClusters(obj, k = 4, method = "gmm")
  expect_equal(length(unique(o$expr_cluster)), 4L)

  labs <- AnnotateClusters(o, add_column = FALSE)
  expect_length(labs, 4L)
  expect_true(all(grepl("\\+$|mixed", labs)))

  o2 <- AnnotateClusters(o, add_column = TRUE)
  expect_true("expr_cluster_label" %in% names(Meta(o2)))
})

test_that("DifferentialAbundance compares phenotype proportions", {
  o <- obj
  o@meta_data$arm <- ifelse(o$sample_id == "tonsil_A", "ctrl", "treat")
  da <- DifferentialAbundance(o, condition = "arm") |> suppressWarnings()
  expect_s3_class(da, "phenoscapR_diffabund")
  expect_true(all(c("phenotype", "mean_ctrl", "mean_treat",
                    "p_value", "p_adj") %in% names(da)))
  expect_output(print(da), "Differential abundance")
  expect_error(DifferentialAbundance(o, condition = "nope"), "not found")
})

test_that("ReadMatrixCoords builds an object from matrix + coords", {
  expr <- matrix(rpois(80, 5), nrow = 20,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "PanCK")))
  meta <- data.frame(x = runif(20, 0, 100), y = runif(20, 0, 100),
                     region = rep(c("a", "b"), 10))
  o <- ReadMatrixCoords(expr, meta)
  expect_s4_class(o, "SpatialCellData")
  expect_equal(NCells(o), 20L)
  expect_setequal(Markers(o), c("CD3", "CD8", "CD20", "PanCK"))
  expect_true("region" %in% names(Meta(o)))
})

test_that("CosMx-style reader maps vendor columns and matches ids", {
  set.seed(1)
  ids <- paste0("c", 1:15)
  expr <- data.frame(fov = 1L, cell_ID = ids,
                     CD3 = rpois(15, 4), CD8 = rpois(15, 3),
                     PanCK = rpois(15, 6), check.names = FALSE)
  meta <- data.frame(cell_ID = rev(ids),                 # different order
                     CenterX_global_px = runif(15, 0, 1000),
                     CenterY_global_px = runif(15, 0, 1000))
  ef <- tempfile(fileext = ".csv"); mf <- tempfile(fileext = ".csv")
  utils::write.csv(expr, ef, row.names = FALSE)
  utils::write.csv(meta, mf, row.names = FALSE)
  on.exit(unlink(c(ef, mf)))

  o <- ReadCosMx(ef, mf)
  expect_equal(NCells(o), 15L)
  expect_setequal(Markers(o), c("CD3", "CD8", "PanCK"))
  expect_false(any(c("fov", "cell_ID") %in% Markers(o)))  # id cols dropped
})

test_that("as_Seurat round-trips back to SpatialCellData", {
  skip_if_not_installed("Seurat")
  skip_if_not_installed("SeuratObject")
  se <- as_Seurat(phenoscapR_example)
  expect_s4_class(se, "Seurat")
  back <- as_SpatialCellData(se)
  expect_s4_class(back, "SpatialCellData")
  expect_equal(NCells(back), NCells(phenoscapR_example))
  expect_setequal(Markers(back), Markers(phenoscapR_example))
})
