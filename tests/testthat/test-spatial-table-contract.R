test_that("standalone spatial tables require complete sample identity and coordinates", {
  base <- data.table::data.table(sample_id = c("a", "b", "a"),
                                x = c(0, 0, 3), y = c(0, 0, 4))
  funcs <- list(function(x) nearest_neighbours(x),
                function(x) cell_density(x, 5))
  for (fun in funcs) {
    expect_error(fun(as.data.frame(base)), "data.table")
    bad <- data.table::copy(base); bad[, sample_id := NULL]
    expect_error(fun(bad), "sample_id")
    for (id in c(NA_character_, "", " ")) {
      bad <- data.table::copy(base); bad$sample_id[2] <- id
      expect_error(fun(bad), "sample_id")
    }
    for (v in c(NA_real_, NaN, Inf, -Inf)) {
      bad <- data.table::copy(base); bad$x[2] <- v
      expect_error(fun(bad), "finite numeric")
    }
    bad <- data.table::copy(base); bad$x <- as.character(bad$x)
    expect_error(fun(bad), "finite numeric")
    bad <- as.data.frame(base); bad$x <- cbind(bad$x, bad$x)
    expect_warning(data.table::setDT(bad), "multi-column type")
    expect_error(fun(bad), "finite numeric")
    bad <- as.data.frame(base); bad$sample_id <- cbind(bad$sample_id, bad$sample_id)
    expect_warning(data.table::setDT(bad), "multi-column type")
    expect_error(fun(bad), "sample_id")
    bad <- data.table::copy(base); data.table::setnames(bad, c("sample_id", "x", "x"))
    expect_error(fun(bad), "unique column names")
  }
  expect_equal(nearest_neighbours(base)$nn_distance, c(5, NA_real_, 5))
  expect_equal(cell_density(base, 5)$density, c(1L, 0L, 1L))
  base$sample_id <- factor(base$sample_id)
  expect_equal(nearest_neighbours(base)$nn_distance, c(5, NA_real_, 5))
  expect_equal(cell_density(base, 5)$density, c(1L, 0L, 1L))
})

test_that("empty standalone tables preserve schema and harmless extra columns", {
  empty <- data.table::data.table(sample_id = character(), x = numeric(),
                                  y = numeric(), notes = character())
  before <- data.table::copy(empty)
  nn <- nearest_neighbours(empty)
  dens <- cell_density(empty, 0)
  expect_identical(nn$nn_distance, numeric())
  expect_identical(dens$density, integer())
  expect_identical(nn[, names(empty), with = FALSE], empty)
  expect_identical(dens[, names(empty), with = FALSE], empty)
  expect_identical(empty, before)
  expect_error(nearest_neighbours(empty, "T"), "phenotype")
  empty[, phenotype := character()]
  expect_identical(nearest_neighbours(empty, "T")$nn_distance, numeric())
  expect_identical(cell_density(empty, 0, "T")$density, integer())
})

test_that("target selectors cannot silently recycle across cells", {
  dt <- data.table::data.table(sample_id = "a", x = 1:3, y = 1:3,
                               phenotype = c("A", "B", "A"))
  for (bad in list(c("A", "B"), NA_character_, matrix("A"), 1)) {
    expect_error(nearest_neighbours(dt, bad), "target_phenotype")
    expect_error(cell_density(dt, 1, bad), "target_phenotype")
  }
})
