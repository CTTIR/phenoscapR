# Text templates filled from plot data, so that numbers printed in figure
# text come from tables rather than from configuration.

#' Fill Text Templates from Table Rows
#'
#' Replaces placeholders in braces with values of `data`, so that figure text
#' such as `"{k|d}/{n|d} patients; p = {p|p}"` is written from plot data
#' rather than typed by hand. Placeholders:
#'
#' * `{column}`: the value; whole numbers with thousands separators
#'   (`1,200`), other numbers and text as they are, missing values `"n.e."`.
#' Negative numbers are written with a true minus sign.
#'
#' * `{column|format}`: a named format: `p` ([FormatP()]), `pfixed` (four
#'   decimals below 0.01, three otherwise), `d` (rounded integer), `comma`
#'   (rounded integer with thousands separators), `f0` to `f9` (fixed
#'   decimals), `sf0` to `sf9` (fixed decimals with a leading `+` or true
#'   minus sign) and `s` (the value as text).
#' * `{column:%fmt}`: a `sprintf()` format such as `%.1f`.
#' * `{column~singular~plural}`: `singular` when the value is 1, otherwise
#'   `plural`.
#'
#' A placeholder whose whole content is a column name refers to that column,
#' so column names may contain `|`, `:` or `~`.
#'
#' @param template Character vector of templates. A single template is
#'   applied to every row; several templates use one row each, or all the
#'   single row of a one-row table.
#' @param data A data frame (or a named list treated as one row), or `NULL`
#'   for templates without placeholders.
#' @return Character vector, one element per template or per row.
#' @examples
#' d <- data.frame(k = 11, n = 12, p = 0.00146, cells = 27081)
#' FormatTemplate("{k|d}/{n|d} patients; p = {p|p}", d)
#' FormatTemplate("{cells} cells ({cells:%.0f}); {k~patient~patients}", d)
#' FormatTemplate("{x|sf1} ({share|f0}%)", data.frame(x = -3.42, share = 51.2))
#' @family figure text
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
  for (i in seq_len(n)) {
    s <- template[i]
    for (h in unique(regmatches(s, gregexpr("\\{[^{}]+\\}", s))[[1L]])) {
      ph <- .fig_template_parse(h, names(data))
      if (is.null(ph)) next
      if (!ph$column %in% names(data)) stop("Template refers to missing column '", ph$column, "'.", call. = FALSE)
      if (!nrow(data)) stop("Template needs at least one data row.", call. = FALSE)
      s <- gsub(h, .fig_template_value(data[[ph$column]][[i]], ph), s, fixed = TRUE)
    }
    out[i] <- s
  }
  out
}

# Parse one placeholder "{...}". Returns NULL for braces that are not a
# placeholder (an unknown "|format" suffix on a name that is not a column).
.fig_template_parse <- function(h, columns = character()) {
  inner <- substr(h, 2L, nchar(h) - 1L)
  if (inner %in% columns) return(list(column = inner, kind = "plain"))
  m <- regmatches(inner, regexec("^(.+)~(.*)~(.*)$", inner))[[1L]]
  if (length(m)) return(list(column = trimws(m[2]), kind = "plural", one = m[3], many = m[4]))
  m <- regmatches(inner, regexec("^(.+)\\|([A-Za-z0-9+]+)$", inner))[[1L]]
  if (length(m)) return(list(column = trimws(m[2]), kind = "format", format = m[3]))
  if (grepl("|", inner, fixed = TRUE)) return(NULL)
  m <- regmatches(inner, regexec("^(.+?):(%.+)$", inner))[[1L]]
  if (length(m)) return(list(column = trimws(m[2]), kind = "sprintf", format = m[3]))
  list(column = trimws(inner), kind = "plain")
}

.fig_template_value <- function(value, ph) {
  switch(ph$kind,
    plural = if (isTRUE(as.numeric(value) == 1)) ph$one else ph$many,
    sprintf = sprintf(ph$format, value),
    format = .fig_format_value(value, ph$format),
    plain = {
      if (length(value) != 1L || is.na(value)) "n.e."
      else if (is.numeric(value) && abs(value - round(value)) < 1e-9) .fig_minus(formatC(round(value), format = "d", big.mark = ","))
      else if (is.numeric(value)) .fig_minus(as.character(value))
      else as.character(value)
    })
}

.fig_format_value <- function(value, format) {
  if (format == "s") return(if (is.na(value)) "n.e." else as.character(value))
  if (is.character(value) || is.factor(value)) {
    stop("Format '", format, "' needs a numeric value.", call. = FALSE)
  }
  value <- as.numeric(value)
  if (format == "p") return(FormatP(value))
  if (!is.finite(value)) return("n.e.")
  if (format == "pfixed") return(sprintf(if (value < 0.01) "%.4f" else "%.3f", value))
  if (format == "d") return(.fig_minus(formatC(round(value) + 0, format = "f", digits = 0)))
  if (format == "comma") return(.fig_minus(formatC(round(value), format = "d", big.mark = ",")))
  if (grepl("^f[0-9]$", format)) return(.fig_minus(formatC(value, format = "f", digits = as.integer(substring(format, 2)))))
  if (grepl("^sf[0-9]$", format)) {
    body <- formatC(abs(value), format = "f", digits = as.integer(substring(format, 3)))
    sign <- if (as.numeric(body) == 0) "" else if (value < 0) "\u2212" else "+"
    return(paste0(sign, body))
  }
  stop("Unknown template format '", format, "'.", call. = FALSE)
}

# One row of template values from a table whose referenced columns hold a
# single distinct value each (missing values ignored), as used by grammar
# texts filled from whole plot-data tables.
.fig_template_unique <- function(template, values) {
  if (is.data.frame(values) || is.list(values)) values <- as.list(values)
  hits <- unique(regmatches(template, gregexpr("\\{[^{}]+\\}", template))[[1L]])
  row <- list()
  for (h in hits) {
    ph <- .fig_template_parse(h, names(values))
    if (is.null(ph)) next
    v <- values[[ph$column]]
    if (is.null(v)) stop("No value for '", ph$column, "' in template.", call. = FALSE)
    v <- unique(v[!is.na(v)])
    if (length(v) != 1L) stop("'", ph$column, "' must have one distinct value for the template.", call. = FALSE)
    row[[ph$column]] <- v
  }
  if (!length(row)) return(NULL)
  as.data.frame(row, check.names = FALSE, stringsAsFactors = FALSE)
}

# Numbers in figure text use a true minus sign.
.fig_minus <- function(x) sub("^-", "\u2212", x)
