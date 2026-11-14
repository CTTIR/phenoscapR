interop_coordinate_fixture <- function() {
  CreateSpatialObject(
    matrix(1:12, 4, dimnames = list(NULL, c("A", "B", "C"))),
    data.frame(z = 11:14, y = 21:24, x = 31:34),
    data.frame(cell_id = c("a", "b", "a", "b"),
               sample_id = c("s", "s", "t", "t"), note = letters[1:4])
  )
}

test_that("Seurat preserves extra coordinates through subset and reorder", {
  skip_if_not_installed("Seurat")
  o <- interop_coordinate_fixture()
  o@coords$annotation <- c("left", "right", "upper", "lower")
  before <- serialize(o, NULL)
  se <- as_Seurat(o)
  expect_equal(unname(SeuratObject::Embeddings(se, "spatial")),
               unname(as.matrix(o@coords[, c("x", "y")])))
  expect_identical(serialize(o, NULL), before)
  for (i in list(1:4, c(4L, 2L))) {
    selected <- se[, colnames(se)[i]]
    # Seurat may retain its own cell order when selecting requested names.
    i <- match(colnames(selected), colnames(se))
    saved <- selected@misc$phenoscapR_coordinates$extra
    selected@misc$phenoscapR_coordinates$extra <- saved[rev(seq_len(nrow(saved))), ]
    selected@meta.data$x <- selected@meta.data$x + 100
    back <- as_SpatialCellData(selected)
    expect_equal(back@coords$x, o@coords$x[i] + 100)
    expect_equal(back@coords$y, o@coords$y[i])
    expect_equal(back@coords$z, o@coords$z[i])
    expect_equal(back@coords$annotation, o@coords$annotation[i])
    expect_equal(back@meta_data$note, o@meta_data$note[i])
    expect_equal(unname(back@counts), unname(o@counts[i, , drop = FALSE]))
  }
  reordered <- o[c(4, 2, 1, 3), ]
  reordered_back <- as_SpatialCellData(as_Seurat(reordered))
  expect_equal(reordered_back@coords$x, reordered@coords$x)
  expect_equal(reordered_back@coords$annotation, reordered@coords$annotation)
  expect_equal(reordered_back@meta_data$note, reordered@meta_data$note)
  se@misc$phenoscapR_coordinates$extra <- se@misc$phenoscapR_coordinates$extra[-1, ]
  expect_error(as_SpatialCellData(se), "Invalid phenoscapR coordinate mapping")
  se@misc$phenoscapR_coordinates <- "malformed"
  expect_error(as_SpatialCellData(se), "Invalid phenoscapR coordinate mapping")
  o@meta_data$x <- rep(0, 4)
  expect_error(as_Seurat(o), "conflicts with spatial coordinates")
})

test_that("SpatialExperiment preserves named numeric coordinate dimensions", {
  skip_if_not_installed("SpatialExperiment")
  o <- interop_coordinate_fixture()
  spe <- as_SpatialExperiment(o)
  back <- as_SpatialCellData(spe)
  expect_equal(back@coords, o@coords, ignore_attr = TRUE)
  expect_identical(names(back@coords), names(o@coords))
  expect_equal(unname(back@counts), unname(o@counts))
  selected <- spe[, c(4, 2)]
  expect_equal(as_SpatialCellData(selected)@coords$x, o@coords$x[c(4, 2)])
  coords <- SpatialExperiment::spatialCoords(spe)
  colnames(coords) <- c("z", "u", "v")
  SpatialExperiment::spatialCoords(spe) <- coords
  expect_equal(as_SpatialCellData(spe)@coords$x, o@coords$z)
  colnames(coords) <- c("z", "y", "v")
  SpatialExperiment::spatialCoords(spe) <- coords
  expect_error(as_SpatialCellData(spe), "both x/y names or neither")
  colnames(coords) <- c("x", "y", "x")
  SpatialExperiment::spatialCoords(spe) <- coords
  expect_error(as_SpatialCellData(spe), "uniquely named")
  o@coords$annotation <- letters[1:4]
  expect_error(as_SpatialExperiment(o), "plain numeric columns")
})
