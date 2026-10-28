# Keyed comparisons of recomputed tables and arrays with references.

.an_mapping <- function(x, what) {
  x <- unlist(x)
  .an_assert(is.character(x) && length(x) > 0L && !anyNA(x), paste("Invalid", what))
  if (is.null(names(x))) names(x) <- x
  names(x)[!nzchar(names(x))] <- x[!nzchar(names(x))]
  .an_assert(!anyDuplicated(names(x)), paste("Duplicate", what))
  x
}

.an_element <- function(x, element, what) {
  if (is.null(element)) return(x)
  .an_assert(is.list(x) && element %in% names(x), paste(what, "lacks element", element))
  x[[element]]
}

.an_text <- function(v) {
  if (is.numeric(v)) {
    out <- sprintf("%.17g", v)
    out[is.na(v)] <- NA_character_
    return(out)
  }
  as.character(v)
}

#' Compare a Recomputed Table with a Reference Table by Key
#'
#' Joins two tables on declared key columns (which must be unique in both)
#' and compares declared value columns: numbers within an absolute
#' tolerance, everything else (text, logical) exactly. Missing values match
#' only missing values. Keys present in one table only are reported.
#'
#' @param observed,reference Data frames (or lists holding one, see
#'   `observed_element`, `reference_element`).
#' @param keys Key columns: a character vector of names shared by both tables,
#'   or a named vector/list `observed name = reference name`.
#' @param columns Value columns, given like `keys`.
#' @param tolerance Absolute tolerance for numeric columns: one number, or a
#'   named vector by observed column (unnamed columns use 0).
#' @param observed_element,reference_element Optional element names when an
#'   input is a list of tables (for example `"tests"` of
#'   [AdjustPatientFamilies()]).
#' @param observed_filter,reference_filter Optional named lists of column
#'   values selecting rows before the join.
#' @param reference_fill Optional value used for every reference column when
#'   a key is absent from the reference (for registries that omit zero rows);
#'   such rows are flagged in `reference_filled`.
#' @param check Label stored in column `check`.
#' @return A data frame with one row per key and column: `check`, the key
#'   columns (observed names), `row_key`, `column`, `reference_column`,
#'   `observed_value`, `reference_value` (text, 17 significant digits for numbers),
#'   `difference` (absolute, numeric pairs), `tolerance`, `reference_filled`,
#'   `matches` and `status` (`MATCH`, `MISMATCH`, `MISSING_OBSERVED`,
#'   `MISSING_REFERENCE`).
#' @examples
#' a <- data.frame(id = c("x", "y"), p = c(0.1, 0.2), s = c("ok", "ok"))
#' b <- data.frame(key = c("y", "x"), pv = c(0.2 + 1e-12, 0.1), s = c("ok", "no"))
#' CompareTables(a, b, keys = c(id = "key"), columns = c(p = "pv", s = "s"),
#'               tolerance = 1e-10)
#' @seealso [SummarizeComparisons()]
#' @export
CompareTables <- function(observed, reference, keys, columns, tolerance = 0,
                          observed_element = NULL, reference_element = NULL,
                          observed_filter = NULL, reference_filter = NULL,
                          reference_fill = NULL, check = "comparison") {
  .an_assert(is.null(reference_fill) || length(reference_fill) == 1L,
             "reference_fill must be one value")
  observed <- .an_element(observed, observed_element, "observed")
  reference <- .an_element(reference, reference_element, "reference")
  keys <- .an_mapping(keys, "keys")
  reserved <- c("check", "row_key", "column", "reference_column", "observed_value",
                "reference_value", "difference", "tolerance", "reference_filled", "matches", "status")
  .an_assert(!any(names(keys) %in% reserved), paste("Key names collide with output columns:",
             paste(intersect(names(keys), reserved), collapse = ", ")))
  columns <- .an_mapping(columns, "columns")
  .an_require(observed, c(names(keys), names(columns)), "observed")
  .an_require(reference, c(unname(keys), unname(columns)), "reference")
  observed <- as.data.frame(observed, stringsAsFactors = FALSE)
  reference <- as.data.frame(reference, stringsAsFactors = FALSE)
  filter <- function(d, f) {
    for (k in names(f)) d <- d[as.character(d[[k]]) %in% as.character(unlist(f[[k]])), , drop = FALSE]
    d
  }
  observed <- filter(observed, observed_filter)
  reference <- filter(reference, reference_filter)
  tol <- unlist(tolerance)
  .an_assert(is.numeric(tol) && all(is.finite(tol) & tol >= 0), "Invalid tolerance")
  if (!is.null(names(tol))) {
    .an_assert(all(names(tol) %in% names(columns)), "Tolerance for an unknown column")
    full <- stats::setNames(rep(0, length(columns)), names(columns))
    full[names(tol)] <- tol
    tol <- full
  } else {
    .an_assert(length(tol) == 1L, "Unnamed tolerance must be one number")
    tol <- stats::setNames(rep(tol, length(columns)), names(columns))
  }
  ko <- .an_key(observed, names(keys))
  kr <- .an_key(stats::setNames(reference[unname(keys)], names(keys)), names(keys))
  .an_assert(!anyDuplicated(ko), "Duplicate keys in observed")
  .an_assert(!anyDuplicated(kr), "Duplicate keys in reference")
  all_keys <- unique(c(ko, kr))
  io <- match(all_keys, ko)
  ir <- match(all_keys, kr)
  key_table <- data.frame(row.names = seq_along(all_keys))
  for (k in names(keys)) {
    v <- observed[[k]][io]
    miss <- is.na(io)
    if (any(miss)) v[miss] <- reference[[keys[[k]]]][ir[miss]]
    key_table[[k]] <- v
  }
  row_key <- do.call(paste, c(lapply(names(keys), function(k) .an_text(key_table[[k]])),
                              list(sep = " | ")))
  filled <- is.na(ir) & !is.null(reference_fill)
  parts <- lapply(names(columns), function(col) {
    o <- observed[[col]][io]
    r <- reference[[columns[[col]]]][ir]
    if (any(filled)) r[filled] <- reference_fill
    numeric_pair <- (is.numeric(o) || all(is.na(o))) && (is.numeric(r) || all(is.na(r))) &&
      (is.numeric(o) || is.numeric(r))
    if (numeric_pair) {
      o <- as.numeric(o)
      r <- as.numeric(r)
      diff <- abs(o - r)
      same <- (is.na(o) & is.na(r)) | (!is.na(o) & !is.na(r) & (o == r | diff <= tol[[col]]))
    } else {
      o <- as.character(o)
      r <- as.character(r)
      diff <- rep(NA_real_, length(o))
      same <- (is.na(o) & is.na(r)) | (!is.na(o) & !is.na(r) & o == r)
    }
    status <- ifelse(is.na(io), "MISSING_OBSERVED",
                     ifelse(is.na(ir) & !filled, "MISSING_REFERENCE",
                            ifelse(same, "MATCH", "MISMATCH")))
    data.frame(key_table, row_key = row_key, column = col, reference_column = columns[[col]],
               observed_value = .an_text(o), reference_value = .an_text(r), difference = diff,
               tolerance = if (numeric_pair) tol[[col]] else NA_real_,
               reference_filled = filled, matches = status == "MATCH", status = status,
               stringsAsFactors = FALSE, check.names = FALSE)
  })
  out <- do.call(rbind, parts)
  out <- cbind(check = rep(check, nrow(out)), out, stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

#' Compare Table Columns or Arrays with Arrays of a NumPy Archive
#'
#' Compares observed vectors or matrices (taken from columns of a table or
#' elements of a list) with reference arrays, read from an `.npz` archive with
#' `cellspecR::cs_read_npz()` or given as a list. Shapes must agree; values
#' are compared exactly or within an absolute tolerance.
#'
#' @param observed A data frame or named list.
#' @param reference Path to an `.npz` archive, or a named list of arrays.
#' @param arrays Named list: reference array name to the observed column(s)
#'   or element. Several columns are bound into a matrix in the given order.
#' @param tolerance Absolute tolerance (numbers).
#' @param check Label stored in column `check`.
#' @return A data frame with one row per array: `check`, `row_key` (array
#'   name), `array`, `observed_dim`, `reference_dim`, `reference_type`,
#'   `n_values`, `n_different`, `max_difference`, `tolerance`, `matches` and
#'   `status` (`MATCH`, `MISMATCH`, `SHAPE_MISMATCH`).
#' @examples
#' obs <- data.frame(a = 1:3, b = c(0, 1, 0), z = c(0.5, 1.5, 2.5))
#' ref <- list(counts = cbind(1:3, c(0, 1, 0)), z = c(0.5, 1.5, 2.5))
#' CompareArrays(obs, ref, list(counts = c("a", "b"), z = "z"))
#' @export
CompareArrays <- function(observed, reference, arrays, tolerance = 0, check = "arrays") {
  .an_assert(is.list(arrays) && .an_names(names(arrays), FALSE), "arrays must be a named list")
  if (is.character(reference) && length(reference) == 1L) {
    .an_assert(requireNamespace("cellspecR", quietly = TRUE),
               "Reading archives requires the cellspecR package")
    reference <- cellspecR::cs_read_npz(reference, arrays = names(arrays))
  }
  .an_assert(is.list(reference) && all(names(arrays) %in% names(reference)),
             "Reference lacks requested arrays")
  rows <- lapply(names(arrays), function(a) {
    cols <- as.character(unlist(arrays[[a]]))
    .an_assert(all(cols %in% names(observed)), paste("Observed lacks", paste(cols, collapse = ", ")))
    o <- if (length(cols) == 1L) observed[[cols]] else do.call(cbind, lapply(cols, function(k) observed[[k]]))
    r <- reference[[a]]
    od <- if (is.null(dim(o))) length(o) else dim(o)
    rd <- if (is.null(dim(r))) length(r) else dim(r)
    shape <- identical(as.numeric(od), as.numeric(rd))
    n_diff <- NA_real_
    max_diff <- NA_real_
    if (shape) {
      if (is.numeric(o) && is.numeric(r)) {
        d <- abs(as.numeric(o) - as.numeric(r))
        bad <- (is.na(o) != is.na(r)) | (!is.na(d) & d > tolerance)
        max_diff <- if (all(is.na(d))) NA_real_ else max(d, na.rm = TRUE)
      } else {
        bad <- !((is.na(o) & is.na(r)) | (!is.na(o) & !is.na(r) &
                                           as.character(o) == as.character(r)))
      }
      n_diff <- sum(bad)
    }
    status <- if (!shape) "SHAPE_MISMATCH" else if (n_diff == 0) "MATCH" else "MISMATCH"
    data.frame(check = check, row_key = a, array = a,
               observed_dim = paste(od, collapse = "x"), reference_dim = paste(rd, collapse = "x"),
               reference_type = typeof(r), n_values = if (shape) length(r) else NA_real_,
               n_different = n_diff, max_difference = max_diff, tolerance = tolerance,
               matches = status == "MATCH", status = status, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Summarise Comparison Results into Pass/Fail Checks
#'
#' Condenses outputs of [CompareTables()] or [CompareArrays()] (one or a list
#' of them) into one row per check: rows compared, rows whose values all
#' match, values compared and matching, the largest difference and
#' tolerance, and `PASS` when every value matches and the declared number of
#' rows (if any) was compared.
#'
#' @param comparisons A comparison data frame or a list of them. When an
#'   element lacks the first `by` column, its list name is used.
#' @param unit Columns that identify one compared row (default `"row_key"`).
#' @param expected_rows Optional named list or vector: value of the first
#'   `by` column (the check label) to the number of rows that must be
#'   compared in each summary row of that check.
#' @param by Columns defining one summary row (default `"check"`), for
#'   example `c("check", "branch")`. Missing columns are treated as `NA`.
#' @return A data frame with the `by` columns, `rows`, `matching_rows`,
#'   `values`, `matching_values`, `max_difference`, `tolerance`,
#'   `expected_rows` and `status`.
#' @examples
#' a <- data.frame(id = c("x", "y"), p = c(0.1, 0.2))
#' cmp <- CompareTables(a, a, "id", "p", check = "self")
#' SummarizeComparisons(cmp, expected_rows = c(self = 2))
#' @export
SummarizeComparisons <- function(comparisons, unit = "row_key", expected_rows = NULL,
                                 by = "check") {
  .an_assert(.an_names(unit, FALSE) && .an_names(by, FALSE), "Invalid unit or by columns")
  if (is.data.frame(comparisons)) comparisons <- list(comparisons)
  .an_assert(is.list(comparisons) && length(comparisons) > 0L &&
               all(vapply(comparisons, is.data.frame, logical(1))), "No comparisons given")
  label <- by[1L]
  comparisons <- lapply(seq_along(comparisons), function(i) {
    d <- comparisons[[i]]
    if (!label %in% names(d)) {
      .an_assert(!is.null(names(comparisons)) && nzchar(names(comparisons)[i]),
                 "Unlabelled comparison")
      d[[label]] <- rep(names(comparisons)[i], nrow(d))
    }
    d
  })
  all <- as.data.frame(data.table::rbindlist(comparisons, use.names = TRUE, fill = TRUE))
  for (k in setdiff(by, names(all))) all[[k]] <- NA_character_
  .an_require(all, c(by, unit, "matches"), "comparisons")
  expected <- unlist(expected_rows)
  parts <- .an_split(all, by)
  rows <- lapply(parts, function(ii) {
    d <- all[ii, , drop = FALSE]
    key <- .an_key(d, unit)
    ok <- tapply(d$matches, factor(key, levels = unique(key)), all)
    diff <- if ("max_difference" %in% names(d)) d$max_difference else d$difference
    if ("difference" %in% names(d) && "max_difference" %in% names(d)) {
      diff <- ifelse(is.na(d$max_difference), d$difference, d$max_difference)
    }
    tol <- if ("tolerance" %in% names(d)) d$tolerance else NA_real_
    arrays <- "n_values" %in% names(d) && all(!is.na(d$n_values))
    values <- if (arrays) sum(d$n_values) else nrow(d)
    matching_values <- if (arrays) sum(d$n_values - d$n_different) else sum(d$matches)
    ch <- as.character(d[[label]][1L])
    exp_rows <- if (!is.null(expected) && ch %in% names(expected)) expected[[ch]] else NA_real_
    pass <- all(d$matches) && (is.na(exp_rows) || length(ok) == exp_rows)
    out <- d[1L, by, drop = FALSE]
    cbind(out, data.frame(rows = length(ok), matching_rows = sum(ok), values = values,
      matching_values = matching_values,
      max_difference = if (all(is.na(diff))) NA_real_ else max(diff, na.rm = TRUE),
      tolerance = if (all(is.na(tol))) NA_real_ else max(tol, na.rm = TRUE),
      expected_rows = exp_rows, status = if (pass) "PASS" else "FAIL",
      stringsAsFactors = FALSE))
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

