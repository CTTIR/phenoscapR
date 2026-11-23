# Printed object summaries, identity fallbacks, palette forms and table-level
# plot preconditions that the workflow tests do not reach.

summary_object <- function(n = 40L, markers = paste0("M", 1:8)) {
  withr::local_seed(21)
  counts <- matrix(abs(stats::rnorm(n * length(markers))), nrow = n,
                   dimnames = list(NULL, markers))
  meta <- data.frame(cell_id = as.character(seq_len(n)),
                     sample_id = rep(c("s1", "s2"), length.out = n),
                     cell_area = seq(10, 100, length.out = n))
  CreateSpatialObject(counts, data.frame(x = stats::runif(n, 0, 50),
                                         y = stats::runif(n, 0, 50)), meta)
}

test_that("the object summary reports markers, labels, results and reductions", {
  obj <- summary_object()
  out <- utils::capture.output(print(obj))
  expect_identical(out[1L], "A SpatialCellData object")
  expect_true(any(grepl("40 cells across 2 samples", out, fixed = TRUE)))
  # More than six markers are abbreviated to five and a total.
  expect_true(any(grepl("Markers: M1, M2, M3, M4, M5, ... (8 total)", out, fixed = TRUE)))
  expect_true(any(grepl("Normalised: FALSE", out, fixed = TRUE)))
  expect_false(any(grepl("Phenotypes|Spatial results|Reductions", out)))

  full <- NormaliseData(obj)
  full <- PhenotypeCells(full, thresholds = list(M1 = 0, M2 = 0.5))
  full <- FindNeighbours(full, k = 2)
  full <- RunPCA(full, n_pcs = 2)
  out <- utils::capture.output(print(full))
  expect_true(any(grepl("Normalised: TRUE", out, fixed = TRUE)))
  expect_true(any(grepl(paste("Phenotypes:", length(unique(full$phenotype))), out, fixed = TRUE)))
  expect_true(any(grepl("Spatial results: nn_distances", out, fixed = TRUE)))
  expect_true(any(grepl("Reductions: pca", out, fixed = TRUE)))

  few <- obj[, 1:2]
  expect_true(any(grepl("Markers: M1, M2 ", utils::capture.output(print(few)), fixed = TRUE)))
  one <- obj[obj$sample_id == "s1", ]
  expect_true(any(grepl("20 cells across 1 sample", utils::capture.output(print(one)),
                        fixed = TRUE)))
  none <- obj[, integer(0)]
  expect_true(any(grepl("Markers: none", utils::capture.output(print(none)), fixed = TRUE)))
})

test_that("identities fall back to the sample when no phenotype is assigned", {
  obj <- summary_object()
  expect_identical(Idents(obj), obj$sample_id)
  typed <- PhenotypeCells(obj, thresholds = list(M1 = 0.5))
  expect_identical(Idents(typed), typed$phenotype)
  expect_identical(dim(obj), c(40L, 8L))
  expect_identical(obj[["cell_area"]], obj$cell_area)
})

test_that("neighbour distances and densities accept a target phenotype on objects", {
  obj <- PhenotypeCells(summary_object(), thresholds = list(M1 = 0.5))
  target <- obj$phenotype[1L]
  near <- FindNeighbours(obj, k = 1, target = target)
  expect_length(near$nn_distance, 40L)
  expect_true(all(is.na(near$nn_distance) | near$nn_distance >= 0))
  dens <- CellDensity(obj, radius = 15, target = target)
  expect_true(all(dens$density >= 0))
  # Per sample, a cell is never counted in its own neighbourhood.
  expect_true(all(dens$density <= table(obj$sample_id, obj$phenotype)[
    cbind(obj$sample_id, target)]))
})

test_that("palettes accept viridis names, single colours, gradients and vectors", {
  expect_length(PaletteContinuous(5, "inferno"), 5L)
  single <- PaletteContinuous(3, "#3366CC")
  expect_identical(toupper(single[1L]), "#FFFFFF")
  expect_identical(toupper(single[3L]), "#3366CC")
  gradient <- PaletteContinuous(3, c("#000000", "#FFFFFF"))
  expect_identical(toupper(gradient[c(1L, 3L)]), c("#000000", "#FFFFFF"))
  fixed <- c("#111111", "#222222", "#333333", "#444444", "#555555")
  expect_identical(PaletteDiscrete(3, fixed), fixed[1:3])
  expect_identical(PaletteDiscrete(7, fixed[1:4]), rep_len(fixed[1:4], 7L))
  # An unknown palette name falls back to the default instead of failing.
  expect_identical(PaletteContinuous(4, "no-such-palette"), PaletteContinuous(4, "viridis"))
  expect_error(CustomGradient("red"), "2 or 3 colours")
  expect_identical(CustomGradient(c("black", "white"))(2), c("#000000", "#FFFFFF"))
})

test_that("table-level plots state their preconditions", {
  dt <- data.table::data.table(sample_id = "s1", cell_id = 1:6, x = 1:6, y = 6:1,
                               CD3 = c(1, 2, 3, 4, 5, 6))
  expect_error(plot_density(dt), "Column 'density' not found")
  expect_error(plot_heatmap(dt), "Column 'phenotype' not found")
  expect_error(plot_cell_map(dt, colour_by = "phenotype"), "not found in data")
  dt$phenotype <- rep(c("A", "B"), each = 3L)
  expect_error(plot_heatmap(dt[, c("sample_id", "cell_id", "x", "y", "phenotype"), with = FALSE]),
               "No marker columns found")
  expect_s3_class(plot_heatmap(dt), "ggplot")
  expect_s3_class(plot_density(cell_density(dt, radius = 2)), "ggplot")
  expect_warning(normalised <- normalise_markers(
    dt[, c("sample_id", "cell_id", "x", "y", "phenotype"), with = FALSE]),
    "No marker columns found to normalise")
  expect_identical(nrow(normalised), 6L)
  expect_identical(qc_filter(dt, max_intensity = 3)$cell_id, 1:3)
  expect_error(summarise_phenotypes(dt[, c("sample_id", "x"), with = FALSE]),
               "Column 'phenotype' not found")
})

test_that("coordinate clustering supports Ward linkage and triangulation needs three cells", {
  dt <- data.table::data.table(x = c(0, 1, 0, 50, 51, 50), y = c(0, 0, 1, 50, 50, 51))
  ward <- spatial_clusters(dt, k = 2, method = "hierarchical")
  expect_identical(ward$cluster, c("1", "1", "1", "2", "2", "2"))
  obj <- summary_object()
  expect_identical(length(unique(SpatialClusters(obj, k = 3, method = "hierarchical")$cluster)), 3L)
  expect_error(DelaunayNetwork(obj[1:2, ]), "at least 3 cells")
})
