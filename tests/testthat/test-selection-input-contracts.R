# Input contracts of quality control, marker selections, principal components,
# cell subsetting, plots of empty objects and table import: malformed input is
# rejected with a clear message, and a marker name that does not exist is
# reported instead of being dropped silently.

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

test_that("quality-control thresholds must be single non-missing numbers", {
  obj <- contract_object()
  dt <- data.table::data.table(sample_id = "s1", cell_id = 1:5, x = 1:5, y = 1:5,
                               cell_area = c(5, 20, 30, 40, 500), CD3 = c(1, 2, 3, 4, 5))
  for (bad in list(NA, NA_real_, "a", c(1, 2), TRUE)) {
    expect_error(QCFilter(obj, min_intensity = bad),
                 "min_intensity must be NULL or one non-missing number")
    expect_error(QCFilter(obj, max_area = bad),
                 "max_area must be NULL or one non-missing number")
    expect_error(qc_filter(dt, min_area = bad),
                 "min_area must be NULL or one non-missing number")
    expect_error(qc_filter(dt, max_intensity = bad),
                 "max_intensity must be NULL or one non-missing number")
  }
  expect_identical(NCells(QCFilter(obj, min_intensity = NULL)), NCells(obj))
  expect_identical(nrow(qc_filter(dt, min_intensity = NULL)), 5L)
  expect_identical(qc_filter(dt, min_area = 10, max_area = 100)$cell_id, 2:4)
  expect_identical(NCells(QCFilter(obj, min_area = 20, max_area = 60)),
                   sum(obj$cell_area >= 20 & obj$cell_area <= 60))
})

test_that("marker selections name the markers that do not exist", {
  obj <- contract_object()
  expect_warning(norm <- NormaliseData(obj, markers = c("CD3", "typo")),
                 "Ignoring markers not found in the data: typo")
  expect_equal(norm@data[, "CD3"], as.numeric(scale(obj@counts[, "CD3"])))
  expect_identical(norm@data[, "CD8"], obj@counts[, "CD8"])
  expect_no_warning(NormaliseData(obj, markers = c("CD3", "CD8")))

  dt <- data.table::data.table(sample_id = "s1", cell_id = 1:4, x = 1:4, y = 1:4,
                               phenotype = c("A", "A", "B", "B"),
                               CD3 = c(1, 2, 3, 4), CD8 = c(4, 3, 2, 1))
  expect_warning(normalise_markers(dt, markers = c("CD3", "nope")),
                 "Ignoring markers not found in the data: nope")
  expect_warning(expect_s3_class(plot_heatmap(dt, markers = c("CD3", "nope")), "ggplot"),
                 "Ignoring markers not found in the data: nope")
  expect_warning(expect_s3_class(MarkerHeatmap(obj, markers = c("CD3", "nope")), "ggplot"),
                 "Ignoring markers not found in the data: nope")
  expect_warning(pca <- RunPCA(obj, markers = c("CD3", "CD8", "nope")),
                 "Ignoring markers not found in the data: nope")
  expect_identical(ncol(Embeddings(pca, "pca")), 2L)

  expect_warning(
    expect_error(SpatialDomains(obj, n_domains = 2, markers = "nope", seed = 1),
                 "No markers available for spatial domains"),
    "Ignoring markers not found in the data: nope")
})

test_that("cell subsetting rejects missing indices", {
  obj <- contract_object()
  obj@meta_data$phenotype[2L] <- NA
  expect_error(obj[obj$phenotype == "A", ], "must not contain missing values")
  expect_error(obj[c(1L, NA), ], "must not contain missing values")
  kept <- obj[which(obj$phenotype == "A"), ]
  expect_identical(NCells(kept), sum(obj$phenotype == "A", na.rm = TRUE))
  expect_identical(NCells(obj[obj$phenotype %in% "A", ]), NCells(kept))
})

test_that("principal components validate their inputs", {
  obj <- contract_object()
  for (bad in list(0, NA, "2", c(1, 2), -1)) {
    expect_error(RunPCA(obj, n_pcs = bad), "n_pcs must be one number of at least 1")
  }
  expect_error(RunPCA(obj[1L, ]), "PCA requires at least two cells")
  incomplete <- obj
  incomplete@counts[1L, 1L] <- NA
  incomplete@data[1L, 1L] <- NA
  expect_error(RunPCA(incomplete), "complete, finite marker values")
  expect_identical(dim(Embeddings(RunPCA(obj, n_pcs = 2), "pca")), c(60L, 2L))
  # More components than markers are capped, as documented.
  expect_identical(ncol(Embeddings(RunPCA(obj), "pca")), 3L)
})

test_that("feature and group plots of an object without cells build empty plots", {
  none <- contract_object()[integer(0), ]
  for (plot in list(FeaturePlot(none, features = "CD3"),
                    ViolinPlot(none, features = c("CD3", "CD8")),
                    BoxPlot(none, features = "CD3"),
                    RidgePlot(none, features = "CD3"))) {
    expect_s3_class(plot, "ggplot")
    expect_identical(nrow(plot$data), 0L)
  }
  expect_error(MarkerHeatmap(none), "No cells with a phenotype to summarise")
})

test_that("table import reports empty files and malformed paths", {
  empty <- withr::local_tempfile(fileext = ".csv")
  file.create(empty)
  expect_error(read_spatial(empty), "File is empty")
  expect_error(ReadSpatial(empty), "File is empty")
  expect_error(read_spatial(NA_character_), "path must be one file or directory path")
  expect_error(read_spatial(c("a.csv", "b.csv")), "path must be one file or directory path")
  expect_error(read_spatial(1), "path must be one file or directory path")
  expect_error(read_spatial(file.path(tempdir(), "no-such-file.csv")), "Path does not exist")
})

test_that("feature plots name the features that do not exist", {
  obj <- contract_object()
  plots <- list(
    function(features) FeaturePlot(obj, features = features),
    function(features) ViolinPlot(obj, features = features),
    function(features) BoxPlot(obj, features = features),
    function(features) RidgePlot(obj, features = features),
    function(features) DotPlot(obj, features = features)
  )
  for (plot in plots) {
    expect_warning(built <- plot(c("CD3", "nope")),
                   "Ignoring features not found in the data: nope")
    expect_s3_class(built, "ggplot")
    expect_no_warning(plot(c("CD3", "CD8")))
    # Nothing to draw is an error without an additional warning.
    expect_no_warning(expect_error(plot("nope"), "No matching features found"))
  }
})

test_that("optional grouping columns that do not exist are reported", {
  obj <- contract_object()
  expect_warning(plot <- HistogramPlot(obj, feature = "CD3", group_by = "nope"),
                 "Ignoring group_by = \"nope\": column not found in meta_data")
  expect_s3_class(plot, "ggplot")
  expect_warning(plot <- QCPlot(obj, x = "cell_area", y = "cell_area", colour_by = "nope"),
                 "Ignoring colour_by = \"nope\": column not found in meta_data")
  expect_s3_class(plot, "ggplot")
  expect_no_warning(HistogramPlot(obj, feature = "CD3", group_by = "phenotype"))
  expect_no_warning(HistogramPlot(obj, feature = "CD3"))
  expect_no_warning(QCPlot(obj, x = "cell_area", y = "cell_area", colour_by = "phenotype"))
  expect_no_warning(QCPlot(obj, x = "cell_area", y = "cell_area"))
})

test_that("ridge densities are outlined in the colour of their fill", {
  obj <- contract_object()
  built <- ggplot2::ggplot_build(RidgePlot(obj, features = "CD3"))$data[[1L]]
  expect_identical(built$colour, built$fill)
  expect_identical(sort(unique(built$fill)), sort(PaletteDiscrete(3L)))
  chosen <- c(A = "#AA0000", B = "#00AA00", C = "#0000AA")
  built <- ggplot2::ggplot_build(RidgePlot(obj, features = c("CD3", "CD8"),
                                           colours = chosen))$data[[1L]]
  expect_identical(built$colour, built$fill)
  expect_setequal(unique(built$fill), unname(chosen))
})

test_that("QC scatter plots use the package palette", {
  obj <- contract_object()
  built <- ggplot2::ggplot_build(
    QCPlot(obj, x = "cell_area", y = "cell_area", colour_by = "phenotype"))$data[[1L]]
  expect_identical(sort(unique(built$colour)), sort(PaletteDiscrete(3L)))
  obj@meta_data$score <- seq_len(NCells(obj))
  built <- ggplot2::ggplot_build(
    QCPlot(obj, x = "cell_area", y = "cell_area", colour_by = "score"))$data[[1L]]
  ends <- PaletteContinuous(256L)[c(1L, 256L)]
  expect_identical(toupper(built$colour[c(1L, NCells(obj))]), toupper(ends))
})

test_that("phenotype labels must be named by signature", {
  obj <- contract_object()
  thresholds <- list(CD3 = 0.5)
  for (bad in list("T", c("T", "B"), stats::setNames("T", ""), stats::setNames("T", NA),
                   c("CD3+" = "T", "CD3+" = "B"), c("CD3+" = NA_character_),
                   list("CD3+" = "T"))) {
    expect_error(PhenotypeCells(obj, thresholds, labels = bad),
                 "labels must be NULL or a vector of non-missing labels")
  }
  dt <- data.table::data.table(sample_id = "s1", cell_id = 1:3, x = 1:3, y = 1:3,
                               CD3 = c(0, 1, 2))
  expect_error(phenotype_cells(dt, thresholds, labels = "T"),
               "labels must be NULL or a vector of non-missing labels")
  labelled <- PhenotypeCells(obj, thresholds, labels = c("CD3+" = "T cell"))
  expect_setequal(unique(labelled$phenotype), c("T cell", "Negative"))
  expect_identical(phenotype_cells(dt, thresholds, labels = c("CD3+" = "T"))$phenotype,
                   c("Negative", "T", "T"))
  expect_setequal(unique(PhenotypeCells(obj, thresholds)$phenotype), c("CD3+", "Negative"))
})

test_that("interaction heatmaps rotate the phenotype labels", {
  obj <- contract_object()
  plot <- InteractionPlot(InteractionMatrix(obj, radius = 20))
  expect_identical(plot$theme$axis.text.x$angle, 45)
  expect_identical(plot_interactions(as.data.frame(InteractionMatrix(obj, radius = 20)))$theme$
                     axis.text.x$angle, 45)
})

test_that("dot plots hold one summary row per feature and group", {
  obj <- contract_object()
  plot <- DotPlot(obj, features = c("CD3", "CD8"))
  expect_identical(nrow(plot$data), 2L * length(unique(obj$phenotype)))
  expect_identical(anyDuplicated(plot$data[, c("feature", "group")]), 0L)
  a_cd3 <- plot$data[plot$data$feature == "CD3" & plot$data$group == "A", ]
  values <- obj@data[obj$phenotype == "A", "CD3"]
  expect_equal(a_cd3$avg_exp, mean(values))
  expect_equal(a_cd3$pct_exp, 100 * mean(values > 0))
  none <- obj[integer(0), ]
  empty <- DotPlot(none, features = "CD3")
  expect_identical(nrow(empty$data), 0L)
  expect_s3_class(ggplot2::ggplot_build(empty), "ggplot_built")
})
