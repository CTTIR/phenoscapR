test_that("paired ranks preserve ties and independent group keys", {
  d <- data.frame(sample = rep(c("b", "a"), each = 4),
    id = rep(letters[1:4], 2), x = c(1, 1, 3, 4, 1, 2, 3, 4),
    y = c(4, 3, 2, 1, 1, 2, 3, 4))
  z <- CorrelateGroupedRanks(d, "sample", "id", "x", "y")
  expect_identical(z$sample, c("a", "b"))
  expect_equal(z$rho, c(1, -4.5 / sqrt(4.5 * 5)), tolerance = 1e-15)
  expect_identical(z$status, c("COMPLETE", "COMPLETE"))
  expect_equal(z$n_available, c(4, 4))
  expect_equal(z$n_unique_x, c(4, 3))
  expect_identical(z, CorrelateGroupedRanks(d[8:1, ], "sample", "id", "x", "y"))
  d$x <- d$x * 1e300
  expect_equal(CorrelateGroupedRanks(d, "sample", "id", "x", "y")$rho,
    z$rho, tolerance = 0)
})

test_that("paired missingness and status precedence are explicit", {
  d <- data.frame(g = "a", id = letters[1:5],
    x = c(1, 2, 3, NA, 5), y = c(3, 2, 1, 4, NA))
  f <- function(...) CorrelateGroupedRanks(d, "g", "id", "x", "y", ...)
  z <- f()
  expect_identical(z$status, "MISSING_PAIRS")
  expect_true(is.na(z$rho))
  expect_equal(unlist(z[c("n_supplied", "n_available", "n_unavailable")]),
    c(n_supplied = 5, n_available = 3, n_unavailable = 2))
  expect_identical(f(missing = "available")$status, "PARTIAL")
  expect_equal(f(missing = "available")$rho, -1)
  expect_identical(f(min_pairs = 4)$status, "INSUFFICIENT")
  d$x[] <- NA_real_
  expect_identical(f()$status, "UNAVAILABLE")
  d$x[] <- 1
  d$y[] <- 2
  expect_identical(f()$status, "CONSTANT_BOTH")
  d$y <- 1:5
  expect_identical(f()$status, "CONSTANT_X")
  d$x <- 1:5
  d$y[] <- 1
  expect_identical(f()$status, "CONSTANT_Y")
  d$y <- 5:1
  expect_equal(f()$rho, -1)
  d <- d[1:2, ]
  expect_identical(f()$status, "INSUFFICIENT")
  expect_equal(f(min_pairs = 2)$rho, -1)
  d <- d[FALSE, ]
  z <- f()
  expect_equal(nrow(z), 0)
  expect_type(z$rho, "double")
  expect_type(z$status, "character")
})

test_that("malformed keys and numeric policies fail closed", {
  d <- data.frame(g = "a", id = letters[1:3], x = 1:3, y = 3:1)
  f <- function(z = d, ...) CorrelateGroupedRanks(z, "g", "id", "x", "y", ...)
  for (bad in list(NA_real_, NaN, Inf, 1, 2.5, TRUE, matrix(3))) {
    expect_error(f(min_pairs = bad), "min_pairs")
  }
  for (bad in list(Inf, -Inf, NaN, "bad")) {
    z <- d
    z$x[1] <- bad
    expect_error(f(z), "finite numeric")
  }
  z <- d
  z$x <- I(matrix(1:3))
  expect_error(f(z), "finite numeric")
  expect_error(f(d[c(1, 1, 2), ]), "Duplicate observation")
  for (column in c("g", "id")) {
    z <- d
    z[[column]] <- I(matrix(letters[1:6], nrow = 3))
    expect_error(f(z), "dimensionless")
  }
  for (bad in c("", " ", NA_character_, "a\034b")) {
    z <- d
    z$g[1] <- bad
    expect_error(f(z), "Keys")
  }
  expect_error(CorrelateGroupedRanks(d, "g", "id", "x", "x"), "distinct")
  expect_error(CorrelateGroupedRanks(d, c("g", "g"), "id", "x", "y"), "Groups")
  expect_error(CorrelateGroupedRanks(d, matrix("g"), "id", "x", "y"), "Groups")
  z <- d
  names(z)[1] <- "rho"
  expect_error(CorrelateGroupedRanks(z, "rho", "id", "x", "y"), "distinct")
  expect_error(f(missing = "omit"), "arg")
})

test_that("legal column names do not collide with grouping internals", {
  d <- data.frame(g = "a", id = letters[1:3], x = 1:3, y = 3:1)
  for (name in c(".SD", ".N", ".I", ".GRP", ".BY", "a b", "if")) {
    for (column in c("g", "id", "x", "y")) {
      z <- d
      selected <- names(d)
      selected[match(column, selected)] <- name
      names(z) <- selected
      result <- CorrelateGroupedRanks(z, selected[1], selected[2],
        selected[3], selected[4])
      expect_identical(names(result)[1], selected[1])
      expect_equal(result$rho, -1)
      expect_identical(result$status, "COMPLETE")
    }
  }
})
