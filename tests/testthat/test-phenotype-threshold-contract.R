.threshold_fixture <- function() {
  counts <- matrix(c(.5, .5, .5, .5, 0, .4, .7, NA_real_), ncol = 2,
                   dimnames = list(NULL, c('CD3', 'CD8')))
  list(dt = data.table::data.table(sample_id = 's', cell_id = 1:4,
       x = 1:4, y = 0, CD3 = counts[, 1], CD8 = counts[, 2]),
       object = CreateSpatialObject(counts, data.frame(x = 1:4, y = 0)))
}

test_that('phenotype thresholds cannot recycle, coerce or silently omit names', {
  fixture <- .threshold_fixture()
  invalid <- list(list(CD3 = c(.1, .9)), list(CD3 = NA_real_),
    list(CD3 = NaN), list(CD3 = Inf), list(CD3 = -Inf),
    list(CD3 = '0.3'), list(CD3 = TRUE), list(CD3 = matrix(.3)),
    list(CD3 = .3 + 0i), list(CD3 = factor('low')), list(CD3 = numeric()),
    list(CD3 = list(.3)), list(.3), c(.3), setNames(list(.2, .8), c('CD3','CD3')),
    setNames(list(.3), ''), setNames(list(.3), ' '), setNames(list(.3), NA_character_),
    matrix(.3, dimnames = list('CD3',NULL)), '0.3', TRUE,
    data.frame(CD3 = .3))
  for (thresholds in invalid) {
    before <- data.table::copy(fixture$dt)
    expect_error(phenotype_cells(fixture$dt, thresholds), 'threshold')
    expect_identical(fixture$dt, before)
    expect_error(PhenotypeCells(fixture$object, thresholds), 'threshold')
  }
})

test_that('valid thresholds retain marker order, equality and missing-intensity semantics', {
  fixture <- .threshold_fixture()
  for (thresholds in list(list(CD3 = .5, CD8 = .4), c(CD3 = .5, CD8 = .4))) {
    expected <- c('CD3+', 'CD3+/CD8+', 'CD3+/CD8+', 'CD3+')
    expect_identical(phenotype_cells(fixture$dt, thresholds)$phenotype, expected)
    expect_identical(PhenotypeCells(fixture$object, thresholds)@meta_data$phenotype,
                     expected)
  }
  expect_identical(phenotype_cells(fixture$dt, list(CD8 = .4, CD3 = .5))$phenotype,
                   c('CD3+', 'CD8+/CD3+', 'CD8+/CD3+', 'CD3+'))
  expect_identical(phenotype_cells(fixture$dt, list())$phenotype, rep('Negative',4))
  expect_identical(PhenotypeCells(fixture$object, list())@meta_data$phenotype,
                   rep('Negative',4))
  expect_identical(phenotype_cells(fixture$dt, list(CD8 = 0L))$phenotype,
                   c('CD8+', 'CD8+', 'CD8+', 'Negative'))
  expect_identical(phenotype_cells(fixture$dt, list(CD3 = .5),
                                  labels = c('CD3+' = 'T'))$phenotype, rep('T',4))
  expect_error(phenotype_cells(fixture$dt, list(absent = 1)), 'Markers not found')
})

test_that('selected duplicate marker columns cannot choose one intensity silently', {
  dt <- .threshold_fixture()$dt
  dt[, second := 0]
  data.table::setnames(dt, 'second', 'CD3')
  expect_error(phenotype_cells(dt, list(CD3 = .5)), 'unique names')
})
