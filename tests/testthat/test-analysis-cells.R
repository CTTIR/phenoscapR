test_that("cell arrays are read from an archive with a keep mask", {
  skip_if_not(requireNamespace("cellspecR", quietly = TRUE))
  f <- withr::local_tempfile(fileext = ".npz")
  cellspecR::cs_write_npz(list(x_um = c(1.5, 2.5, 3.5), y_um = c(0, 1, 2),
                               label = c("a", "b", "a"), kept = c(TRUE, FALSE, TRUE),
                               grid = matrix(1:6, 3)), f)
  out <- ReadCellArrays(f, c(x = "x_um", y = "y_um", type = "label"), keep = "kept")
  expect_identical(names(out), c("source_row", "x", "y", "type"))
  expect_identical(out$source_row, c(1L, 3L))
  expect_identical(out$x, c(1.5, 3.5))
  expect_identical(out$type, c("a", "a"))
  same <- ReadCellArrays(f, list(x = "x_um"), row_id = NULL)
  expect_identical(names(same), "x")
  expect_error(ReadCellArrays(f, c("x_um", "grid")), "one-dimensional")
  expect_error(ReadCellArrays(f, "x_um", keep = "label"), "logical")
})

test_that("nearest-target distance summaries equal brute force", {
  set.seed(2)
  cells <- data.frame(x = stats::runif(120, 0, 50), y = stats::runif(120, 0, 50),
                      type = sample(c("t1", "t2", "a", "b", "o"), 120, replace = TRUE),
                      area = stats::runif(120, 1, 3))
  out <- SummarizeNearestDistances(cells, from = list(A = "a", B = "b"), to = c("t1", "t2"),
                                   radius = c(2, 5), area = "area", area_divisor = 10)
  tgt <- cells$type %in% c("t1", "t2")
  for (k in c("A", "B")) {
    src <- cells$type == tolower(k)
    d <- vapply(which(src), function(i) {
      min(sqrt((cells$x[tgt] - cells$x[i])^2 + (cells$y[tgt] - cells$y[i])^2))
    }, numeric(1))
    rows <- out[out$from == k, ]
    expect_identical(rows$n, rep(sum(src), 2))
    expect_equal(rows$median_distance[1], stats::median(d))
    expect_equal(rows$within, 100 * c(mean(d <= 2), mean(d <= 5)))
  }
  expect_equal(out$area[1], sum(cells$area) / 10)
  none <- SummarizeNearestDistances(cells, from = list(Z = "absent"), to = "t1", radius = 3)
  expect_identical(none$n, 0L)
  expect_true(is.na(none$median_distance))
  expect_error(SummarizeNearestDistances(cells, from = list(A = "a"), to = "a"), "disjoint")
})

test_that("composition, densities and subset fractions are exact counts", {
  cells <- data.frame(type = c("t", "t", "a", "b", "t", "a"), pos = c(TRUE, FALSE, FALSE, TRUE, TRUE, TRUE),
                      area = c(10, 12, 9, 11, 8, 50))
  out <- SummarizeCellComposition(cells, "type", c("t", "a", "b", "c"), area = "area",
    area_divisor = 100, prefix = c(fraction = "pct|", density = "density|"),
    totals = c(cells = "n", area = "mm2"),
    fractions = list("pos % t" = list(numerator = "t", denominator = "t", flag = "pos"),
                     "a % ab" = list(numerator = "a", denominator = c("a", "b"))))
  get <- function(e) out$value[out$endpoint == e]
  expect_identical(get("pct|t"), 100 * 3 / 6)
  expect_identical(get("pct|c"), 0)
  expect_identical(get("pos % t"), 100 * (2 / 3))
  expect_identical(get("a % ab"), 100 * (2 / 3))
  expect_identical(get("mm2"), 100 / 100)
  expect_identical(get("density|a"), 2 / 1)
  expect_identical(get("n"), 6)
  expect_identical(out$type[out$endpoint == "density|b"], "b")
  expect_identical(nrow(out), 4L + 2L + 4L + 2L)
  expect_error(SummarizeCellComposition(cells, "type", c("t", "a")), "outside the registry")
  bad <- cells
  bad$pos <- 2
  expect_error(SummarizeCellComposition(bad, "type", c("t", "a", "b"),
    fractions = list(f = list(numerator = "t", denominator = "t", flag = "pos"))), "0/1")
})
