# Small declared table transformations used between analysis stages.

#' Recode the Values of a Column by a Declared Map
#'
#' Replaces each value of a column by its entry in a declared map (for
#' example ordinal codes for reported categories), writing the result to a
#' new or the same column. Values absent from the map become `default`.
#'
#' @param data A data frame.
#' @param column Column to recode (compared as text).
#' @param map Named list or vector: original value (name) to new value.
#' @param to Output column (default: overwrite `column`).
#' @param default Value for unmapped entries (default `NA`).
#' @return `data` with the recoded column; numeric when all map values are
#'   numeric.
#' @examples
#' d <- data.frame(id = 1:4, grade = c("low", "<1", "high", "n.a."))
#' RecodeValues(d, "grade", list(low = 1, "<1" = 0.5, high = 3), to = "score")
#' @export
RecodeValues <- function(data, column, map, to = column, default = NA) {
  .an_assert(.an_name(column) && .an_name(to), "Invalid column names")
  .an_require(data, column)
  .an_assert(length(map) > 0L && !is.null(names(map)) && !anyDuplicated(names(map)),
             "map must be named with distinct original values")
  .an_assert(length(default) == 1L, "default must be one value")
  values <- unlist(map)
  .an_assert(length(values) == length(map), "map entries must be single values")
  data <- as.data.frame(data, stringsAsFactors = FALSE, optional = TRUE)
  key <- as.character(data[[column]])
  out <- unname(values[match(key, names(map))])
  out[is.na(match(key, names(map)))] <- default
  data[[to]] <- out
  data
}
