# Generic plot-data builders. Every function takes a table (or a list of
# tables or arrays) and returns a data frame for the next builder or for a
# figure grammar. They select, reshape, join, recode, count and summarise;
# no test is computed here. All of them are named PlotData*() and use the
# same argument names: `data` for the table, `filter` for a named list of
# columns and the values to keep, `into` for the name of a new column and
# `names_to`/`values_to` for long tables.

# ---- shared internals -------------------------------------------------------------

# Rows whose columns take given values: `filter` is a named list of column
# to values. Logical values compare as logical, everything else as text.
.fig_filter_rows <- function(data, filter) {
  if (is.null(filter) || !length(filter)) return(rep(TRUE, nrow(data)))
  .fig_require_columns(data, names(filter))
  ok <- rep(TRUE, nrow(data))
  for (col in names(filter)) {
    v <- unlist(filter[[col]])
    ok <- ok & if (is.logical(v)) as.logical(data[[col]]) %in% v else as.character(data[[col]]) %in% as.character(v)
  }
  ok
}

# Rows meeting conditions: list of list(column, op, value).
.fig_where_rows <- function(data, where) {
  if (is.null(where) || !length(where)) return(rep(TRUE, nrow(data)))
  if (!is.list(where)) stop("where must be a list of conditions.", call. = FALSE)
  if (!is.null(where$column)) where <- list(where)
  keep <- rep(TRUE, nrow(data))
  for (w in where) {
    .fig_require_columns(data, w$column)
    x <- data[[w$column]]
    v <- unlist(w$value)
    hit <- switch(w$op,
      "<" = as.numeric(x) < v, "<=" = as.numeric(x) <= v, ">" = as.numeric(x) > v,
      ">=" = as.numeric(x) >= v, "==" = as.character(x) == as.character(v),
      "!=" = as.character(x) != as.character(v),
      "in" = as.character(x) %in% as.character(v), "not_in" = !as.character(x) %in% as.character(v),
      "is_na" = is.na(x), "not_na" = !is.na(x),
      "matches" = grepl(v, as.character(x), perl = TRUE),
      "not_matches" = !grepl(v, as.character(x), perl = TRUE),
      stop("Unknown operator '", w$op, "'.", call. = FALSE))
    keep <- keep & !is.na(hit) & hit
  }
  keep
}

# One text key per row from several columns.
.fig_row_key <- function(data, columns) {
  if (!length(columns)) return(rep("", nrow(data)))
  do.call(paste, c(lapply(columns, function(b) as.character(data[[b]])), sep = "\r"))
}

# Names for columns selected by a pattern: its first capture group, or the
# column name when the pattern has no group.
.fig_pattern_names <- function(pattern, columns) {
  if (is.null(pattern)) return(columns)
  m <- regmatches(columns, regexec(pattern, columns, perl = TRUE))
  vapply(seq_along(columns), function(i) if (length(m[[i]]) >= 2L) m[[i]][2L] else columns[i], character(1))
}

# ---- selecting and reshaping --------------------------------------------------------

#' Select Rows and Columns of Plot Data
#'
#' Keeps rows whose columns take given values (`filter`) and that meet
#' comparison conditions (`where`), optionally orders rows by a given order
#' of one column, and keeps or renames columns.
#'
#' @param data A data frame.
#' @param filter Named list: column name to the values to keep. Logical
#'   values are compared as logical, all others as text.
#' @param where Conditions, each a list with `column`, `op` and (except for
#'   `is_na`, `not_na`) `value`. Operators: `<`, `<=`, `>`, `>=`, `==`, `!=`,
#'   `in`, `not_in`, `is_na`, `not_na`, `matches`, `not_matches` (regular
#'   expression). Conditions are combined with AND; comparisons with missing
#'   values are false.
#' @param columns Columns to keep (all if `NULL`).
#' @param rename Named character vector or list, new name to old name.
#' @param order_by Optional column whose values follow `order`.
#' @param order Value order for `order_by`; rows with other values are
#'   dropped.
#' @return A data frame.
#' @examples
#' d <- data.frame(type = c("x", "y", "x"), v = 1:3, n = c(1, 12, NA))
#' PlotDataSelect(d, filter = list(type = "x"), rename = c(value = "v"))
#' PlotDataSelect(d, where = list(list(column = "n", op = ">=", value = 10)))
#' @family plot-data builders
#' @export
PlotDataSelect <- function(data, filter = list(), where = list(), columns = NULL, rename = NULL,
                           order_by = NULL, order = NULL) {
  if (!is.data.frame(data)) stop("data must be a data frame.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  .fig_require_columns(data, c(names(filter), columns, unlist(rename), order_by))
  keep <- .fig_filter_rows(data, filter) & .fig_where_rows(data, where)
  data <- data[keep, , drop = FALSE]
  if (!is.null(order_by)) {
    if (is.null(order)) stop("order is required with order_by.", call. = FALSE)
    pos <- match(as.character(data[[order_by]]), as.character(unlist(order)))
    data <- data[!is.na(pos), , drop = FALSE][order(pos[!is.na(pos)]), , drop = FALSE]
  }
  if (!is.null(columns)) data <- data[columns]
  if (!is.null(rename)) {
    rename <- unlist(rename)
    names(data)[match(rename, names(data))] <- names(rename)
  }
  rownames(data) <- NULL
  data
}

#' Reshape Wide Columns into Long Plot Data
#'
#' Stacks value columns of a summary table (one row per patient, say) into
#' one row per identifier and column, the form used by the plot builders.
#' The columns are given by name (`values`), by a regular expression
#' (`pattern`), or default to all columns other than `id` and `exclude`.
#'
#' With `pattern`, the first capture group of the pattern becomes the
#' condition name (`"^log2\\|(.*)$"` turns `log2|p1` into `p1`); a pattern
#' without a group keeps the column names.
#'
#' @param data A data frame.
#' @param id Identifier columns kept on every row.
#' @param values Value columns to stack, in condition order.
#' @param conditions Condition names for the stacked columns; default the
#'   column names (or the pattern groups).
#' @param pattern Regular expression selecting the value columns when
#'   `values` is `NULL`.
#' @param exclude Columns never stacked when `values` is `NULL`.
#' @param names_to,values_to Names of the new condition and value columns.
#' @param drop_na Drop rows whose value is missing.
#' @return A data frame with `id` columns, `names_to` (character, in column
#'   order) and `values_to` (numeric).
#' @examples
#' d <- data.frame(patient = c("p1", "p2"), a = 1:2, b = 3:4)
#' PlotDataLonger(d, "patient", c("a", "b"), conditions = c("A", "B"))
#' w <- data.frame(type = c("a", "b"), `v|p1` = 1:2, `v|p2` = c(3, NA), check.names = FALSE)
#' PlotDataLonger(w, "type", pattern = "^v\\|(.*)$", names_to = "patient", drop_na = TRUE)
#' @family plot-data builders
#' @export
PlotDataLonger <- function(data, id, values = NULL, conditions = NULL, pattern = NULL, exclude = NULL,
                           names_to = "condition", values_to = "value", drop_na = FALSE) {
  id <- as.character(unlist(id))
  values <- if (is.null(values)) NULL else as.character(unlist(values))
  .fig_require_columns(data, c(id, values))
  data <- as.data.frame(data, check.names = FALSE)
  if (is.null(values)) {
    cols <- setdiff(names(data), c(id, unlist(exclude)))
    if (!is.null(pattern)) cols <- grep(pattern, cols, value = TRUE, perl = TRUE)
    if (!length(cols)) stop("No value columns selected.", call. = FALSE)
    values <- cols
    if (is.null(conditions)) conditions <- .fig_pattern_names(pattern, cols)
  } else if (!is.null(pattern) || !is.null(exclude)) {
    stop("Give values, or pattern/exclude, not both.", call. = FALSE)
  }
  if (is.null(conditions)) conditions <- values
  if (length(conditions) != length(values)) stop("conditions must match values.", call. = FALSE)
  if (any(c(names_to, values_to) %in% id)) stop("New column names clash with id.", call. = FALSE)
  parts <- lapply(seq_along(values), function(j) {
    out <- data[id]
    out[[names_to]] <- conditions[[j]]
    out[[values_to]] <- as.numeric(data[[values[[j]]]])
    out
  })
  out <- do.call(rbind, parts)
  if (drop_na) out <- out[!is.na(out[[values_to]]), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Join Columns of Another Table
#'
#' Left join that keeps the rows and row order of `data` and adds selected
#' columns of `other`, matched on key columns. Keys of `other` must be
#' unique.
#'
#' @param data A data frame.
#' @param other A data frame.
#' @param by Key columns of `data`.
#' @param by_other Key columns of `other`; default `by`.
#' @param columns Columns of `other` to add; default all non-key columns.
#' @param rename Optional new names for `columns`.
#' @return `data` with the added columns (missing matches are `NA`).
#' @examples
#' a <- data.frame(id = c("p2", "p1", "p3"), v = 1:3)
#' b <- data.frame(key = c("p1", "p2"), group = c("A", "B"))
#' PlotDataJoin(a, b, by = "id", by_other = "key", columns = "group")
#' @family plot-data builders
#' @export
PlotDataJoin <- function(data, other, by, by_other = by, columns = NULL, rename = NULL) {
  by <- as.character(unlist(by))
  by_other <- as.character(unlist(by_other))
  columns <- if (is.null(columns)) NULL else as.character(unlist(columns))
  .fig_require_columns(data, by)
  .fig_require_columns(other, c(by_other, columns), "other")
  if (length(by) != length(by_other)) stop("by and by_other must have the same length.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  other <- as.data.frame(other, check.names = FALSE)
  if (is.null(columns)) columns <- setdiff(names(other), by_other)
  if (is.null(rename)) rename <- columns
  if (length(rename) != length(columns)) stop("rename must match columns.", call. = FALSE)
  k1 <- .fig_row_key(data, by)
  k2 <- .fig_row_key(other, by_other)
  if (anyDuplicated(k2)) stop("Keys of other are not unique.", call. = FALSE)
  idx <- match(k1, k2)
  for (j in seq_along(columns)) data[[rename[[j]]]] <- other[[columns[[j]]]][idx]
  rownames(data) <- NULL
  data
}

#' Bind Plot Data Tables
#'
#' `PlotDataBindRows()` stacks tables by column name, filling columns
#' missing from some tables with `NA`. It can record the source of each row
#' (`names_to`, after the table columns) and add constant key columns per
#' table (`keys`, before the table columns). `PlotDataBindColumns()` places
#' one-row (or equally long) tables side by side.
#'
#' @param tables A list of data frames (named when `names_to` without
#'   `labels`, `keys` or `rename` are used), or a single data frame.
#' @param names_to Optional column recording the source of each row: the
#'   list name, the matching entry of `labels`, or the list position.
#' @param labels Optional source labels, one per table.
#' @param keys Optional named list: table name to a named list of scalar
#'   values added as leading columns. For a single data frame, `keys` is the
#'   named list of values itself.
#' @param columns Optional columns kept from every table.
#' @param rename Optional named list of renamings per table: table name to a
#'   named vector (new name = old name).
#' @param element Optional element name when the list items are lists that
#'   hold the tables.
#' @return A data frame.
#' @examples
#' PlotDataBindRows(list(a = data.frame(x = 1), b = data.frame(x = 2, y = 3)), names_to = "src")
#' PlotDataBindRows(list(a = data.frame(v = 1), b = data.frame(v = 2:3)),
#'                  keys = list(a = list(batch = "one"), b = list(batch = "two")))
#' PlotDataBindColumns(list(data.frame(n = 9), data.frame(text = "p1, 1")))
#' @family plot-data builders
#' @export
PlotDataBindRows <- function(tables, names_to = NULL, labels = NULL, keys = NULL, columns = NULL,
                             rename = NULL, element = NULL) {
  if (is.data.frame(tables)) {
    tables <- list(table = tables)
    if (!is.null(keys)) keys <- list(table = keys)
  }
  if (!is.list(tables) || !length(tables)) stop("tables must be a non-empty list of data frames.", call. = FALSE)
  tn <- names(tables)
  src <- if (!is.null(labels)) as.character(unlist(labels)) else tn
  if (!is.null(labels) && length(src) != length(tables)) stop("labels must have one entry per table.", call. = FALSE)
  if ((!is.null(keys) || !is.null(rename)) && is.null(tn)) stop("keys and rename need a named list.", call. = FALSE)
  parts <- lapply(seq_along(tables), function(i) {
    t <- tables[[i]]
    if (!is.null(element)) {
      if (!is.list(t) || !element %in% names(t)) stop("Table ", i, " lacks element '", element, "'.", call. = FALSE)
      t <- t[[element]]
    }
    if (!is.data.frame(t)) stop("tables must be a list of data frames.", call. = FALSE)
    t <- as.data.frame(t, check.names = FALSE)
    if (!is.null(columns)) t <- t[, as.character(unlist(columns)), drop = FALSE]
    r <- if (!is.null(rename)) rename[[tn[i]]] else NULL
    if (!is.null(r)) {
      r <- unlist(r)
      .fig_require_columns(t, r)
      names(t)[match(r, names(t))] <- names(r)
    }
    if (!is.null(keys)) {
      kv <- keys[[tn[i]]]
      if (is.null(kv)) stop("No keys for table '", tn[i], "'.", call. = FALSE)
      if (any(names(kv) %in% names(t))) stop("Key columns collide with table columns.", call. = FALSE)
      lead <- lapply(kv, function(v) {
        if (length(v) != 1L) stop("Key values must be scalars.", call. = FALSE)
        rep(v, nrow(t))
      })
      t <- cbind(as.data.frame(lead, stringsAsFactors = FALSE, optional = TRUE), t)
    }
    if (!is.null(names_to)) t[[names_to]] <- rep(if (is.null(src)) i else src[[i]], nrow(t))
    t
  })
  cols <- unique(unlist(lapply(parts, names)))
  parts <- lapply(parts, function(t) {
    for (m in setdiff(cols, names(t))) t[[m]] <- rep(NA, nrow(t))
    t[cols]
  })
  out <- do.call(rbind, parts)
  rownames(out) <- NULL
  out
}

#' @rdname PlotDataBindRows
#' @export
PlotDataBindColumns <- function(tables) {
  if (!is.list(tables) || !length(tables) || !all(vapply(tables, is.data.frame, logical(1)))) {
    stop("tables must be a list of data frames.", call. = FALSE)
  }
  n <- vapply(tables, nrow, integer(1))
  if (length(unique(n)) != 1L) stop("Tables must have the same number of rows.", call. = FALSE)
  out <- do.call(cbind, unname(lapply(tables, as.data.frame, check.names = FALSE)))
  if (anyDuplicated(names(out))) stop("Column names clash.", call. = FALSE)
  rownames(out) <- NULL
  out
}

#' Table from a List of Arrays
#'
#' Turns a named list of equally long arrays, for example the arrays of a
#' NumPy `.npz` archive, into a data frame. Given a file path instead of a
#' list, only the arrays needed are read with `cellspecR::cs_read_npz()`
#' (pure R). One-dimensional arrays become columns, the columns of matrices
#' become further columns, arrays defined only for some rows (`masked`) are
#' expanded with `NA`, and rows can be restricted to a logical array.
#'
#' @param arrays Named list of vectors and matrices with one row per record,
#'   or the path of an `.npz` archive.
#' @param columns Names of one-dimensional arrays to keep; a named vector or
#'   list renames them (new name = array name). Default all vectors of the
#'   record length.
#' @param matrices Named list: for each matrix, either the new column names
#'   or `list(names_from = "<array>", prefix = "")` taking the names from a
#'   character array.
#' @param masked Named list: output column (as named in `columns`) to the
#'   name of the logical array marking the rows its values belong to.
#' @param keep Optional name of a logical array; only rows where it is
#'   `TRUE` are returned.
#' @param row_id Optional name of a column holding the position of each row
#'   in the arrays (before `keep`).
#' @param row_base Position of the first row (0 or 1).
#' @param row_first Put the `row_id` column first instead of last.
#' @return A data frame.
#' @examples
#' a <- list(xy = matrix(1:6, 3), label = c("a", "b", "a"), names = c("u", "v"),
#'           feat = matrix(c(0.1, 0.2, 0.3, 1, 2, 3), 3), kept = c(TRUE, FALSE, TRUE),
#'           cls = c(7L, 8L), has_cls = c(TRUE, FALSE, TRUE))
#' PlotDataFromArrays(a, columns = "label",
#'                    matrices = list(xy = c("x", "y"), feat = list(names_from = "names")))
#' PlotDataFromArrays(a, c(type = "label", cls = "cls"), masked = list(cls = "has_cls"),
#'                    keep = "kept", row_id = "row")
#' @family plot-data builders
#' @export
PlotDataFromArrays <- function(arrays, columns = NULL, matrices = NULL, masked = NULL, keep = NULL,
                               row_id = NULL, row_base = 0L, row_first = FALSE) {
  masked <- if (is.null(masked)) list() else as.list(masked)
  if (is.character(arrays) && length(arrays) == 1L) {
    if (!requireNamespace("cellspecR", quietly = TRUE)) stop("Reading an archive needs 'cellspecR'.", call. = FALSE)
    .require_cellspec_npz()
    if (!file.exists(arrays)) stop("Archive not found: ", arrays, call. = FALSE)
    need <- if (is.null(columns)) NULL else {
      from <- unlist(lapply(matrices, function(s) if (is.list(s)) s$names_from))
      unique(c(unname(as.character(unlist(columns))), unlist(masked), keep, names(matrices), from))
    }
    arrays <- if (is.null(need)) cellspecR::cs_read_npz(arrays) else cellspecR::cs_read_npz(arrays, arrays = need)
  }
  if (!is.list(arrays) || is.null(names(arrays))) stop("arrays must be a named list or an archive path.", call. = FALSE)
  rows <- function(a) if (is.matrix(a)) nrow(a) else length(a)
  if (is.null(columns)) {
    n0 <- max(vapply(arrays, rows, numeric(1)))
    columns <- names(arrays)[vapply(arrays, function(a) !is.matrix(a) && length(a) == n0, logical(1))]
  }
  columns <- unlist(columns)
  new <- if (is.null(names(columns))) unname(columns) else ifelse(nzchar(names(columns)), names(columns), columns)
  columns <- unname(as.character(columns))
  missing <- setdiff(c(columns, unlist(masked), keep, names(matrices)), names(arrays))
  if (length(missing)) stop("Unknown array(s): ", paste(missing, collapse = ", "), call. = FALSE)
  if (anyDuplicated(c(new, row_id))) stop("Duplicate output column names.", call. = FALSE)
  n <- if (!is.null(keep)) length(arrays[[keep]]) else NULL
  if (is.null(n)) {
    plain <- columns[!new %in% names(masked)]
    n <- if (length(plain)) rows(arrays[[plain[1L]]]) else if (length(masked)) length(arrays[[masked[[1L]]]]) else
      if (length(matrices)) rows(arrays[[names(matrices)[1L]]]) else 0L
  }
  out <- list()
  for (k in seq_along(columns)) {
    v <- arrays[[columns[k]]]
    if (!is.null(dim(v)) && length(dim(v)) > 1L) stop("Array '", columns[k], "' is not one-dimensional.", call. = FALSE)
    v <- as.vector(v)
    m <- masked[[new[k]]]
    if (!is.null(m)) {
      mask <- as.logical(arrays[[m]])
      if (length(mask) != n || sum(mask) != length(v)) stop("Masked column '", new[k], "' does not match its mask.", call. = FALSE)
      full <- rep(v[NA_integer_], n)
      full[mask] <- v
      v <- full
    }
    if (length(v) != n) stop("Array '", columns[k], "' has ", length(v), " values, expected ", n, ".", call. = FALSE)
    out[[new[k]]] <- v
  }
  for (k in names(matrices)) {
    m <- arrays[[k]]
    if (!is.matrix(m)) m <- matrix(m, ncol = 1L)
    if (nrow(m) != n) stop("Matrix '", k, "' has ", nrow(m), " rows, expected ", n, ".", call. = FALSE)
    spec <- matrices[[k]]
    nm <- if (is.list(spec) && !is.null(spec$names_from)) {
      paste0(if (is.null(spec$prefix)) "" else spec$prefix, as.character(arrays[[spec$names_from]]))
    } else as.character(unlist(spec))
    if (length(nm) != ncol(m)) stop("Names for '", k, "' must match its ", ncol(m), " columns.", call. = FALSE)
    for (j in seq_len(ncol(m))) out[[nm[j]]] <- as.vector(m[, j])
  }
  if (!is.null(row_id)) {
    pos <- list(seq_len(n) - 1L + as.integer(row_base))
    names(pos) <- row_id
    out <- if (isTRUE(row_first)) c(pos, out) else c(out, pos)
  }
  out <- as.data.frame(out, check.names = FALSE, stringsAsFactors = FALSE)
  if (!is.null(keep)) {
    k <- arrays[[keep]]
    if (!is.logical(k) || anyNA(k) || length(k) != n) stop("keep must be a logical array without NA.", call. = FALSE)
    out <- out[as.vector(k), , drop = FALSE]
  }
  rownames(out) <- NULL
  out
}

# ---- recoding and computed columns ----------------------------------------------------

#' Recode the Values of a Column
#'
#' Maps the values of a column to new values. Each value is looked up, in
#' this order, in an exact `map`, in a list of regular expressions
#' (`patterns`, the first match wins) and by position in `index` (integer
#' codes counted from `index_base`); an optional `extract` expression first
#' picks the part of each value that is looked up. Unmatched values are kept,
#' or replaced by `default`. Finally `substitute` applies regular-expression
#' replacements to every value, in order (for example to turn analysis names
#' into display labels).
#'
#' The result is numeric when every replacement value is numeric and
#' unmatched values are not kept (for example ordinal codes for reported
#' categories); otherwise it is text.
#'
#' @param data A data frame.
#' @param column Column to recode.
#' @param map Optional named vector or list: old value to new value.
#' @param patterns Optional named vector or list: regular expression to new
#'   value, tried in order for values not in `map`.
#' @param index Optional names for integer codes: a vector, or a data frame
#'   whose first column is used.
#' @param index_base Code of the first name of `index`.
#' @param extract Optional regular expression with one capture group; the
#'   group is looked up instead of the whole value.
#' @param default Value for unmatched entries; `NULL` keeps them.
#' @param keep_unmatched Keep unmatched values; with `FALSE` they become
#'   `default` (missing when `default` is `NULL`).
#' @param substitute Optional list of `c(pattern, replacement)` pairs (Perl
#'   regular expressions) applied to every value at the end, in order.
#' @param into Name of the result column; default `column`.
#' @return `data` with the recoded column.
#' @examples
#' d <- data.frame(e = c("pct|B cells", "density|B cells"), g = c("A-x", "B"), cn = c(0, 2))
#' PlotDataRecode(d, "e", substitute = list(c("^pct\\|(.*)$", "\\1 (% of cells)"),
#'                                          c("^density\\|(.*)$", "\\1 (per mm2)")))
#' PlotDataRecode(d, "g", patterns = c("^A" = "first"), default = "other", into = "label")
#' PlotDataRecode(d, "cn", index = c("zero", "one", "two"), into = "name")
#' PlotDataRecode(data.frame(tps = c("0", "<1", "8", "n.a.")), "tps",
#'                map = list("0" = 0, "<1" = 0.5, "8" = 8), keep_unmatched = FALSE, into = "score")
#' @family plot-data builders
#' @export
PlotDataRecode <- function(data, column, map = NULL, patterns = NULL, index = NULL, index_base = 0L,
                           extract = NULL, default = NULL, keep_unmatched = is.null(default),
                           substitute = NULL, into = column) {
  .fig_require_columns(data, column)
  data <- as.data.frame(data, check.names = FALSE)
  v <- data[[column]]
  key <- as.character(v)
  if (!is.null(extract)) key <- ifelse(grepl(extract, key, perl = TRUE), sub(extract, "\\1", key, perl = TRUE), key)
  map <- if (is.null(map)) NULL else unlist(map)
  patterns <- if (is.null(patterns)) NULL else unlist(patterns)
  if (length(default) > 1L) stop("default must be one value.", call. = FALSE)
  numeric_out <- !keep_unmatched && is.null(index) && is.null(substitute) &&
    all(vapply(list(map, patterns, default), function(x) is.null(x) || is.numeric(x) || all(is.na(x)), logical(1))) &&
    (is.numeric(map) || is.numeric(patterns) || is.numeric(default))
  out <- if (numeric_out) rep(c(unname(map), unname(patterns), default)[NA_integer_], length(v)) else
    rep(NA_character_, length(v))
  done <- rep(FALSE, length(v))
  if (!is.null(map)) {
    hit <- key %in% names(map)
    out[hit] <- unname(map[key[hit]])
    done <- hit
  }
  for (rx in names(patterns)) {
    hit <- !done & grepl(rx, key, perl = TRUE)
    out[hit] <- patterns[[rx]]
    done <- done | hit
  }
  if (!is.null(index)) {
    nm <- if (is.data.frame(index)) as.character(index[[1L]]) else as.character(unlist(index))
    code <- suppressWarnings(as.integer(as.numeric(key))) - as.integer(index_base) + 1L
    hit <- !done & !is.na(code) & code >= 1L & code <= length(nm)
    out[hit] <- nm[code[hit]]
    done <- done | hit
  }
  if (keep_unmatched) {
    out[!done] <- as.character(v)[!done]
  } else if (!is.null(default)) {
    out[!done] <- default
  }
  for (pr in substitute) {
    pr <- unlist(pr)
    if (length(pr) != 2L) stop("Each substitution must be c(pattern, replacement).", call. = FALSE)
    out <- gsub(pr[[1]], pr[[2]], out, perl = TRUE)
  }
  data[[into]] <- out
  data
}

#' Ratios Between Columns
#'
#' Adds `scale * (numerator + pseudocount) / (denominator + pseudocount)`,
#' optionally on a logarithmic scale. Zero numerators give `-Inf` on a log
#' scale; builders such as [PlotBandProfiles()] draw them at a floor.
#'
#' @param data A data frame.
#' @param numerator,denominator Numeric columns.
#' @param pseudocount Added to both columns.
#' @param log_base Optional logarithm base.
#' @param scale Multiplier applied before the logarithm.
#' @param into Name of the new column.
#' @return `data` with the ratio column.
#' @examples
#' PlotDataRatio(data.frame(a = c(1, 0, 4), b = 2), "a", "b", log_base = 2)
#' @family plot-data builders
#' @export
PlotDataRatio <- function(data, numerator, denominator, pseudocount = 0, log_base = NULL,
                          scale = 1, into = "ratio") {
  .fig_require_columns(data, c(numerator, denominator))
  data <- as.data.frame(data, check.names = FALSE)
  r <- scale * (as.numeric(data[[numerator]]) + pseudocount) /
    (as.numeric(data[[denominator]]) + pseudocount)
  if (!is.null(log_base)) r <- log(r, base = log_base)
  data[[into]] <- r
  data
}

#' Ratios Between Two Levels of a Key Column
#'
#' For tables with one row per identifier and level (for example per patient
#' and cell set), divides the values of one level by those of a reference
#' level of the same identifier, for one or several value columns, and
#' returns one row per identifier and value column.
#'
#' @param data A data frame.
#' @param id Identifier columns that pair rows.
#' @param key Column holding the levels.
#' @param numerator,denominator Levels of `key`.
#' @param values Value columns.
#' @param names Names for `values` in the output; default `values`.
#' @param pseudocount Added to both values.
#' @param log_base Optional logarithm base.
#' @param names_to,values_to Names of the output columns.
#' @return A data frame with `id`, `names_to`, `values_to` and the two input
#'   values (`numerator_value`, `denominator_value`). Identifiers lacking a
#'   level give `NA`.
#' @examples
#' d <- data.frame(id = rep(c("p1", "p2"), each = 2), set = c("x", "ref", "x", "ref"),
#'                 v = c(4, 2, 1, 2))
#' PlotDataPairRatio(d, "id", "set", "x", "ref", "v", log_base = 2)
#' @family plot-data builders
#' @export
PlotDataPairRatio <- function(data, id, key, numerator, denominator, values, names = values,
                              pseudocount = 0, log_base = NULL, names_to = "variable",
                              values_to = "ratio") {
  .fig_require_columns(data, c(id, key, values))
  if (length(names) != length(values)) stop("names must match values.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  k <- .fig_row_key(data, id)
  num <- data[as.character(data[[key]]) == numerator, , drop = FALSE]
  den <- data[as.character(data[[key]]) == denominator, , drop = FALSE]
  kn <- k[as.character(data[[key]]) == numerator]
  kd <- k[as.character(data[[key]]) == denominator]
  if (anyDuplicated(kn) || anyDuplicated(kd)) stop("Identifiers are not unique within a level.", call. = FALSE)
  ids <- unique(k)
  first <- data[match(ids, k), id, drop = FALSE]
  parts <- lapply(seq_along(values), function(j) {
    a <- as.numeric(num[[values[[j]]]][match(ids, kn)])
    b <- as.numeric(den[[values[[j]]]][match(ids, kd)])
    r <- (a + pseudocount) / (b + pseudocount)
    if (!is.null(log_base)) r <- log(r, base = log_base)
    out <- first
    out[[names_to]] <- names[[j]]
    out[[values_to]] <- r
    out$numerator_value <- a
    out$denominator_value <- b
    out
  })
  out <- do.call(rbind, parts)
  rownames(out) <- NULL
  out
}

#' Product of Columns
#'
#' Multiplies columns row by row, divides by a constant and optionally
#' rounds (half to even), for example a count from a total and a
#' percentage.
#'
#' @param data A data frame.
#' @param columns Columns to multiply, in order.
#' @param divide Divisor applied after the product.
#' @param round Round to whole numbers.
#' @param into Name of the new column.
#' @return `data` with the new column.
#' @examples
#' PlotDataProduct(data.frame(n = c(44, 2), pct = c(54.5454545, 50)), c("n", "pct"),
#'                 divide = 100, round = TRUE, into = "k")
#' @family plot-data builders
#' @export
PlotDataProduct <- function(data, columns, divide = 1, round = FALSE, into = "value") {
  columns <- as.character(unlist(columns))
  .fig_require_columns(data, columns)
  v <- as.numeric(data[[columns[1]]])
  for (cc in columns[-1]) v <- v * as.numeric(data[[cc]])
  v <- v / divide
  data[[into]] <- if (isTRUE(round)) round(v) else v
  data
}

#' Shares of a Total in Several Columns
#'
#' Divides selected count columns by a total column row by row, for example
#' excluded objects of several kinds as percentages of all objects.
#'
#' @param data A data frame.
#' @param columns Count columns.
#' @param total Column holding the total.
#' @param scale Multiplier (100 for percentages).
#' @param suffix Suffix of the new columns (empty replaces the columns).
#' @return `data` with the share columns.
#' @examples
#' PlotDataShares(data.frame(a = 1:2, b = 3:4, n = c(10, 20)), c("a", "b"), "n")
#' @family plot-data builders
#' @export
PlotDataShares <- function(data, columns, total, scale = 100, suffix = "") {
  .fig_require_columns(data, c(unlist(columns), total))
  for (cl in unlist(columns)) {
    data[[paste0(cl, suffix)]] <- scale * as.numeric(data[[cl]]) / as.numeric(data[[total]])
  }
  data
}

#' Scale a Column to a Reference Row
#'
#' Divides a column by its value in a reference row (the first row by
#' default, or the row where `at_column` equals `at`), for curves shown
#' relative to their first point.
#'
#' @param data A data frame.
#' @param column Column to scale.
#' @param at_column,at Optional reference row selector.
#' @param into Name of the result column; default `column`.
#' @return `data` with the scaled column.
#' @examples
#' PlotDataRelative(data.frame(k = 4:6, inertia = c(50, 40, 30)), "inertia", into = "relative")
#' @family plot-data builders
#' @export
PlotDataRelative <- function(data, column, at_column = NULL, at = NULL, into = column) {
  .fig_require_columns(data, c(column, at_column))
  ref <- if (is.null(at_column)) data[[column]][1L] else data[[column]][which(data[[at_column]] == at)[1L]]
  data[[into]] <- as.numeric(data[[column]]) / as.numeric(ref)
  data
}

#' Count of Units in the Direction of an Estimate
#'
#' Adds `k`, the number of units (patients) whose difference has the sign
#' of the summary estimate: `up` when the estimate is positive or zero and
#' `n - up` otherwise, as reported in "k/n patients".
#'
#' @param data A data frame.
#' @param n Column with the number of units.
#' @param up Column with the number of positive differences.
#' @param estimate Column with the summary estimate.
#' @param into Name of the new column.
#' @return `data` with the count column.
#' @examples
#' PlotDataDirection(data.frame(n = c(9, 9), up = c(9, 1), est = c(1.1, -0.4)), "n", "up", "est")
#' @family plot-data builders
#' @export
PlotDataDirection <- function(data, n, up, estimate, into = "k") {
  .fig_require_columns(data, c(n, up, estimate))
  data <- as.data.frame(data, check.names = FALSE)
  e <- as.numeric(data[[estimate]])
  data[[into]] <- ifelse(e >= 0, as.numeric(data[[up]]), as.numeric(data[[n]]) - as.numeric(data[[up]]))
  data
}

#' Flag Rows Whose Key Occurs in Another Table
#'
#' @param data A data frame.
#' @param reference A data frame.
#' @param by Key columns (same names in both tables).
#' @param into Name of the new logical column.
#' @param negate If `TRUE`, flag rows whose key does not occur.
#' @return `data` with the logical column.
#' @examples
#' PlotDataMembership(data.frame(id = c("a", "b")), data.frame(id = "a"), "id",
#'                    into = "excluded", negate = TRUE)
#' @family plot-data builders
#' @export
PlotDataMembership <- function(data, reference, by, into = "member", negate = FALSE) {
  .fig_require_columns(data, by)
  .fig_require_columns(reference, by, "reference")
  data <- as.data.frame(data, check.names = FALSE)
  hit <- .fig_row_key(data, by) %in% .fig_row_key(reference, by)
  data[[into]] <- if (negate) !hit else hit
  data
}

#' Add a Constant Column
#'
#' @param data A data frame.
#' @param column Name of the new column.
#' @param value Value written on every row.
#' @return `data` with the column.
#' @examples
#' PlotDataConstant(data.frame(x = 1:2), "series", "a")
#' @family plot-data builders
#' @export
PlotDataConstant <- function(data, column, value) {
  if (!is.data.frame(data)) stop("data must be a data frame.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  data[[column]] <- rep(unlist(value), length.out = nrow(data))
  data
}

#' Paste Columns into a Key Column
#'
#' @param data A data frame.
#' @param columns Columns to paste, in order.
#' @param into Name of the new column.
#' @param sep Separator.
#' @return `data` with the key column. Whole numbers are written without
#'   decimals.
#' @examples
#' PlotDataUnite(data.frame(type = "a", r = 20), c("type", "r"), "row")
#' @family plot-data builders
#' @export
PlotDataUnite <- function(data, columns, into, sep = " ") {
  .fig_require_columns(data, columns)
  data <- as.data.frame(data, check.names = FALSE)
  parts <- lapply(columns, function(cl) {
    v <- data[[cl]]
    if (is.numeric(v)) ifelse(!is.na(v) & v == round(v), format(round(v), trim = TRUE, scientific = FALSE),
                              as.character(v)) else as.character(v)
  })
  data[[into]] <- do.call(paste, c(parts, sep = sep))
  data
}

# ---- summaries, counts and ranks ---------------------------------------------------------

.fig_summary_fun <- function(fun, na_rm) {
  switch(fun,
    sum = function(v) sum(as.numeric(v), na.rm = na_rm),
    mean = function(v) mean(as.numeric(v), na.rm = na_rm),
    median = function(v) stats::median(as.numeric(v), na.rm = na_rm),
    min = function(v) min(as.numeric(v), na.rm = na_rm),
    max = function(v) max(as.numeric(v), na.rm = na_rm),
    count = length,
    n_distinct = function(v) length(unique(v[!is.na(v)])),
    stop("Unknown summary '", fun, "'.", call. = FALSE))
}

#' Summarise Columns by Group
#'
#' One summary per group (or one in total) of each selected column, in wide
#' form (one column per summarised column) or long form (one row per group
#' and column).
#'
#' @param data A data frame.
#' @param columns Columns to summarise (for `fun = "count"` only the first
#'   is used, default the first column of `data`).
#' @param fun One of `"sum"`, `"mean"`, `"median"`, `"min"`, `"max"`,
#'   `"count"` (rows) or `"n_distinct"`.
#' @param by Optional grouping columns.
#' @param into Names of the result columns in wide form; default `columns`
#'   (or `"n"` for counts).
#' @param filter Optional named list of columns and values selecting rows
#'   first.
#' @param long Return long form with `names_to` (column name) and
#'   `values_to` (summary).
#' @param names_to,values_to Names of the long-form columns.
#' @param sort Order groups by their values; by default groups keep the
#'   order of first appearance.
#' @param na_rm Ignore missing values.
#' @return A data frame.
#' @examples
#' d <- data.frame(g = c("b", "b", "a"), x = 1:3, y = c(2, 4, 6))
#' PlotDataSummarise(d, c("x", "y"), "sum")
#' PlotDataSummarise(d, fun = "count", by = "g")
#' PlotDataSummarise(d, c("x", "y"), "mean", by = "g", long = TRUE, sort = TRUE)
#' @family plot-data builders
#' @export
PlotDataSummarise <- function(data, columns = NULL, fun = "sum", by = NULL, into = NULL, filter = NULL,
                              long = FALSE, names_to = "name", values_to = "value", sort = FALSE,
                              na_rm = TRUE) {
  by <- if (is.null(by)) NULL else as.character(unlist(by))
  columns <- if (is.null(columns)) NULL else as.character(unlist(columns))
  .fig_require_columns(data, c(columns, by))
  data <- as.data.frame(data, check.names = FALSE)
  data <- data[.fig_filter_rows(data, filter), , drop = FALSE]
  f <- .fig_summary_fun(fun, na_rm)
  if (fun == "count") columns <- if (is.null(columns)) names(data)[1L] else columns[1L]
  if (!length(columns)) stop("columns are required.", call. = FALSE)
  key <- if (is.null(by)) rep("all", nrow(data)) else .fig_row_key(data, by)
  keys <- if (is.null(by)) "all" else if (sort) unique(key[do.call(order, unname(as.list(data[by])))]) else unique(key)
  first <- if (is.null(by)) data.frame(row.names = 1L) else data[match(keys, key), by, drop = FALSE]
  if (long) {
    out <- do.call(rbind, lapply(columns, function(cc) {
      v <- data[[cc]]
      r <- first
      r[[names_to]] <- rep(cc, length(keys))
      r[[values_to]] <- vapply(keys, function(k) f(v[key == k]), numeric(1))
      r
    }))
  } else {
    if (is.null(into)) into <- if (fun == "count") "n" else columns
    into <- as.character(unlist(into))
    if (length(into) != length(columns)) stop("into must match columns.", call. = FALSE)
    out <- do.call(rbind, lapply(seq_along(keys), function(i) {
      sel <- key == keys[i]
      r <- first[i, , drop = FALSE]
      for (j in seq_along(columns)) r[[into[[j]]]] <- f(data[[columns[[j]]]][sel])
      r
    }))
    if (!length(keys)) {
      # No rows selected: no groups.
      out <- first
      for (nm in into) out[[nm]] <- if (fun %in% c("count", "n_distinct")) integer() else numeric()
    }
  }
  rownames(out) <- NULL
  out
}

#' Counts and Shares by Group
#'
#' Counts rows per group (or overall), optionally the number of distinct
#' values of a column and the rows per distinct value, the share of all
#' counted rows, and counts of selected values of further columns.
#'
#' @param data A data frame.
#' @param by Grouping columns (none for one overall row).
#' @param filter Optional named list of columns and values selecting rows.
#' @param distinct Optional column whose distinct values are counted.
#' @param tally Optional named list of extra counts: each a list of
#'   `column` and `values`.
#' @param scale Multiplier of the share (100 for percentages).
#' @return A data frame with the groups, `n`, `share`, and if requested
#'   `n_distinct`, `n_per_distinct` (integer division) and the tallies.
#' @examples
#' d <- data.frame(g = c("a", "a", "b"), p = c("x", "y", "x"), t = c("T", "U", "T"))
#' PlotDataCount(d, "g", distinct = "p", tally = list(n_t = list(column = "t", values = "T")))
#' @family plot-data builders
#' @export
PlotDataCount <- function(data, by = NULL, filter = NULL, distinct = NULL, tally = NULL, scale = 100) {
  by <- as.character(unlist(by))
  .fig_require_columns(data, c(by, distinct))
  # data.table subsetting differs; other data frames (tibbles) keep their class.
  if (data.table::is.data.table(data)) data <- as.data.frame(data, check.names = FALSE)
  d <- data[.fig_filter_rows(data, filter), , drop = FALSE]
  key <- if (length(by)) do.call(paste, c(d[by], sep = "\r")) else rep("all", nrow(d))
  lev <- if (length(by)) unique(key) else "all"
  out <- if (length(by)) d[match(lev, key), by, drop = FALSE] else data.frame(row.names = 1)
  out$n <- as.integer(vapply(lev, function(k) sum(key == k), numeric(1)))
  out$share <- if (nrow(d)) scale * out$n / nrow(d) else rep(NA_real_, nrow(out))
  if (!is.null(distinct)) {
    out$n_distinct <- vapply(lev, function(k) length(unique(d[[distinct]][key == k])), integer(1))
    out$n_per_distinct <- out$n %/% out$n_distinct
  }
  for (nm in names(tally)) {
    t <- tally[[nm]]
    .fig_require_columns(d, t$column)
    hit <- as.character(d[[t$column]]) %in% as.character(unlist(t$values))
    out[[nm]] <- as.integer(vapply(lev, function(k) sum(hit[key == k]), numeric(1)))
  }
  rownames(out) <- NULL
  out
}

#' Shares of One Category within Another
#'
#' Cross-tabulates two columns and returns every combination with its count,
#' the total of its row category and the share of the row total (for
#' example the cell-type composition of each cluster).
#'
#' @param data A data frame.
#' @param row,column Column names.
#' @param filter Optional named list of columns and values selecting rows.
#' @param rows,columns Optional level sets (and order); default the sorted
#'   values present.
#' @param scale Multiplier of the share (100 for percentages).
#' @return A data frame with `row`, `column` (named as the inputs), `n`,
#'   `total` and `share`.
#' @examples
#' d <- data.frame(cl = c(1, 1, 2, 2, 2), type = c("a", "b", "a", "a", "c"))
#' PlotDataCrossShares(d, "cl", "type")
#' @family plot-data builders
#' @export
PlotDataCrossShares <- function(data, row, column, filter = NULL, rows = NULL, columns = NULL, scale = 100) {
  .fig_require_columns(data, c(row, column))
  ok <- .fig_filter_rows(data, filter)
  r <- as.character(data[[row]][ok])
  cc <- as.character(data[[column]][ok])
  srt <- function(v) {
    u <- unique(v)
    num <- suppressWarnings(as.numeric(u))
    if (!anyNA(num)) u[order(num)] else sort(u)
  }
  rows <- if (is.null(rows)) srt(r) else .figb_levels(rows, r)
  columns <- if (is.null(columns)) srt(cc) else .figb_levels(columns, cc)
  tab <- table(factor(r, levels = rows), factor(cc, levels = columns))
  out <- data.frame(a = rep(rows, times = length(columns)), b = rep(columns, each = length(rows)),
                    n = as.vector(tab), stringsAsFactors = FALSE)
  tot <- rowSums(tab)
  out$total <- unname(tot[match(out$a, rows)])  # by position: "" is not a usable name
  out$share <- ifelse(out$total > 0, scale * out$n / out$total, NA_real_)
  names(out)[1:2] <- c(row, column)
  out <- out[order(match(out[[row]], rows), match(out[[column]], columns)), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Quantile Summaries of Plot Data
#'
#' Summarises a value column by groups (for example a distance curve across
#' patients) into lower, middle and upper quantiles and the number of
#' non-missing values. Quantiles use R's default (type 7) interpolation,
#' which equals the linear rule of common numerical libraries.
#'
#' @param data A data frame.
#' @param by Grouping columns; groups keep their order of first appearance.
#' @param value Value column.
#' @param probs Three probabilities.
#' @param names Names of the three quantile columns.
#' @param n_name Name of the count column.
#' @return A data frame with the `by` columns, the quantile columns and the
#'   count column.
#' @examples
#' d <- data.frame(type = rep(c("a", "b"), each = 6), x = rep(1:2, 6), v = 1:12)
#' PlotDataQuantiles(d, by = c("type", "x"), value = "v")
#' @family plot-data builders
#' @export
PlotDataQuantiles <- function(data, by, value, probs = c(0.25, 0.5, 0.75),
                              names = c("lower", "median", "upper"), n_name = "n") {
  .fig_require_columns(data, c(by, value))
  if (length(probs) != length(names)) stop("probs and names must have the same length.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  key <- .fig_row_key(data, by)
  keys <- unique(key)
  rows <- lapply(keys, function(k) {
    v <- as.numeric(data[[value]][key == k])
    v <- v[!is.na(v)]
    q <- if (length(v)) stats::quantile(v, probs, names = FALSE, type = 7) else rep(NA_real_, length(probs))
    out <- data[match(k, key), by, drop = FALSE]
    out[names] <- as.list(q)
    out[[n_name]] <- length(v)
    out
  })
  out <- do.call(rbind, rows)
  if (!length(keys)) {
    # No rows: the typed columns without groups.
    out <- data[0L, by, drop = FALSE]
    out[names] <- rep(list(numeric()), length(names))
    out[[n_name]] <- integer()
  }
  rownames(out) <- NULL
  out
}

#' Rank Rows by the Sum of Selected Columns
#'
#' Sums the columns named in `columns` or matching `pattern` in each row and
#' ranks the rows (rank 1 = largest sum by default; ties keep the row order).
#'
#' @param data Wide data frame with one row per item.
#' @param id Identifier column.
#' @param columns Columns to add up.
#' @param pattern Regular expression selecting further columns.
#' @param decreasing Rank the largest sum first.
#' @param ids Optional identifiers to keep (a vector, or a data frame whose
#'   first column holds them); other rows are dropped.
#' @return A data frame with `id`, `value` and `rank`, sorted by rank.
#' @examples
#' d <- data.frame(p = c("a", "b", "c"), "CN1 T" = c(10, 40, 20), check.names = FALSE)
#' PlotDataRankRows(d, "p", pattern = "^CN1 ")
#' @family plot-data builders
#' @export
PlotDataRankRows <- function(data, id, columns = NULL, pattern = NULL, decreasing = TRUE, ids = NULL) {
  .fig_require_columns(data, c(id, unlist(columns)))
  data <- as.data.frame(data, check.names = FALSE)
  cols <- unique(c(unlist(columns), if (!is.null(pattern)) grep(pattern, names(data), value = TRUE, perl = TRUE)))
  if (!length(cols)) stop("No columns selected.", call. = FALSE)
  if (!is.null(ids)) data <- data[as.character(data[[id]]) %in% .figb_levels(ids, NULL), , drop = FALSE]
  v <- rowSums(as.matrix(data[, cols, drop = FALSE]))
  o <- order(if (decreasing) -v else v)
  out <- data.frame(id = as.character(data[[id]])[o], value = unname(v[o]), rank = seq_along(o),
                    stringsAsFactors = FALSE)
  names(out)[1] <- id
  out
}

#' Order Groups by Their Dominant Category
#'
#' For each row group of a share table (from [PlotDataCrossShares()]), finds
#' the category with the largest share (ties go to the earlier category in
#' `columns`) and orders the groups by the position of that category in
#' `priority`, then by the group value. Categories missing from `priority`
#' take position zero, before all listed ones. A group without any share
#' among `columns` has a missing `dominant` category and also takes position
#' zero.
#'
#' @param data Long share table.
#' @param row,column,value Column names.
#' @param columns Category order used to break ties.
#' @param priority Category order defining the group order.
#' @return A data frame with the group, `dominant`, `dominant_share` and
#'   `rank`, sorted by rank.
#' @examples
#' s <- PlotDataCrossShares(data.frame(cl = c(1, 1, 2, 3), type = c("b", "b", "a", "b")), "cl", "type")
#' PlotDataDominant(s, "cl", "type", "share", columns = c("a", "b"), priority = c("a", "b"))
#' @family plot-data builders
#' @export
PlotDataDominant <- function(data, row, column, value = "share", columns = NULL, priority = NULL) {
  .fig_require_columns(data, c(row, column, value))
  columns <- .figb_levels(columns, data[[column]])
  priority <- if (is.null(priority)) columns else as.character(unlist(priority))
  groups <- unique(as.character(data[[row]]))
  dom <- vapply(groups, function(g) {
    s <- data[as.character(data[[row]]) == g, , drop = FALSE]
    s <- s[order(match(as.character(s[[column]]), columns)), , drop = FALSE]
    s <- s[as.character(s[[column]]) %in% columns, , drop = FALSE]
    top <- which.max(as.numeric(s[[value]]))
    # A group without any share has no dominant category.
    if (length(top)) as.character(s[[column]][top]) else NA_character_
  }, character(1))
  dshare <- vapply(seq_along(groups), function(i) {
    s <- data[as.character(data[[row]]) == groups[i] & as.character(data[[column]]) == dom[i], value]
    as.numeric(s[1])
  }, numeric(1))
  pos <- match(dom, priority)
  pos[is.na(pos)] <- 0L
  gnum <- suppressWarnings(as.numeric(groups))
  o <- if (!anyNA(gnum)) order(pos, gnum) else order(pos, groups)
  out <- data.frame(g = groups[o], dominant = unname(dom[o]), dominant_share = dshare[o], rank = seq_along(o),
                    stringsAsFactors = FALSE)
  names(out)[1] <- row
  out
}

#' Key Colours from a Categorical Palette
#'
#' Assigns colours to integer keys (for example cluster numbers) by cycling
#' through one or more categorical palettes: key `k` takes colour
#' `((k - first) mod n) + 1` of the joined palettes.
#'
#' @param keys Keys: a vector, or a data frame whose `column` holds them.
#' @param column Key column when `keys` is a data frame.
#' @param palettes Palette names: `"tab20"`, `"tab20b"`, `"tab20c"` or
#'   `"clusters"` (the style's cluster palette), joined in order.
#' @param first Key that takes the first colour.
#' @return A data frame with `key` and `colour`, sorted by key.
#' @examples
#' PlotDataKeyColours(1:25)
#' @family plot-data builders
#' @export
PlotDataKeyColours <- function(keys, column = "key", palettes = c("tab20", "tab20b"), first = 1) {
  k <- if (is.data.frame(keys)) keys[[column]] else unlist(keys)
  k <- sort(unique(as.numeric(k[!is.na(k)])))
  pal <- unlist(lapply(unlist(palettes), .figb_categorical))
  data.frame(key = as.character(k), colour = pal[((k - first) %% length(pal)) + 1L], stringsAsFactors = FALSE)
}

.figb_categorical <- function(name) {
  switch(name,
    tab20 = ManuscriptPalettes()$clusters,
    clusters = ManuscriptPalettes()$clusters,
    tab20b = c("#393b79", "#5254a3", "#6b6ecf", "#9c9ede", "#637939", "#8ca252", "#b5cf6b", "#cedb9c",
               "#8c6d31", "#bd9e39", "#e7ba52", "#e7cb94", "#843c39", "#ad494a", "#d6616b", "#e7969c",
               "#7b4173", "#a55194", "#ce6dbd", "#de9ed6"),
    tab20c = c("#3182bd", "#6baed6", "#9ecae1", "#c6dbef", "#e6550d", "#fd8d3c", "#fdae6b", "#fdd0a2",
               "#31a354", "#74c476", "#a1d99b", "#c7e9c0", "#756bb1", "#9e9ac8", "#bcbddc", "#dadaeb",
               "#636363", "#969696", "#bdbdbd", "#d9d9d9"),
    stop("Unknown categorical palette '", name, "'.", call. = FALSE)
  )
}

# ---- text from rows ---------------------------------------------------------------------

#' Text Labels from Table Rows
#'
#' `PlotDataLabels()` writes one text per row with [FormatTemplate()] (for
#' example titles such as `"{cells:%.0f}k cells; {area:%.0f} mm2"`), after
#' optional per-column scaling. `PlotDataCollapse()` writes every row and
#' joins the results into one text, for example to list patients with their
#' cell counts in a figure note.
#'
#' @param data A data frame.
#' @param template Template (see [FormatTemplate()]).
#' @param id Optional columns of `data` kept in the output of
#'   `PlotDataLabels()`.
#' @param scales Named list: column to a multiplier applied before
#'   formatting.
#' @param into Name of the text column.
#' @param sep Separator of the collapsed rows.
#' @param order_by Optional column to sort by before collapsing (stable,
#'   increasing).
#' @param decreasing Sort decreasing.
#' @param n_name Name of a column with the number of rows collapsed.
#' @return `PlotDataLabels()`: a data frame with the `id` columns and
#'   `into`; `PlotDataCollapse()`: a one-row data frame.
#' @examples
#' d <- data.frame(p = c("p3", "p1"), n = c(27081, 1450), g = c("A", "B"))
#' PlotDataLabels(d, "{n:%.0f}k cells, {g}", id = "p", scales = list(n = 0.001))
#' PlotDataCollapse(d, "{p}, {n|comma}", order_by = "n")
#' @family plot-data builders
#' @export
PlotDataLabels <- function(data, template, id = NULL, scales = NULL, into = "text") {
  if (!is.data.frame(data)) stop("data must be a data frame.", call. = FALSE)
  .fig_require_columns(data, c(id, names(scales)))
  d <- as.data.frame(data, check.names = FALSE)
  for (cl in names(scales)) d[[cl]] <- as.numeric(d[[cl]]) * scales[[cl]]
  res <- if (is.null(id)) data.frame(row.names = seq_len(nrow(d))) else d[id]
  res[[into]] <- if (nrow(d)) FormatTemplate(rep_len(template, nrow(d)), d) else character()
  rownames(res) <- NULL
  res
}

#' @rdname PlotDataLabels
#' @export
PlotDataCollapse <- function(data, template, sep = "; ", order_by = NULL, decreasing = FALSE,
                             into = "text", n_name = "rows") {
  if (!is.data.frame(data)) stop("data must be a data frame.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  if (!is.null(order_by)) {
    .fig_require_columns(data, order_by)
    data <- data[order(data[[order_by]], decreasing = decreasing, method = "radix"), , drop = FALSE]
  }
  text <- if (nrow(data)) paste(FormatTemplate(template, data), collapse = sep) else ""
  out <- data.frame(text = text, n = nrow(data))
  names(out) <- c(into, n_name)
  out
}
