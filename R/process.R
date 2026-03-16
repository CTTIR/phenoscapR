#' Quality Control Filter
#'
#' Removes cells that fail quality control criteria based on marker intensity
#' ranges, cell area, or custom filters.
#'
#' @param dt A `data.table` as returned by [read_akoya()].
#' @param min_area Numeric or `NULL`. Minimum cell area. Cells below this
#'   threshold are removed.
#' @param max_area Numeric or `NULL`. Maximum cell area. Cells above this
#'   threshold are removed.
#' @param min_intensity Numeric. Minimum total marker intensity. Cells with
#'   total intensity below this value are removed. Default `0`.
#' @param max_intensity Numeric or `NULL`. Maximum total marker intensity.
#'
#' @return A filtered `data.table`.
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:10,
#'   x = runif(10), y = runif(10),
#'   cell_area = c(5, seq(50, 200, length.out = 8), 5000),
#'   CD3 = rnorm(10, 300, 50)
#' )
#' filtered <- qc_filter(dt, min_area = 10, max_area = 1000)
#' nrow(filtered)
#'
#' @export
qc_filter <- function(dt, min_area = NULL, max_area = NULL,
                       min_intensity = 0, max_intensity = NULL) {
  dt <- data.table::copy(dt)

  if (!is.null(min_area) && "cell_area" %in% names(dt)) {
    dt <- dt[dt$cell_area >= min_area, ]
  }
  if (!is.null(max_area) && "cell_area" %in% names(dt)) {
    dt <- dt[dt$cell_area <= max_area, ]
  }

  marker_cols <- .marker_columns(dt)
  if (length(marker_cols) > 0L) {
    total <- rowSums(dt[, marker_cols, with = FALSE], na.rm = TRUE)
    keep <- total >= min_intensity
    if (!is.null(max_intensity)) {
      keep <- keep & total <= max_intensity
    }
    dt <- dt[keep, ]
  }

  dt
}

#' Normalise Marker Intensities
#'
#' Normalises marker intensity columns using one of several methods.
#'
#' @param dt A `data.table` as returned by [read_akoya()].
#' @param method Character string. Normalisation method: `"zscore"` (default),
#'   `"minmax"`, or `"quantile"`.
#' @param markers Character vector or `NULL`. Marker columns to normalise.
#'   If `NULL`, all detected marker columns are normalised.
#'
#' @return A `data.table` with normalised marker intensities.
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:20,
#'   x = runif(20), y = runif(20),
#'   CD3 = rnorm(20, 500, 100),
#'   CD8 = rnorm(20, 300, 80)
#' )
#' norm_dt <- normalise_markers(dt, method = "zscore")
#' head(norm_dt)
#'
#' @export
normalise_markers <- function(dt, method = c("zscore", "minmax", "quantile"),
                               markers = NULL) {
  method <- match.arg(method)
  dt <- data.table::copy(dt)

  cols <- if (!is.null(markers)) {
    intersect(markers, names(dt))
  } else {
    .marker_columns(dt)
  }

  if (length(cols) == 0L) {
    warning("No marker columns found to normalise.", call. = FALSE)
    return(dt)
  }

  for (col in cols) {
    vals <- dt[[col]]
    dt[, (col) := .normalise_vector(vals, method)]
  }

  dt
}

#' Normalise a numeric vector
#' @noRd
.normalise_vector <- function(x, method) {
  switch(method,
    zscore = {
      mu <- mean(x, na.rm = TRUE)
      s <- sd(x, na.rm = TRUE)
      if (is.na(s) || s == 0) return(x - mu)
      (x - mu) / s
    },
    minmax = {
      mn <- min(x, na.rm = TRUE)
      mx <- max(x, na.rm = TRUE)
      rng <- mx - mn
      if (rng == 0) return(rep(0, length(x)))
      (x - mn) / rng
    },
    quantile = {
      ranks <- rank(x, na.last = "keep", ties.method = "average")
      (ranks - 1) / (sum(!is.na(x)) - 1)
    }
  )
}

#' Phenotype Cells by Marker Thresholds
#'
#' Assigns phenotype labels to cells based on marker intensity thresholds.
#' A cell is considered positive for a marker if its intensity exceeds the
#' given threshold.
#'
#' @param dt A `data.table` as returned by [read_akoya()] or
#'   [normalise_markers()].
#' @param thresholds A named list where names are marker column names and
#'   values are numeric thresholds. Example:
#'   `list(CD3 = 0.5, CD8 = 0.3)`.
#' @param labels A named character vector mapping phenotype signatures to
#'   labels, or `NULL` for automatic labelling. When `NULL`, phenotypes are
#'   labelled by concatenating positive marker names with `"+"`.
#'
#' @return The input `data.table` with an added `phenotype` column.
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:6,
#'   x = runif(6), y = runif(6),
#'   CD3 = c(0.8, 0.1, 0.9, 0.2, 0.7, 0.05),
#'   CD8 = c(0.1, 0.6, 0.7, 0.05, 0.8, 0.02)
#' )
#' result <- phenotype_cells(dt, thresholds = list(CD3 = 0.5, CD8 = 0.5))
#' table(result$phenotype)
#'
#' @export
phenotype_cells <- function(dt, thresholds, labels = NULL) {
  dt <- data.table::copy(dt)

  markers <- names(thresholds)
  missing <- setdiff(markers, names(dt))
  if (length(missing) > 0L) {
    stop("Markers not found in data: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  # Build a positivity matrix
  pos <- vapply(markers, function(m) {
    dt[[m]] >= thresholds[[m]]
  }, logical(nrow(dt)))

  if (is.null(dim(pos))) {
    pos <- matrix(pos, ncol = 1L, dimnames = list(NULL, markers))
  }

  # Create phenotype labels
  pheno <- apply(pos, 1L, function(row) {
    positive <- markers[row]
    if (length(positive) == 0L) return("Negative")
    paste0(positive, "+", collapse = "/")
  })

  if (!is.null(labels)) {
    matched <- labels[pheno]
    pheno <- ifelse(is.na(matched), pheno, matched)
  }

  dt[, phenotype := pheno]
  dt
}

#' Summarise Phenotype Proportions
#'
#' Computes phenotype frequencies and proportions per sample.
#'
#' @param dt A `data.table` with a `phenotype` column, as returned by
#'   [phenotype_cells()].
#'
#' @return A `data.table` with columns `sample_id`, `phenotype`, `count`,
#'   and `proportion`.
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = rep("s1", 100),
#'   phenotype = sample(c("CD3+", "CD8+", "Negative"), 100, replace = TRUE)
#' )
#' summarise_phenotypes(dt)
#'
#' @export
summarise_phenotypes <- function(dt) {
  if (!"phenotype" %in% names(dt)) {
    stop("Column 'phenotype' not found. Run phenotype_cells() first.",
         call. = FALSE)
  }

  result <- dt[, .N, by = c("sample_id", "phenotype")]
  data.table::setnames(result, "N", "count")
  result[, proportion := count / sum(count), by = "sample_id"]
  result
}

#' Identify marker columns (non-metadata)
#' @noRd
.marker_columns <- function(dt) {
  meta <- c("sample_id", "cell_id", "x", "y", "cell_area", "phenotype",
            "cluster", "nn_distance", "density")
  cols <- setdiff(names(dt), meta)
  # Keep only numeric columns
  is_num <- vapply(cols, function(col) is.numeric(dt[[col]]), logical(1L))
  cols[is_num]
}
