# Generic plot-data builders for patient-level figures: templates, quantile
# summaries, joins, ratios, pivots, filters and one-row summaries. They only
# reshape and summarise tables; tests come from upstream analysis tables.

#' Fill Text Templates from Table Rows
#'
#' Replaces placeholders of the form `{column}` or `{column|format}` with
#' values of `data`, so that figure text such as `"{k}/{n} patients; p =
#' {p|p}"` is written from plot data rather than typed by hand.
#'
#' Formats: `p` ([FormatP()]), `pfixed` (four decimals below 0.01, three
#' otherwise), `d` (rounded integer), `comma` (rounded integer with thousands
#' separators), `f0` to `f9` (fixed decimals), `sf0` to `sf9` (fixed decimals
#' with a leading `+` or true minus sign) and `s` (as text, the default).
#' Missing numeric values are written `"n.e."`.
#'
#' @param template Character vector of templates. A single template is applied
#'   to every row; several templates use one row each, or all the single row
#'   of a one-row table.
#' @param data A data frame (or a named list treated as one row), or `NULL`
#'   for templates without placeholders.
#' @return Character vector, one element per template or per row.
#' @examples
#' d <- data.frame(k = 11, n = 12, p = 0.00146)
#' FormatTemplate("{k|d}/{n|d} patients; p = {p|p}", d)
#' FormatTemplate("{x|sf1} ({share|f0}%)", data.frame(x = -3.42, share = 51.2))
#' @export
FormatTemplate <- function(template, data = NULL) {
  if (!is.character(template)) stop("template must be character.", call. = FALSE)
  if (is.null(data)) data <- data.frame(row.names = 1L)
  if (is.list(data) && !is.data.frame(data)) data <- as.data.frame(data, check.names = FALSE)
  if (!is.data.frame(data)) stop("data must be a data frame or NULL.", call. = FALSE)
  n <- if (length(template) == 1L) max(1L, nrow(data)) else length(template)
  if (length(template) > 1L && nrow(data) > 1L && nrow(data) < n) {
    stop("data has fewer rows than templates.", call. = FALSE)
  }
  if (length(template) > 1L && nrow(data) == 1L) data <- data[rep(1L, n), , drop = FALSE]
  template <- rep_len(template, n)
  out <- character(n)
  rx <- "\\{([^{}|]+)(\\|([A-Za-z0-9+]+))?\\}"
  for (i in seq_len(n)) {
    s <- template[i]
    hits <- regmatches(s, gregexpr(rx, s, perl = TRUE))[[1L]]
    for (h in unique(hits)) {
      parts <- regmatches(h, regexec(rx, h, perl = TRUE))[[1L]]
      column <- trimws(parts[2])
      if (!column %in% names(data)) stop("Template refers to missing column '", column, "'.", call. = FALSE)
      if (!nrow(data)) stop("Template needs at least one data row.", call. = FALSE)
      value <- data[[column]][[i]]
      s <- gsub(h, .figA_format_value(value, parts[4]), s, fixed = TRUE)
    }
    out[i] <- s
  }
  out
}

.figA_format_value <- function(value, format) {
  if (is.na(format) || !nzchar(format) || format == "s") return(if (is.na(value)) "n.e." else as.character(value))
  if (is.character(value) || is.factor(value)) {
    stop("Format '", format, "' needs a numeric value.", call. = FALSE)
  }
  value <- as.numeric(value)
  if (format == "p") return(FormatP(value))
  if (!is.finite(value)) return("n.e.")
  if (format == "pfixed") return(sprintf(if (value < 0.01) "%.4f" else "%.3f", value))
  if (format == "d") return(as.character(round(value)))
  if (format == "comma") return(formatC(round(value), format = "d", big.mark = ","))
  if (grepl("^f[0-9]$", format)) return(formatC(value, format = "f", digits = as.integer(substring(format, 2))))
  if (grepl("^sf[0-9]$", format)) {
    body <- formatC(abs(value), format = "f", digits = as.integer(substring(format, 3)))
    sign <- if (as.numeric(body) == 0) "" else if (value < 0) "\u2212" else "+"
    return(paste0(sign, body))
  }
  stop("Unknown template format '", format, "'.", call. = FALSE)
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
#' @export
PlotDataQuantiles <- function(data, by, value, probs = c(0.25, 0.5, 0.75),
                              names = c("lower", "median", "upper"), n_name = "n") {
  .fig_require_columns(data, c(by, value))
  if (length(probs) != length(names)) stop("probs and names must have the same length.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  key <- do.call(paste, c(lapply(by, function(b) as.character(data[[b]])), sep = "\r"))
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
#' b <- data.frame(id = c("p1", "p2"), group = c("A", "B"))
#' PlotDataJoin(a, b, by = "id", columns = "group")
#' @export
PlotDataJoin <- function(data, other, by, by_other = by, columns = NULL, rename = NULL) {
  .fig_require_columns(data, by)
  .fig_require_columns(other, c(by_other, columns), "other")
  if (length(by) != length(by_other)) stop("by and by_other must have the same length.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  other <- as.data.frame(other, check.names = FALSE)
  if (is.null(columns)) columns <- setdiff(names(other), by_other)
  if (is.null(rename)) rename <- columns
  if (length(rename) != length(columns)) stop("rename must match columns.", call. = FALSE)
  k1 <- do.call(paste, c(lapply(by, function(b) as.character(data[[b]])), sep = "\r"))
  k2 <- do.call(paste, c(lapply(by_other, function(b) as.character(other[[b]])), sep = "\r"))
  if (anyDuplicated(k2)) stop("Keys of other are not unique.", call. = FALSE)
  idx <- match(k1, k2)
  for (j in seq_along(columns)) data[[rename[[j]]]] <- other[[columns[[j]]]][idx]
  rownames(data) <- NULL
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
#' @export
PlotDataPairRatio <- function(data, id, key, numerator, denominator, values, names = values,
                              pseudocount = 0, log_base = NULL, names_to = "variable",
                              values_to = "ratio") {
  .fig_require_columns(data, c(id, key, values))
  if (length(names) != length(values)) stop("names must match values.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  k <- do.call(paste, c(lapply(id, function(b) as.character(data[[b]])), sep = "\r"))
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

#' Stack Columns Selected by a Name Pattern
#'
#' Long form of wide tables whose column names carry an identifier, for
#' example `log2|p1`, `log2|p2`: the first capture group of `pattern` becomes
#' the value of `names_to`.
#'
#' @param data A data frame.
#' @param id Identifier columns kept on every row.
#' @param pattern Regular expression with one capture group, matched against
#'   column names.
#' @param names_to,values_to Names of the new columns.
#' @param drop_na Drop rows whose value is missing.
#' @return A data frame.
#' @examples
#' d <- data.frame(type = c("a", "b"), `v|p1` = 1:2, `v|p2` = c(3, NA), check.names = FALSE)
#' PlotDataPivotLonger(d, "type", "^v\\|(.*)$", names_to = "patient")
#' @export
PlotDataPivotLonger <- function(data, id, pattern, names_to = "name", values_to = "value",
                                drop_na = TRUE) {
  .fig_require_columns(data, id)
  data <- as.data.frame(data, check.names = FALSE)
  cols <- grep(pattern, names(data), perl = TRUE, value = TRUE)
  cols <- setdiff(cols, id)
  if (!length(cols)) stop("No column matches pattern.", call. = FALSE)
  keys <- sub(pattern, "\\1", cols, perl = TRUE)
  out <- PlotDataLonger(data, id, cols, conditions = keys, names_to = names_to, values_to = values_to)
  if (drop_na) out <- out[!is.na(out[[values_to]]), , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' Keep Rows Meeting Conditions
#'
#' @param data A data frame.
#' @param where List of conditions, each a list with `column`, `op` and
#'   (except for `is_na`, `not_na`) `value`. Operators: `<`, `<=`, `>`, `>=`,
#'   `==`, `!=`, `in`, `not_in`, `is_na`, `not_na`, `matches`,
#'   `not_matches` (regular expression). Conditions are combined with AND;
#'   comparisons with missing values are false.
#' @return The kept rows.
#' @examples
#' d <- data.frame(id = c("a", "b", "c"), n = c(1, 12, NA))
#' PlotDataWhere(d, list(list(column = "n", op = ">=", value = 10)))
#' @export
PlotDataWhere <- function(data, where) {
  if (!is.data.frame(data)) stop("data must be a data frame.", call. = FALSE)
  if (!is.list(where)) stop("where must be a list of conditions.", call. = FALSE)
  if (length(where) && !is.null(where$column)) where <- list(where)
  data <- as.data.frame(data, check.names = FALSE)
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
  out <- data[keep, , drop = FALSE]
  rownames(out) <- NULL
  out
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
#' @export
PlotDataMembership <- function(data, reference, by, into = "member", negate = FALSE) {
  .fig_require_columns(data, by)
  .fig_require_columns(reference, by, "reference")
  data <- as.data.frame(data, check.names = FALSE)
  k1 <- do.call(paste, c(lapply(by, function(b) as.character(data[[b]])), sep = "\r"))
  k2 <- do.call(paste, c(lapply(by, function(b) as.character(reference[[b]])), sep = "\r"))
  hit <- k1 %in% k2
  data[[into]] <- if (negate) !hit else hit
  data
}

#' Summarise Columns
#'
#' One row per group (or one row in total) with a summary of each column.
#'
#' @param data A data frame.
#' @param columns Columns to summarise (ignored for `fun = "count"`).
#' @param fun One of `"sum"`, `"mean"`, `"median"`, `"min"`, `"max"`,
#'   `"count"` (rows) or `"n_distinct"`.
#' @param by Optional grouping columns.
#' @param into Names of the result columns; default `columns` (or `"n"`
#'   for counts).
#' @return A data frame.
#' @examples
#' d <- data.frame(g = c("a", "a", "b"), x = 1:3, y = c(2, 4, 6))
#' PlotDataSummarise(d, c("x", "y"), "sum")
#' PlotDataSummarise(d, fun = "count", by = "g")
#' @export
PlotDataSummarise <- function(data, columns = NULL, fun = "sum", by = NULL, into = NULL) {
  .fig_require_columns(data, c(columns, by))
  data <- as.data.frame(data, check.names = FALSE)
  f <- switch(fun,
    sum = function(v) sum(as.numeric(v), na.rm = TRUE), mean = function(v) mean(as.numeric(v), na.rm = TRUE),
    median = function(v) stats::median(as.numeric(v), na.rm = TRUE),
    min = function(v) min(as.numeric(v), na.rm = TRUE), max = function(v) max(as.numeric(v), na.rm = TRUE),
    count = length, n_distinct = function(v) length(unique(v[!is.na(v)])),
    stop("Unknown summary '", fun, "'.", call. = FALSE))
  if (fun == "count") columns <- if (is.null(columns)) names(data)[1L] else columns[1L]
  if (is.null(into)) into <- if (fun == "count") "n" else columns
  if (length(into) != length(columns)) stop("into must match columns.", call. = FALSE)
  key <- if (is.null(by)) rep("", nrow(data)) else do.call(paste, c(lapply(by, function(b) as.character(data[[b]])), sep = "\r"))
  keys <- unique(key)
  if (!length(keys)) keys <- ""
  rows <- lapply(keys, function(k) {
    sel <- key == k
    out <- if (is.null(by)) data.frame(row.names = 1L) else data[match(k, key), by, drop = FALSE]
    for (j in seq_along(columns)) out[[into[[j]]]] <- f(data[[columns[[j]]]][sel])
    out
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Collapse Rows into One Text Field
#'
#' Writes each row with [FormatTemplate()] and joins the results, for
#' example to list patients with their cell counts in a figure note.
#'
#' @param data A data frame.
#' @param template Template applied to every row.
#' @param sep Separator.
#' @param order_by Optional column to sort by (stable, increasing).
#' @param decreasing Sort decreasing.
#' @param into Name of the text column.
#' @param n_name Name of a column with the number of rows collapsed.
#' @return A one-row data frame.
#' @examples
#' d <- data.frame(id = c("p3", "p1"), n = c(4, 1))
#' PlotDataCollapse(d, "{id}, {n|d}", order_by = "n")
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

#' Bind Plot Data Tables
#'
#' `PlotDataBindRows()` stacks tables, filling columns missing from some
#' tables with `NA`; `PlotDataBindColumns()` places one-row (or equally long)
#' tables side by side.
#'
#' @param tables A list of data frames (named when `names_to` is used).
#' @param names_to Optional column recording the source table name.
#' @param rename Optional named list of renamings per table: table name to a
#'   named vector (new name = old name).
#' @return A data frame.
#' @examples
#' PlotDataBindRows(list(a = data.frame(x = 1), b = data.frame(x = 2, y = 3)), names_to = "src")
#' PlotDataBindColumns(list(data.frame(n = 9), data.frame(text = "p1, 1")))
#' @export
PlotDataBindRows <- function(tables, names_to = NULL, rename = NULL) {
  if (!is.list(tables) || !length(tables) || !all(vapply(tables, is.data.frame, logical(1)))) {
    stop("tables must be a list of data frames.", call. = FALSE)
  }
  if (!is.null(names_to) && is.null(names(tables))) stop("names_to needs a named list.", call. = FALSE)
  tables <- lapply(seq_along(tables), function(i) {
    t <- as.data.frame(tables[[i]], check.names = FALSE)
    r <- if (!is.null(rename) && !is.null(names(tables))) rename[[names(tables)[i]]] else NULL
    if (!is.null(r)) {
      r <- unlist(r)
      .fig_require_columns(t, r)
      names(t)[match(r, names(t))] <- names(r)
    }
    if (!is.null(names_to)) t[[names_to]] <- rep(names(tables)[i], nrow(t))
    t
  })
  cols <- unique(unlist(lapply(tables, names)))
  tables <- lapply(tables, function(t) {
    for (m in setdiff(cols, names(t))) t[[m]] <- rep(NA, nrow(t))
    t[cols]
  })
  out <- do.call(rbind, tables)
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

#' Recode Values of a Column
#'
#' Applies an exact value map and then regular-expression replacements, in
#' order, for example to turn analysis names into display labels.
#'
#' @param data A data frame.
#' @param column Column to recode.
#' @param map Optional named vector or list: old value to new value.
#' @param patterns Optional list of `c(pattern, replacement)` pairs (Perl
#'   regular expressions, applied in order).
#' @param into Name of the result column; default `column`.
#' @return `data` with the recoded column (character).
#' @examples
#' d <- data.frame(e = c("pct|B cells", "density|B cells"))
#' PlotDataRecode(d, "e", patterns = list(c("^pct\\|(.*)$", "\\1 (% of cells)"),
#'                                        c("^density\\|(.*)$", "\\1 (per mm2)")))
#' @export
PlotDataRecode <- function(data, column, map = NULL, patterns = NULL, into = column) {
  .fig_require_columns(data, column)
  data <- as.data.frame(data, check.names = FALSE)
  x <- as.character(data[[column]])
  if (!is.null(map)) {
    map <- unlist(map)
    hit <- x %in% names(map)
    x[hit] <- unname(map[x[hit]])
  }
  for (pr in patterns) {
    pr <- unlist(pr)
    if (length(pr) != 2L) stop("Each pattern must be c(pattern, replacement).", call. = FALSE)
    x <- gsub(pr[[1]], pr[[2]], x, perl = TRUE)
  }
  data[[into]] <- x
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
#' @export
PlotDataDirection <- function(data, n, up, estimate, into = "k") {
  .fig_require_columns(data, c(n, up, estimate))
  data <- as.data.frame(data, check.names = FALSE)
  e <- as.numeric(data[[estimate]])
  data[[into]] <- ifelse(e >= 0, as.numeric(data[[up]]), as.numeric(data[[n]]) - as.numeric(data[[up]]))
  data
}

#' Lower Bound of an Exact Two-Sided Permutation P Value
#'
#' For an exact permutation test of two groups of sizes `n_a` and `n_b`
#' (all allocations of the pooled values), the observed allocation always
#' reaches its own statistic; with equal group sizes its mirror allocation
#' reaches the same absolute difference. The smallest attainable two-sided
#' P is therefore at least `2 / choose(n_a + n_b, n_a)` for equal and
#' `1 / choose(n_a + n_b, n_a)` for unequal sizes.
#'
#' @param n_a,n_b Group sizes.
#' @return Numeric lower bound.
#' @examples
#' ExactPermutationBound(6, 6)
#' ExactPermutationBound(4, 2)
#' @export
ExactPermutationBound <- function(n_a, n_b) {
  if (!is.numeric(n_a) || !is.numeric(n_b) || any(n_a < 1 | n_b < 1)) {
    stop("Group sizes must be positive.", call. = FALSE)
  }
  ifelse(n_a == n_b, 2, 1) / choose(n_a + n_b, n_a)
}

#' Summary of a Family of Two-Group Tests
#'
#' One row describing a set of exact two-group tests: the number of tests
#' with a finite P value, of nominal (`p < alpha`) and of adjusted
#' (`q < alpha`) results, the group sizes and [ExactPermutationBound()].
#'
#' @param data Test table, one row per endpoint.
#' @param p,q P value and adjusted P value columns.
#' @param n_a,n_b Group-size columns (the most frequent sizes are used).
#' @param alpha Significance level.
#' @param label Optional column whose distinct values are counted as
#'   `endpoints`.
#' @return A one-row data frame with `tests`, `nominal`, `adjusted`, `n_a`,
#'   `n_b`, `p_bound` and `endpoints`.
#' @examples
#' t <- data.frame(p = c(0.01, 0.2, NA), q = c(0.1, 0.4, NA), n_a = 4, n_b = 2)
#' PlotDataContrastSummary(t)
#' @export
PlotDataContrastSummary <- function(data, p = "p", q = "q", n_a = "n_a", n_b = "n_b",
                                    alpha = 0.05, label = NULL) {
  .fig_require_columns(data, c(p, q, n_a, n_b, label))
  pv <- as.numeric(data[[p]])
  ok <- is.finite(pv)
  modal <- function(v) {
    v <- v[ok & !is.na(v)]
    if (!length(v)) return(NA_real_)
    t <- table(v)
    as.numeric(names(t)[which.max(t)])
  }
  na <- modal(data[[n_a]])
  nb <- modal(data[[n_b]])
  data.frame(tests = sum(ok), nominal = sum(pv[ok] < alpha),
             adjusted = sum(as.numeric(data[[q]])[ok] < alpha, na.rm = TRUE),
             n_a = na, n_b = nb,
             p_bound = if (is.finite(na) && is.finite(nb)) ExactPermutationBound(na, nb) else NA_real_,
             endpoints = if (is.null(label)) sum(ok) else length(unique(data[[label]])))
}

#' Text-Table Cells from a Per-Unit Table
#'
#' Transposes a table with one row per unit (patient) into the cells of a
#' small text table for [PlotTextBlock()]: a header row with the unit
#' labels and one row per value column, each with a row label in the first
#' column. Cells whose value lies below `highlight_below` are flagged.
#'
#' @param data A data frame, one row per unit, in display order.
#' @param id Column with the unit labels shown in the header.
#' @param values Value columns, one table row each.
#' @param row_labels Labels of the value rows.
#' @param header Label of the header row.
#' @param key Optional column copied to the header cells as `key` (for
#'   example a group used to colour header text).
#' @param highlight_below Values below this are flagged (`highlight = TRUE`).
#' @param zero_text Optional text written instead of zero values.
#' @return A data frame of cells with `row`, `column`, `label`, `header`,
#'   `highlight` and `key`.
#' @examples
#' d <- data.frame(id = c("1", "2"), a = c(3, 0), b = c(12, 40), g = c("x", "y"))
#' PlotDataTableCells(d, "id", c("a", "b"), c("First", "Second"), key = "g",
#'                    highlight_below = 10, zero_text = "0 (NE)")
#' @export
PlotDataTableCells <- function(data, id, values, row_labels = values, header = "", key = NULL,
                               highlight_below = NULL, zero_text = NULL) {
  .fig_require_columns(data, c(id, values, key))
  if (length(row_labels) != length(values)) stop("row_labels must match values.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  n <- nrow(data)
  cells <- list(data.frame(row = 1L, column = seq_len(n + 1L), label = c(header, as.character(data[[id]])),
                           header = TRUE, highlight = FALSE,
                           key = c(NA, if (is.null(key)) rep(NA, n) else as.character(data[[key]]))))
  for (j in seq_along(values)) {
    v <- as.numeric(data[[values[[j]]]])
    lab <- ifelse(is.na(v), "NE", formatC(v, format = "fg", big.mark = ""))
    lab <- ifelse(!is.na(v) & v == round(v), as.character(round(v)), lab)
    if (!is.null(zero_text)) lab[!is.na(v) & v == 0] <- zero_text
    hl <- if (is.null(highlight_below)) rep(FALSE, n) else (!is.na(v) & v < highlight_below)
    cells[[j + 1L]] <- data.frame(row = j + 1L, column = seq_len(n + 1L), label = c(row_labels[[j]], lab),
                                  header = FALSE, highlight = c(FALSE, hl), key = NA)
  }
  out <- do.call(rbind, cells)
  rownames(out) <- NULL
  out
}

#' Add a Constant Column
#'
#' @param data A data frame.
#' @param column Name of the new column.
#' @param value Value written on every row.
#' @return `data` with the column.
#' @examples
#' PlotDataConstant(data.frame(x = 1:2), "series", "a")
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
