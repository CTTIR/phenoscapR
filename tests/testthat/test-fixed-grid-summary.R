grid_summary_fixture <- function() {
  cells <- data.frame(cell_id = c("a", "b", "c", "a"),
    sample_id = c("one", "one", "one", "two"), frame_id = "physical",
    x = c(0, 1, 11, 0), y = 0)
  settings <- data.frame(setting_id = "g", size_um = 10,
    offset_x_um = 0, offset_y_um = 0)
  frames <- data.frame(sample_id = c("one", "two"),
    frame_id = "physical", unit = "um")
  list(membership = AssignFixedGrid(cells, settings, frames), settings = settings,
    annotations = data.frame(sample_id = cells$sample_id, cell_id = cells$cell_id,
      type = c("T", "B", "T", NA_character_), signal = c(TRUE, FALSE, NA, TRUE)),
    categories = "type", indicators = "signal")
}

test_that("grid summaries keep samples, actual counts and missingness explicit", {
  x <- grid_summary_fixture()
  z <- do.call(SummarizeFixedGrid, x)
  expect_identical(z$bins$n_cells, c(2L, 1L, 1L))
  expect_identical(z$indicators$n_true, c(1L, 0L, 1L))
  expect_identical(z$indicators$n_false, c(1L, 0L, 0L))
  expect_identical(z$indicators$n_unavailable, c(0L, 1L, 0L))
  expect_equal(z$indicators$fraction_true, c(.5, NA, 1))
  expect_identical(z$indicators$status, c("COMPLETE", "UNAVAILABLE", "COMPLETE"))
  expect_identical(z$categories$value, c("B", "T", "T", NA_character_))
  expect_identical(z$categories$n_cells, rep(1L, 4))
  expect_equal(z$categories$fraction, c(.5, .5, 1, 1))
  expect_identical(z$categories$status, c("KNOWN", "KNOWN", "KNOWN", "UNAVAILABLE"))
  expect_equal(sum(z$bins$n_cells), nrow(x$membership))
  y <- x; y$annotations$signal[1] <- NA
  expect_identical(do.call(SummarizeFixedGrid, y)$indicators$status[1], "PARTIAL")
  expect_true(is.na(do.call(SummarizeFixedGrid, y)$indicators$fraction_true[1]))
  y <- x; y$annotations <- y$annotations[4:1, ]; y$membership <- y$membership[4:1, ]
  expect_identical(do.call(SummarizeFixedGrid, y), z)
  y <- x; y$membership <- data.table::as.data.table(y$membership)
  y$annotations <- data.table::as.data.table(y$annotations)
  expect_identical(do.call(SummarizeFixedGrid, y), z)
  expect_equal(as.data.frame(y$membership), x$membership)
  y <- x; y$membership <- y$membership[0, ]
  e <- do.call(SummarizeFixedGrid, y)
  expect_true(all(vapply(e, nrow, integer(1)) == 0L))
  y <- x; y$categories <- character(); y$indicators <- character()
  expect_equal(nrow(do.call(SummarizeFixedGrid, y)$bins), 3)
})

test_that("grid joins and conflicting bin geometry fail before aggregation", {
  x <- grid_summary_fixture()
  y <- x; y$annotations <- y$annotations[-1, ]
  expect_error(do.call(SummarizeFixedGrid, y), "Missing annotation")
  y <- x; y$annotations <- rbind(y$annotations, y$annotations[1, ])
  expect_error(do.call(SummarizeFixedGrid, y), "Duplicate annotation")
  y <- x; y$membership <- rbind(y$membership, y$membership[1, ])
  expect_error(do.call(SummarizeFixedGrid, y), "Duplicate membership")
  y <- x; y$membership$xmax_um[2] <- 11
  expect_error(do.call(SummarizeFixedGrid, y), "bounds differ from settings")
  y <- x; y$membership$frame_id[2] <- "other"
  expect_error(do.call(SummarizeFixedGrid, y), "Conflicting sample frame")
  y <- x; y$membership$grid_x[1] <- .5
  expect_error(do.call(SummarizeFixedGrid, y), "integer grid")
  y <- x; y$membership$xmin_um[1] <- Inf
  expect_error(do.call(SummarizeFixedGrid, y), "finite bin")
  y <- x; y$membership$xmin_um[1] <- 10
  expect_error(do.call(SummarizeFixedGrid, y), "increasing bin")
  y <- x; y$annotations$signal <- as.integer(y$annotations$signal)
  expect_error(do.call(SummarizeFixedGrid, y), "logical")
  y <- x; y$annotations$type <- factor(y$annotations$type)
  expect_error(do.call(SummarizeFixedGrid, y), "character")
  y <- x; y$categories <- "absent"
  expect_error(do.call(SummarizeFixedGrid, y), "columns")
  y <- x; y$categories <- c("type", "type")
  expect_error(do.call(SummarizeFixedGrid, y), "unique column")
  y <- x; y$indicators <- "type"
  expect_error(do.call(SummarizeFixedGrid, y), "disjoint")
})


test_that("grid summaries bind every bin to explicit settings", {
  x <- grid_summary_fixture()
  y <- x; y$membership$size_um[3] <- 20; y$membership$xmax_um[3] <- 30
  expect_error(do.call(SummarizeFixedGrid, y), "size differs from settings")
  y <- x; y$membership$xmin_um[3] <- 15; y$membership$xmax_um[3] <- 25
  expect_error(do.call(SummarizeFixedGrid, y), "bounds differ from settings")
  y <- x; y$settings$setting_id <- "other"
  expect_error(do.call(SummarizeFixedGrid, y), "Unknown membership setting")
  y <- x; y$settings <- rbind(y$settings, y$settings)
  expect_error(do.call(SummarizeFixedGrid, y), "unique IDs")
  y <- x; y$settings$offset_x_um <- Inf
  expect_error(do.call(SummarizeFixedGrid, y), "finite numeric")
  y <- x; y$settings$size_um <- 0
  expect_error(do.call(SummarizeFixedGrid, y), "positive grid")
})
