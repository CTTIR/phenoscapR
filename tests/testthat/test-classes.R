test_that("AkoyaExperiment can be created", {
  counts <- matrix(rnorm(20), nrow = 5,
                   dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK")))
  coords <- data.frame(x = 1:5, y = 1:5)
  obj <- CreateAkoyaObject(counts, coords, sample_id = "s1")

  expect_s4_class(obj, "AkoyaExperiment")
  expect_equal(NCells(obj), 5L)
  expect_equal(NMarkers(obj), 4L)
  expect_equal(Markers(obj), c("CD3", "CD8", "DAPI", "PanCK"))
})

test_that("accessors work correctly", {
  counts <- matrix(rnorm(20), nrow = 5,
                   dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK")))
  coords <- data.frame(x = 1:5, y = 6:10)
  obj <- CreateAkoyaObject(counts, coords, sample_id = "test")

  expect_equal(nrow(Coords(obj)), 5L)
  expect_equal(Coords(obj)$x, 1:5)
  expect_equal(Meta(obj)$sample_id, rep("test", 5))
  expect_equal(dim(obj), c(5L, 4L))
  expect_equal(Idents(obj), rep("test", 5))
})

test_that("subsetting works", {
  counts <- matrix(rnorm(20), nrow = 5,
                   dimnames = list(NULL, c("CD3", "CD8", "DAPI", "PanCK")))
  coords <- data.frame(x = 1:5, y = 1:5)
  obj <- CreateAkoyaObject(counts, coords)

  sub <- obj[1:3, ]

  expect_equal(NCells(sub), 3L)
  expect_equal(NMarkers(sub), 4L)

  sub2 <- obj[, c("CD3", "CD8")]
  expect_equal(NMarkers(sub2), 2L)
  expect_equal(NCells(sub2), 5L)
})

test_that("[[ and $ access metadata", {
  counts <- matrix(rnorm(10), nrow = 5,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = 1:5, y = 1:5)
  obj <- CreateAkoyaObject(counts, coords, sample_id = "s1")

  expect_equal(obj[["sample_id"]], rep("s1", 5))
  expect_equal(obj$sample_id, rep("s1", 5))
})

test_that("show method runs without error", {
  counts <- matrix(rnorm(10), nrow = 5,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = 1:5, y = 1:5)
  obj <- CreateAkoyaObject(counts, coords)

  expect_output(show(obj), "AkoyaExperiment")
})
