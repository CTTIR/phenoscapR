test_that("canonical import preserves values, missing features and source metadata", {
  skip_if_not_installed("cellspecR")
  x <- cellspecR::cs_example()
  x$measurements[, 1L] <- NA_real_
  y <- FromCellspec(x)
  expect_identical(y@counts, x$measurements)
  expect_identical(y@data, x$measurements)
  expect_identical(y@coords$x, x$cells$x)
  expect_identical(y@coords$y, x$cells$y)
  expect_identical(y@meta_data$cell_id, x$cells$cell_id)
  expect_identical(y@meta_data$image_id, x$cells$image_id)
  expect_identical(y@meta_data$sample_id, x$cells$image_id)
  expect_identical(y@meta_data$source_sample_id, x$cells$sample_id)
  expect_identical(y@meta_data$cell_area, x$cells$area)
  receipt <- attr(Meta(y), "cellspec_import")
  for (component in c("dictionary", "images", "channels", "adjacency", "provenance")) {
    expect_identical(receipt[[component]], x[[component]])
  }
  expect_identical(receipt$scope, "original_import")
  expect_identical(receipt$coordinate_unit, "um")
  expect_true(all(receipt$feature_support$support[
    receipt$feature_support$feature_id == colnames(x$measurements)[1L]] == "mostly_na"))
  expect_identical(y@spatial, list())
  expect_true(methods::validObject(y))
})

test_that("features are selected explicitly and snapshots remain scoped after subsetting", {
  skip_if_not_installed("cellspecR")
  x <- cellspecR::cs_example()
  features <- rev(x$dictionary$feature_id[1:3])
  y <- FromCellspec(x, features)
  expect_identical(y@counts, x$measurements[, features, drop = FALSE])
  receipt <- attr(Meta(y), "cellspec_import")
  expect_identical(receipt$selected_features, features)
  expect_identical(attr(Meta(y[3:1, 2:1]), "cellspec_import"), receipt)
  expect_equal(ncol(FromCellspec(x, character())@counts), 0L)
  expect_error(FromCellspec(x, c(features[1L], features[1L])), "unique known")
  expect_error(FromCellspec(x, "UNKNOWN"), "unique known")
  expect_error(FromCellspec(x, NA_character_), "unique known")
  expect_error(FromCellspec(x, 1), "unique known")
  expect_error(FromCellspec(x, project = " "), "project")
  x$cells$source_sample_id <- "conflict"
  expect_error(FromCellspec(x), "reserved")
})

test_that("invalid canonical inputs cannot be silently repaired", {
  skip_if_not_installed("cellspecR")
  x <- cellspecR::cs_example()
  x$images$pixel_size <- NA_real_
  expect_error(FromCellspec(x), class = "cellspec_error")
  x <- cellspecR::cs_example()
  x$cells$x[1L] <- Inf
  expect_error(FromCellspec(x), class = "cellspec_error")
  x <- cellspecR::cs_example()
  x$measurements <- x$measurements[, rev(seq_len(ncol(x$measurements))), drop = FALSE]
  expect_error(FromCellspec(x), class = "cellspec_error")
})

test_that("independent images remain separate even with identical biological sample IDs", {
  skip_if_not_installed("cellspecR")
  x <- cellspecR::cs_example()
  expect_gte(nrow(x$images), 2L)
  x$images$sample_id[] <- "shared_sample"
  x$cells$sample_id[] <- "shared_sample"
  y <- FromCellspec(x)
  expect_setequal(unique(y@meta_data$sample_id), x$images$image_id)
  y <- DelaunayNetwork(y)
  edges <- y@spatial$delaunay_edges
  expect_gt(nrow(edges), 0L)
  expect_true(all(y@meta_data$image_id[edges$from] == y@meta_data$image_id[edges$to]))
})


test_that("source provenance and patient mapping cannot be overwritten silently", {
  skip_if_not_installed("cellspecR")
  x <- cellspecR::cs_example()
  x$cells$subject_id <- "conflicting_patient"
  expect_error(FromCellspec(x), class = "cellspec_error")
  x <- cellspecR::cs_example()
  attr(x$cells, "cellspec_import") <- list(scope = "previous_import")
  expect_error(FromCellspec(x), "already carries")
  x <- cellspecR::cs_example()
  x$images$subject_id <- rep("patient_one", nrow(x$images))
  expect_identical(FromCellspec(x)@meta_data$subject_id,
                   x$images$subject_id[match(x$cells$image_id, x$images$image_id)])
  x$cells <- x$cells[FALSE, , drop = FALSE]
  x$measurements <- x$measurements[FALSE, , drop = FALSE]
  if (!is.null(x$adjacency)) x$adjacency <- x$adjacency[FALSE, , drop = FALSE]
  y <- FromCellspec(x)
  expect_equal(NCells(y), 0L)
  expect_identical(y@counts, x$measurements)
})
