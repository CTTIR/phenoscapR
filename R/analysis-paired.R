# Paired (within-subject) exact tests on declared differences.

.an_assert <- function(ok, message) {
  if (!isTRUE(ok)) stop(message, call. = FALSE)
}

.an_name <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
}

.an_names <- function(x, allow_null = TRUE) {
  if (is.null(x)) return(allow_null)
  is.character(x) && length(x) > 0L && !anyNA(x) && all(nzchar(trimws(x))) &&
    !anyDuplicated(x)
}

.an_require <- function(data, columns, what = "data") {
  .an_assert(is.data.frame(data), paste(what, "must be a data frame"))
  missing <- setdiff(columns, names(data))
  .an_assert(!length(missing), paste0(what, " lacks column(s): ",
                                      paste(missing, collapse = ", ")))
  .an_assert(!anyDuplicated(names(data)), paste(what, "has duplicate column names"))
}

# Character key of selected columns; one string per row.
.an_key <- function(data, columns) {
  if (!nrow(data)) return(character())
  if (!length(columns)) return(rep("", nrow(data)))
  parts <- lapply(columns, function(k) {
    z <- as.character(data[[k]])
    z[is.na(z)] <- "\001NA"
    paste0(nchar(z, type = "bytes"), ":", z)
  })
  do.call(paste, c(parts, list(sep = "\034")))
}

# Groups in order of first appearance. Without group columns all rows form
# one group, also when there are none.
.an_split <- function(data, columns) {
  if (!length(columns)) return(stats::setNames(list(seq_len(nrow(data))), ""))
  key <- .an_key(data, columns)
  split(seq_len(nrow(data)), factor(key, levels = unique(key)))
}

# Exact two-sided signed-rank p value by dynamic programming. Midranks of
# |d| are multiples of 1/2, so twice the ranks are integers and the null
# distribution of the positive rank sum is enumerated exactly. Probabilities
# are dyadic, so for n <= 52 the result equals (number of sign vectors with
# |sum(sign * rank)| >= observed) / 2^n without rounding.
.an_signed_rank_p <- function(d) {
  n <- length(d)
  r2 <- 2 * rank(abs(d), ties.method = "average")
  .an_assert(all(abs(r2 - round(r2)) < 1e-9), "Midranks are not half-integers")
  r2 <- as.integer(round(r2))
  total <- sum(r2)
  observed <- abs(2 * sum(r2[d > 0]) - total)
  prob <- numeric(total + 1L)
  prob[1L] <- 1
  for (k in r2) {
    shifted <- c(numeric(k), prob[seq_len(total + 1L - k)])
    prob <- 0.5 * prob + 0.5 * shifted
  }
  w <- 0:total
  sum(prob[abs(2 * w - total) >= observed])
}

.an_paired_one <- function(d, expected, conf_level, max_n) {
  finite <- d[is.finite(d)]
  nonzero <- finite[finite != 0]
  n <- length(nonzero)
  out <- list(
    n_available = length(finite), n_nonzero = n, n_zero = length(finite) - n,
    positive = sum(nonzero > 0), negative = sum(nonzero < 0),
    median_difference = NA_real_, mean_difference = NA_real_,
    signed_rank_sum = NA_real_, p_value = NA_real_, sign_p_value = NA_real_
  )
  if (n > 0L) {
    .an_assert(n <= max_n, paste("More than", max_n, "nonzero differences"))
    r <- rank(abs(nonzero), ties.method = "average")
    out$median_difference <- stats::median(nonzero)
    out$mean_difference <- mean(nonzero)
    out$signed_rank_sum <- sum(sign(nonzero) * r)
    out$p_value <- .an_signed_rank_p(nonzero)
    out$sign_p_value <- stats::binom.test(out$positive, n, p = 0.5)$p.value
  }
  out$status <- if (n > 0L) "EXACT" else "UNAVAILABLE_NO_NONZERO_DIFFERENCE"
  if (!is.null(expected)) {
    hit <- if (identical(expected, "less")) finite < 0 else finite > 0
    out$expected <- expected
    out$expected_direction <- sum(hit)
    out$direction_ci_low <- NA_real_
    out$direction_ci_high <- NA_real_
    if (length(finite)) {
      ci <- stats::binom.test(sum(hit), length(finite), conf.level = conf_level)$conf.int
      out$direction_ci_low <- ci[1L]
      out$direction_ci_high <- ci[2L]
    }
    out$conf_level <- conf_level
  }
  out
}

#' Exact Paired Sign-Flip Tests of Within-Subject Differences
#'
#' For each declared group of rows, tests whether paired differences are
#' symmetric about zero with the exact Wilcoxon signed-rank test over all
#' \eqn{2^n} sign assignments, together with the exact two-sided sign test and,
#' optionally, a Clopper-Pearson interval for the fraction of subjects whose
#' difference lies in an expected direction. Leave-one-subject-out results can
#' be requested instead of the full tests.
#'
#' Non-finite differences are unavailable; zero differences are excluded from
#' the signed-rank and sign tests (they still count as available subjects and
#' as not being in the expected direction). Ranks of absolute differences use
#' midranks for ties. The two-sided p value is the fraction of sign
#' assignments whose absolute signed-rank sum is at least the observed one. It
#' is computed by dynamic programming over twice the midranks (integers), so it
#' equals full enumeration exactly for up to 52 nonzero differences without
#' enumerating them.
#'
#' @param data Data frame in long form: one row per subject and test.
#' @param value Name of the numeric difference column (for a one-sample test,
#'   the values themselves).
#' @param groups Optional names of columns that define separate tests. `NULL`
#'   treats all rows as one test. Output groups follow first appearance.
#' @param id Optional subject column; required for `omit = "each"`. Subjects
#'   must be unique within a group.
#' @param expected Optional expected direction: `"less"` or `"greater"` for
#'   every group, or the name of a column holding `"less"`/`"greater"`
#'   (constant within a group). Adds the number of subjects in that direction
#'   and its Clopper-Pearson interval.
#' @param family Optional columns defining multiplicity families; adds
#'   `family_id` (values joined by `" :: "`). `hypothesis_id` joins the group
#'   values the same way. Both are ready for [AdjustPatientFamilies()].
#' @param omit `"none"` (full tests) or `"each"`: one row per group and
#'   omitted subject (all subjects of the group, in data order), with the
#'   omitted subject in column `omitted`.
#' @param conf_level Confidence level of the direction interval.
#' @param max_n Largest number of nonzero differences accepted.
#'
#' @return A data frame with the group columns, `n_available`, `n_nonzero`,
#'   `n_zero`, `positive`, `negative`, `median_difference` and
#'   `mean_difference` (of the nonzero differences), `signed_rank_sum`,
#'   `p_value` (signed-rank), `sign_p_value`, `status`, optionally `expected`,
#'   `expected_direction`, `direction_ci_low`, `direction_ci_high`,
#'   `conf_level`, and `hypothesis_id` (plus `family_id`).
#' @examples
#' d <- data.frame(test = rep(c("a", "b"), each = 6), subject = rep(1:6, 2),
#'                 difference = c(-3, -1, -2, -5, 1, -4, 2, -1, 3, 0, 1, 2))
#' ExactPairedTests(d, "difference", groups = "test", id = "subject",
#'                  expected = "less")
#' ExactPairedTests(d, "difference", groups = "test", id = "subject",
#'                  omit = "each")
#' @seealso [PairedDifferences()], [AdjustPatientFamilies()]
#' @export
ExactPairedTests <- function(data, value, groups = NULL, id = NULL, expected = NULL,
                             family = NULL, omit = c("none", "each"),
                             conf_level = 0.95, max_n = 500L) {
  omit <- match.arg(omit)
  .an_assert(.an_name(value), "value must be one column name")
  .an_assert(.an_names(groups) && .an_names(family), "Invalid group or family columns")
  .an_assert(is.null(id) || .an_name(id), "id must be one column name")
  .an_assert(omit == "none" || !is.null(id), "omit = 'each' requires id")
  .an_assert(is.numeric(conf_level) && length(conf_level) == 1L && conf_level > 0 &&
               conf_level < 1, "conf_level must lie in (0, 1)")
  .an_assert(is.numeric(max_n) && length(max_n) == 1L && max_n >= 1, "Invalid max_n")
  direction_column <- NULL
  if (!is.null(expected)) {
    .an_assert(.an_name(expected), "expected must be one string")
    if (!expected %in% c("less", "greater")) direction_column <- expected
  }
  .an_require(data, c(value, groups, id, family, direction_column))
  .an_assert(all(family %in% groups), "family columns must be among the group columns")
  reserved <- c("omitted", "hypothesis_id", "family_id", "n_available", "p_value")
  .an_assert(!any(c(groups, id) %in% reserved), "Group or id columns use reserved names")
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  x <- data[[value]]
  .an_assert(is.numeric(x) && !is.object(x), "value must be a numeric column")
  parts <- .an_split(data, groups)
  rows <- list()
  for (ii in parts) {
    direction <- expected
    if (!is.null(direction_column)) {
      direction <- unique(as.character(data[[direction_column]][ii]))
      .an_assert(length(direction) == 1L && direction %in% c("less", "greater"),
                 "Expected direction must be 'less' or 'greater', constant within a group")
    }
    key <- data[ii[1L], groups, drop = FALSE]
    if (!is.null(id)) {
      .an_assert(!anyNA(data[[id]][ii]) && !anyDuplicated(data[[id]][ii]),
                 "Subjects must be unique and nonmissing within a group")
    }
    if (omit == "none") {
      rows[[length(rows) + 1L]] <- cbind(key, as.data.frame(
        .an_paired_one(x[ii], direction, conf_level, max_n), stringsAsFactors = FALSE))
    } else {
      for (j in seq_along(ii)) {
        res <- .an_paired_one(x[ii[-j]], direction, conf_level, max_n)
        rows[[length(rows) + 1L]] <- cbind(key, omitted = data[[id]][ii[j]],
          as.data.frame(res, stringsAsFactors = FALSE), stringsAsFactors = FALSE)
      }
    }
  }
  out <- do.call(rbind, rows)
  if (is.null(out)) {
    # No groups or no subjects: typed columns without rows.
    direction <- if (is.null(expected) || is.null(direction_column)) expected else "less"
    out <- as.data.frame(.an_paired_one(numeric(), direction, conf_level, max_n),
                         stringsAsFactors = FALSE)[0L, , drop = FALSE]
    if (omit == "each") out <- cbind(omitted = data[[id]][0L], out, stringsAsFactors = FALSE)
    out <- cbind(data[0L, groups, drop = FALSE], out)
  }
  rownames(out) <- NULL
  if (!is.null(groups)) {
    out$hypothesis_id <- do.call(paste, c(lapply(groups, function(g) as.character(out[[g]])),
                                          list(sep = " :: ")))
    if (omit == "each") out$hypothesis_id <- paste(out$hypothesis_id, out$omitted, sep = " :: ")
  } else {
    out$hypothesis_id <- if (omit == "each") as.character(out$omitted) else rep("all", nrow(out))
  }
  if (!is.null(family)) {
    out$family_id <- do.call(paste, c(lapply(family, function(g) as.character(out[[g]])),
                                      list(sep = " :: ")))
  }
  out
}

#' Build Paired Differences from Wide Subject Tables
#'
#' Turns pairs of columns of one or several subject tables (one row per
#' subject) into long paired differences `x - y`, ready for
#' [ExactPairedTests()].
#'
#' @param data A data frame, or a named list of data frames (for example
#'   several summary tables of the same subjects).
#' @param id Subject column, unique within each table; not named `x`, `y` or
#'   `difference`.
#' @param pairs List of pair specifications, each a list with `name` (label
#'   of the difference), `x` and `y` (column names; `y = NULL` keeps `x`
#'   unchanged) and, when `data` is a list, `table` (element name). Further
#'   scalar fields (for example `expected = "less"`) become columns.
#' @param name Name of the output label column.
#' @return A data frame with `name`, the subject column, `x`, `y`,
#'   `difference` and any extra fields, pairs in the given order and subjects
#'   in table order.
#' @examples
#' d <- data.frame(subject = c("s1", "s2", "s3"), a = c(5, 7, 9), b = c(6, 6, 10))
#' PairedDifferences(d, "subject", list(list(name = "a - b", x = "a", y = "b",
#'                                           expected = "less")))
#' @export
PairedDifferences <- function(data, id, pairs, name = "endpoint") {
  .an_assert(.an_name(id) && .an_name(name) && id != name, "Invalid id or name")
  .an_assert(!any(c(id, name) %in% c("x", "y", "difference")),
             "id and name must differ from the output columns x, y and difference")
  .an_assert(is.list(pairs) && length(pairs) > 0L, "pairs must be a nonempty list")
  tables <- if (is.data.frame(data)) list(data) else data
  .an_assert(is.list(tables) && length(tables) > 0L &&
               all(vapply(tables, is.data.frame, logical(1))),
             "data must be a data frame or a list of data frames")
  core <- c(name, id, "x", "y", "difference")
  rows <- lapply(pairs, function(p) {
    .an_assert(is.list(p) && .an_name(p$name) && .an_name(p$x) &&
                 (is.null(p$y) || .an_name(p$y)), "Each pair needs name, x and y")
    if (is.data.frame(data)) {
      tab <- data
    } else {
      .an_assert(.an_name(p$table) && p$table %in% names(tables),
                 paste("Unknown table for pair", p$name))
      tab <- tables[[p$table]]
    }
    .an_require(tab, c(id, p$x, p$y), paste("table for pair", p$name))
    .an_assert(!anyNA(tab[[id]]) && !anyDuplicated(tab[[id]]), "Subjects must be unique")
    xv <- as.numeric(tab[[p$x]])
    yv <- if (is.null(p$y)) rep(0, nrow(tab)) else as.numeric(tab[[p$y]])
    out <- data.frame(label = rep(p$name, nrow(tab)), subject = tab[[id]], x = xv,
                      y = if (is.null(p$y)) NA_real_ else yv,
                      difference = if (is.null(p$y)) xv else xv - yv,
                      stringsAsFactors = FALSE)
    names(out)[1:2] <- c(name, id)
    extra <- setdiff(names(p), c("name", "x", "y", "table"))
    for (k in extra) {
      .an_assert(length(p[[k]]) == 1L && !k %in% core, paste("Invalid extra field", k))
      out[[k]] <- rep(p[[k]], nrow(out))
    }
    out
  })
  out <- data.table::rbindlist(rows, use.names = TRUE, fill = TRUE)
  as.data.frame(out, stringsAsFactors = FALSE)
}
