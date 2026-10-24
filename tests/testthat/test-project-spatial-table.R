projection_table_fixture <- function() {
  d <- data.frame(id = c("b", "d", "a", "c"), value = c(0.1, NA, 0.6, 0.9),
                  weight = c(0.5, 1.5, 2.5, 3.5), stringsAsFactors = FALSE)
  d$weight <- structure(d$weight, class = "projection_weight", units = "count")
  d
}

projection_input_bytes <- function(x) serialize(x, NULL, version = 2)

test_that("projection preserves repeated row order and column metadata", {
  d <- projection_table_fixture()
  before <- projection_input_bytes(d)
  result <- ProjectSpatialTable(d, c(4L, 2L, 4L, 1L), c("weight", "id"))
  expect_identical(class(result), "data.frame")
  expect_identical(names(result), c("weight", "id"))
  expect_identical(dim(result), c(4L, 2L))
  expect_identical(rownames(result), as.character(1:4))
  expect_identical(result$id, c("c", "d", "c", "b"))
  expect_identical(result$weight,
                   structure(c(3.5, 1.5, 3.5, 0.5),
                             class = "projection_weight", units = "count"))
  expect_identical(projection_input_bytes(d), before)
})

test_that("zero rows retain typed classed columns and frame shape", {
  d <- projection_table_fixture()
  result <- ProjectSpatialTable(d, integer(), c("weight", "id", "value"))
  expect_identical(class(result), "data.frame")
  expect_identical(dim(result), c(0L, 3L))
  expect_identical(rownames(result), character())
  expect_identical(result$weight,
                   structure(numeric(), class = "projection_weight", units = "count"))
  expect_identical(result$id, character())
  expect_identical(result$value, numeric())
})

test_that("one column does not drop and zero-row inputs remain valid", {
  d <- projection_table_fixture()
  one <- ProjectSpatialTable(d, c(3L, 1L), "id")
  expect_identical(one, data.frame(id = c("a", "b")))
  collision <- data.frame(rows = c(FALSE, FALSE), columns = c("a", "b"))
  expect_identical(ProjectSpatialTable(collision, 2L, "columns"),
                   data.frame(columns = "b"))
  empty <- ProjectSpatialTable(d, integer(), c("weight", "id", "value"))
  expect_identical(ProjectSpatialTable(empty, integer(), names(empty)), empty)
})

test_that("data.table keys and input bytes survive projection", {
  d <- data.table::as.data.table(projection_table_fixture())
  data.table::setkeyv(d, "id")
  before <- projection_input_bytes(d)
  result <- ProjectSpatialTable(d, c(4L, 1L, 4L), c("id", "weight"))
  expect_identical(result$id, c("d", "a", "d"))
  expect_identical(result$weight,
                   structure(c(1.5, 2.5, 1.5),
                             class = "projection_weight", units = "count"))
  expect_identical(data.table::key(d), "id")
  expect_identical(projection_input_bytes(d), before)
})

test_that("returned columns are independent of the input", {
  d <- data.table::as.data.table(projection_table_fixture())
  before <- projection_input_bytes(d)
  result <- ProjectSpatialTable(d, seq_len(nrow(d)), names(d))
  changed <- data.table::as.data.table(result)
  data.table::set(changed, i = 1L, j = "id", value = "changed")
  data.table::setattr(changed$weight, "units", "changed")
  expect_identical(projection_input_bytes(d), before)
  expect_identical(d$id, c("b", "d", "a", "c"))
  expect_identical(attr(d$weight, "units"), "count")
})

test_that("projection retains standard classes and missing values exactly", {
  d <- projection_table_fixture()
  d$value <- c(NA_real_, NaN, Inf, -Inf)
  d$day <- as.Date(c("2026-01-01", NA, "2026-01-03", "2026-01-04"))
  d$group <- ordered(c("a", "b", NA, "a"), levels = c("a", "b", "unused"))
  result <- ProjectSpatialTable(d, c(2L, 4L, 1L, 3L),
                                 c("value", "day", "group", "weight"))
  expect_identical(result$value, c(NaN, -Inf, NA_real_, Inf))
  expect_identical(result$day,
                   as.Date(c(NA, "2026-01-04", "2026-01-01", "2026-01-03")))
  expect_identical(result$group,
                   ordered(c("b", "a", "a", NA), levels = c("a", "b", "unused")))
  expect_identical(attributes(result$weight), attributes(d$weight))
})

test_that("projection rejects non-table and unsupported frame subclasses", {
  d <- projection_table_fixture()
  invalid <- list(as.matrix(d), unclass(d), NULL,
                  structure(d, class = c("other_frame", "data.frame")))
  for (value in invalid) {
    expect_error(ProjectSpatialTable(value, 1L, "id"), "plain data.frame")
  }
})

test_that("projection rejects invalid row indices without coercion", {
  d <- projection_table_fixture()
  before <- projection_input_bytes(d)
  invalid <- list(1, 0L, -1L, 5L, NA_integer_, c(1L, NA_integer_), TRUE,
                  "1", NULL, list(1L), matrix(1L), factor("1"),
                  structure(1L, class = "row_index"), Inf, NaN)
  for (rows in invalid) {
    expect_error(ProjectSpatialTable(d, rows, "id"), "rows must")
  }
  expect_identical(projection_input_bytes(d), before)
})

test_that("projection rejects ambiguous or invalid requested columns", {
  d <- projection_table_fixture()
  before <- projection_input_bytes(d)
  invalid <- list(character(), NA_character_, c("id", NA_character_), "", "missing",
                  c("id", "id"), 1L, factor("id"), matrix("id"),
                  structure("id", class = "column_name"), NULL, list("id"))
  for (columns in invalid) {
    expect_error(ProjectSpatialTable(d, 1L, columns), "columns must")
  }
  expect_identical(projection_input_bytes(d), before)
})

test_that("projection refuses ambiguous input schemas", {
  d <- projection_table_fixture()
  for (bad in list(c("id", "id", "weight"), c("", "value", "weight"),
                   c(NA_character_, "value", "weight"))) {
    names(d) <- bad
    expect_error(ProjectSpatialTable(d, 1L, "weight"), "distinct nonempty")
  }
})
