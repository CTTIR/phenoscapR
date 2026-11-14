test_that("large finite radii cap the neighbour search before integer conversion", {
  xy <- matrix(c(0, 1, 1, 0, 0, 0, 1, 1), 4)
  r <- c(0, 1, 2, 1e5, 1e100)
  fast <- .radius_count_sweep(xy, r)
  expect_equal(fast, c(0, 8, 12, 12, 12))
  local_mocked_bindings(requireNamespace = function(...) FALSE)
  expect_equal(.radius_count_sweep(xy, r), fast)
})

test_that("Ripley estimates retain their formulas at large radii", {
  object <- CreateSpatialObject(matrix(1:4, ncol = 1,
                                       dimnames = list(NULL, "v")),
                                data.frame(x = c(0, 1, 1, 0), y = c(0, 0, 1, 1)))
  expect_equal(RipleysK(object, r_seq = c(2, 1e5))$K, c(3 / 4, 3 / 4))
  expect_true(all(is.na(RipleysK(object, r_seq = c(2, 1e5), correction = "border")$K)))
  # All non-self corner pairs have zero translate overlap, retaining the
  # historical zero-contribution convention for those pairs.
  expect_equal(RipleysK(object, r_seq = c(2, 1e5), correction = "translation")$K, c(0, 0))
})

test_that("undefined planar windows fail before dispersion is reported", {
  for (xy in list(data.frame(x = 0:3, y = 0), data.frame(x = 0, y = 0))) {
    object <- CreateSpatialObject(matrix(seq_len(nrow(xy)), ncol = 1,
                                         dimnames = list(NULL, "v")), xy)
    before <- serialize(object, NULL)
    for (correction in c("none", "border", "translation")) {
      expect_error(RipleysK(object, r_seq = 1, correction = correction),
                    "positive finite bounding-box area")
    }
    expect_error(PairCorrelation(object, r_seq = 1), "positive finite bounding-box area")
    expect_identical(serialize(object, NULL), before)
  }
})

test_that("target-filtered bounding-box convention remains explicit", {
  object <- CreateSpatialObject(matrix(1:5, ncol = 1,
                                       dimnames = list(NULL, "v")),
    data.frame(x = c(0, 1, 1, 0, 10), y = c(0, 0, 1, 1, 10)),
    data.frame(cell_id = 1:5, sample_id = "s", phenotype = c(rep("A", 4), "B")))
  expect_equal(RipleysK(object, r_seq = 2, target = "A")$K, 3 / 4)
  expect_error(RipleysK(object, r_seq = 2, target = "B"), "positive finite")
  expect_error(RipleysK(object, r_seq = 2, target = "missing"), "positive finite")
  expect_error(PairCorrelation(object, r_seq = 2, target = "missing"), "positive finite")
})
