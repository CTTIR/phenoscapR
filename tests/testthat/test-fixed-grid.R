grid_fixture <- function() {
  list(cells = data.frame(cell_id = c("a", "b", "c", "a"),
    sample_id = c("s1", "s1", "s1", "s2"),
    frame_id = c("f1", "f1", "f1", "f2"),
    x = c(-0.5, 0, 10, 0), y = c(0, 10, -0.5, 10)),
    settings = data.frame(setting_id = c("base", "shift"),
      size_um = c(10, 10), offset_x_um = c(0, 5), offset_y_um = c(0, 5)),
    frames = data.frame(sample_id = c("s1", "s2"),
      frame_id = c("f1", "f2"), unit = "um"))
}

test_that("fixed grids use physical half-open bins independently by sample", {
  x <- grid_fixture()
  z <- do.call(AssignFixedGrid, x)
  expect_equal(nrow(z), 8)
  b <- z[z$setting_id == "base", ]
  expect_identical(b$grid_x, c(-1L, 0L, 1L, 0L))
  expect_identical(b$grid_y, c(0L, 1L, -1L, 1L))
  expect_equal(b$xmin_um, c(-10, 0, 10, 0))
  expect_equal(b$ymax_um, c(10, 20, 0, 20))
  s <- z[z$setting_id == "shift", ]
  expect_identical(s$grid_x, c(-1L, -1L, 0L, -1L))
  expect_identical(s$grid_y, c(-1L, 0L, -1L, 0L))
  expect_equal(s$xmin_um, c(-5, -5, 5, -5))
  expect_identical(z$frame_id, rep(c("f1", "f1", "f1", "f2"), 2))
  expect_false(any(c("tissue_area", "density", "reviewed") %in% names(z)))
  y <- x; y$cells <- y$cells[4:1, ]; y$settings <- y$settings[2:1, ]
  y$frames <- y$frames[2:1, ]
  expect_identical(do.call(AssignFixedGrid, y), z)
  y <- x; y$cells <- y$cells[0, ]
  expect_identical(do.call(AssignFixedGrid, y), z[0, ])
  original <- x$cells
  y <- x; y$cells <- data.table::as.data.table(y$cells)
  expect_identical(do.call(AssignFixedGrid, y), z)
  expect_equal(as.data.frame(y$cells), original)
})

test_that("keys, units and frame mappings cannot silently change", {
  x <- grid_fixture()
  y <- x; y$cells <- rbind(y$cells, y$cells[1, ])
  expect_error(do.call(AssignFixedGrid, y), "Duplicate cell")
  y <- x; y$frames <- rbind(y$frames, y$frames[1, ])
  expect_error(do.call(AssignFixedGrid, y), "Duplicate frame")
  y <- x; y$frames <- y$frames[-1, ]
  expect_error(do.call(AssignFixedGrid, y), "Unknown sample")
  y <- x; y$cells$frame_id[1] <- "other"
  expect_error(do.call(AssignFixedGrid, y), "Frame mismatch")
  y <- x; y$frames$unit <- "px"
  expect_error(do.call(AssignFixedGrid, y), "micrometre")
  for (bad in list(NA_character_, "", " ", "a\034b")) {
    y <- x; y$cells$cell_id[1] <- bad
    expect_error(do.call(AssignFixedGrid, y), "Keys must")
  }
  y <- x; y$cells$cell_id <- factor(y$cells$cell_id)
  expect_error(do.call(AssignFixedGrid, y), "Keys must")
  y <- x; y$settings$setting_id <- "same"
  expect_error(do.call(AssignFixedGrid, y), "Duplicate setting")
  y <- x; names(y$cells)[5] <- "x"
  expect_error(do.call(AssignFixedGrid, y), "columns")
})

test_that("nonfinite coordinates, invalid grids and overflow fail closed", {
  x <- grid_fixture()
  for (bad in list(NA_real_, NaN, Inf, "1")) {
    y <- x; y$cells$x[1] <- bad
    expect_error(do.call(AssignFixedGrid, y), "finite numeric")
  }
  for (bad in c(0, -1, NA_real_, Inf)) {
    y <- x; y$settings$size_um[1] <- bad
    expect_error(do.call(AssignFixedGrid, y), "positive finite")
  }
  y <- x; y$settings$offset_x_um[1] <- Inf
  expect_error(do.call(AssignFixedGrid, y), "finite numeric")
  y <- x; y$cells$x[1] <- 1e100
  expect_error(do.call(AssignFixedGrid, y), "index range")
  y <- x; y$cells$x <- rep(1e100, 4); y$settings$offset_x_um <- 1e100
  expect_error(do.call(AssignFixedGrid, y), "representable")
  y <- x; y$settings <- y$settings[0, ]
  expect_error(do.call(AssignFixedGrid, y), "At least one setting")
})

test_that("catastrophic cancellation cannot produce a non-containing bin", {
  x <- grid_fixture()
  x$cells <- x$cells[1, ]
  x$settings <- x$settings[1, ]
  contains <- function(r) {
    r$xmin_um <= x$cells$x && x$cells$x < r$xmax_um && r$ymin_um <= x$cells$y && x$cells$y < r$ymax_um
  }
  # The rounded division would put these cells one bin too far; the index is
  # corrected against the reported bounds.
  x$cells$x <- -2^-54
  x$cells$y <- 0
  x$settings$size_um <- 1
  x$settings$offset_x_um <- -1
  r <- do.call(AssignFixedGrid, x)
  expect_identical(r$grid_x, 0L)
  expect_true(contains(r))
  x$cells$x <- -1
  x$settings$size_um <- 1e9
  x$settings$offset_x_um <- -1e16
  expect_true(contains(do.call(AssignFixedGrid, x)))
  x$cells$x <- 0
  x$cells$y <- -2^-54
  x$settings$size_um <- 1
  x$settings$offset_x_um <- 0
  x$settings$offset_y_um <- -1
  r <- do.call(AssignFixedGrid, x)
  expect_identical(r$grid_y, 0L)
  expect_true(contains(r))
})

test_that("coordinates on rounded bin edges join the bin on their positive side", {
  frames <- data.frame(sample_id = "s", frame_id = "f", unit = "um")
  one <- function(x, size, offset) {
    cells <- data.frame(cell_id = sprintf("c%03d", seq_along(x)), sample_id = "s", frame_id = "f", x = x, y = 0)
    AssignFixedGrid(cells, data.frame(setting_id = "g", size_um = size, offset_x_um = offset, offset_y_um = 0), frames)
  }
  r <- one(10.7, 7, 3.7)
  expect_identical(r$grid_x, 1L)
  expect_equal(c(r$xmin_um, r$xmax_um), c(10.7, 17.7))
  expect_identical(one(128.7, 12.5, 3.7)$grid_x, 10L)
  for (size in c(0.3, 7, 12.5, 33.3)) for (offset in c(0, 3.7, -5.3)) {
    x <- offset + (-40:40) * size
    r <- one(x, size, offset)
    expect_true(all(r$xmin_um <= x & x < r$xmax_um))
  }
  # Coordinates away from edges keep their bins.
  r <- one(c(-1, 0, 9.99, 10, 25), 10, 0)
  expect_identical(r$grid_x, c(-1L, 0L, 0L, 1L, 2L))
})
