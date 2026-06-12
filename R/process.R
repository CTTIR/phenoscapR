#' Quality Control Filter
#'
#' Removes cells that fail quality control criteria based on marker intensity
#' ranges, cell area, or custom filters.
#'
#' @param dt A `data.table` as returned by [read_spatial()].
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

  area <- if ("cell_area" %in% names(dt)) dt$cell_area else NULL
  marker_cols <- .marker_columns(dt)
  total <- if (length(marker_cols) > 0L) {
    rowSums(dt[, marker_cols, with = FALSE], na.rm = TRUE)
  } else {
    NULL
  }

  keep <- .qc_keep_mask(nrow(dt), area, total, min_area, max_area,
                        min_intensity, max_intensity)
  dt[keep, ]
}

#' Quality-control keep mask
#'
#' Shared engine for [qc_filter()] and [QCFilter()]. Returns a logical vector
#' marking the cells that pass the area and total-intensity thresholds. Area or
#' total intensity is skipped when \code{NULL} (e.g. no \code{cell_area} column
#' or no marker columns), matching the lenient behaviour of both callers.
#' @noRd
.qc_keep_mask <- function(n, area = NULL, total = NULL, min_area = NULL,
                          max_area = NULL, min_intensity = 0,
                          max_intensity = NULL) {
  keep <- rep(TRUE, n)
  if (!is.null(area)) {
    if (!is.null(min_area)) keep <- keep & area >= min_area
    if (!is.null(max_area)) keep <- keep & area <= max_area
  }
  if (!is.null(total)) {
    keep <- keep & total >= min_intensity
    if (!is.null(max_intensity)) keep <- keep & total <= max_intensity
  }
  keep
}

#' Normalise Marker Intensities
#'
#' Normalises marker intensity columns using one of several methods.
#'
#' @param dt A `data.table` as returned by [read_spatial()].
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
#' @param dt A `data.table` as returned by [read_spatial()] or
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

  present <- intersect(names(thresholds), names(dt))
  mat <- if (length(present) > 0L) {
    as.matrix(dt[, present, with = FALSE])
  } else {
    matrix(numeric(0), nrow = nrow(dt), ncol = 0L)
  }

  dt[, phenotype := .assign_phenotypes(mat, thresholds, labels)]
  dt
}

#' Assign phenotype labels from a marker matrix
#'
#' Shared engine for [phenotype_cells()] (data.table) and [PhenotypeCells()]
#' (SpatialCellData). A cell is positive for a marker when its intensity meets
#' or exceeds the threshold; the label concatenates positive markers with
#' \code{"+"}, or \code{"Negative"} when none are positive.
#' @noRd
.assign_phenotypes <- function(mat, thresholds, labels = NULL) {
  markers <- names(thresholds)
  missing <- setdiff(markers, colnames(mat))
  if (length(missing) > 0L) {
    stop("Markers not found in data: ",
         paste(missing, collapse = ", "), call. = FALSE)
  }

  pos <- vapply(markers, function(m) mat[, m] >= thresholds[[m]],
                logical(nrow(mat)))
  if (is.null(dim(pos))) {
    pos <- matrix(pos, ncol = 1L, dimnames = list(NULL, markers))
  }

  pheno <- apply(pos, 1L, function(row) {
    positive <- markers[row]
    if (length(positive) == 0L) return("Negative")
    paste0(positive, "+", collapse = "/")
  })

  if (!is.null(labels)) {
    matched <- labels[pheno]
    pheno <- ifelse(is.na(matched), pheno, matched)
  }

  pheno
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
  .summarise_phenotypes(dt)
}

#' Phenotype counts and proportions per sample
#'
#' Shared engine for [summarise_phenotypes()] and [PhenotypeSummary()].
#' @noRd
.summarise_phenotypes <- function(dt) {
  if (!"phenotype" %in% names(dt)) {
    stop("Column 'phenotype' not found. Run phenotype_cells() first.",
         call. = FALSE)
  }
  dt <- data.table::as.data.table(dt)
  result <- dt[, .N, by = c("sample_id", "phenotype")]
  data.table::setnames(result, "N", "count")
  result[, proportion := count / sum(count), by = "sample_id"]
  result
}

# ---------------------------------------------------------------------------
# S4-style wrappers operating on SpatialCellData objects
# ---------------------------------------------------------------------------

#' Quality Control Filter (SpatialCellData)
#'
#' Removes cells that fail quality control criteria based on cell area
#' and/or total marker intensity.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param min_area Numeric or \code{NULL}. Minimum cell area.
#' @param max_area Numeric or \code{NULL}. Maximum cell area.
#' @param min_intensity Numeric. Minimum total marker intensity. Default \code{0}.
#' @param max_intensity Numeric or \code{NULL}. Maximum total marker intensity.
#'
#' @return A filtered \code{\link{SpatialCellData-class}} object.
#'
#' @examples
#' counts <- matrix(rnorm(60, 5), nrow = 20,
#'                  dimnames = list(NULL, c("CD3", "CD8", "CD20")))
#' coords <- data.frame(x = runif(20), y = runif(20))
#' meta <- data.frame(cell_id = 1:20, sample_id = "s1",
#'                    cell_area = c(5, seq(50, 200, length.out = 18), 5000))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' filtered <- QCFilter(obj, min_area = 10, max_area = 1000)
#' NCells(filtered)
#'
#' @export
QCFilter <- function(object, min_area = NULL, max_area = NULL,
                     min_intensity = 0, max_intensity = NULL) {
  md <- object@meta_data
  area <- if ("cell_area" %in% names(md)) md$cell_area else NULL
  total <- rowSums(object@counts, na.rm = TRUE)

  keep <- .qc_keep_mask(NCells(object), area, total, min_area, max_area,
                        min_intensity, max_intensity)
  object[keep, ]
}

#' Normalise Marker Intensities (SpatialCellData)
#'
#' Normalises marker intensities and stores the result in the \code{data} slot.
#' Raw counts remain unchanged.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param method Character. \code{"zscore"} (default), \code{"minmax"}, or
#'   \code{"quantile"}.
#' @param markers Character vector or \code{NULL}. Markers to normalise.
#'   If \code{NULL}, all markers are normalised.
#'
#' @return An \code{\link{SpatialCellData-class}} with updated \code{data} slot.
#'
#' @examples
#' counts <- matrix(rnorm(40, 500, 100), nrow = 20,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(20), y = runif(20))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- NormaliseData(obj, method = "zscore")
#'
#' @export
NormaliseData <- function(object, method = c("zscore", "minmax", "quantile"),
                          markers = NULL) {
  method <- match.arg(method)
  mat <- object@counts

  cols <- if (!is.null(markers)) {
    intersect(markers, colnames(mat))
  } else {
    colnames(mat)
  }

  norm_mat <- mat
  for (col in cols) {
    norm_mat[, col] <- .normalise_vector(mat[, col], method)
  }
  object@data <- norm_mat
  object
}

#' Phenotype Cells (SpatialCellData)
#'
#' Assigns phenotype labels to cells based on marker intensity thresholds.
#' Uses the normalised \code{data} slot.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#' @param thresholds Named list of thresholds (marker name = value).
#' @param labels Named character vector mapping signatures to labels, or
#'   \code{NULL} for automatic labelling.
#'
#' @return An \code{\link{SpatialCellData-class}} with a \code{phenotype}
#'   column in \code{meta_data}.
#'
#' @examples
#' counts <- matrix(c(rnorm(10, 5), rnorm(10, 1)), ncol = 2,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(10), y = runif(10))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- PhenotypeCells(obj, thresholds = list(CD3 = 3, CD8 = 3))
#' table(Meta(obj)$phenotype)
#'
#' @export
PhenotypeCells <- function(object, thresholds, labels = NULL) {
  object@meta_data$phenotype <-
    .assign_phenotypes(object@data, thresholds, labels)
  object
}

#' Phenotype Summary (SpatialCellData)
#'
#' Computes phenotype counts and proportions per sample.
#'
#' @param object An \code{\link{SpatialCellData-class}} object.
#'
#' @return A data frame with columns \code{sample_id}, \code{phenotype},
#'   \code{count}, and \code{proportion}.
#'
#' @examples
#' counts <- matrix(c(rnorm(15, 5), rnorm(15, 1)), ncol = 2,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(15), y = runif(15))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- PhenotypeCells(obj, thresholds = list(CD3 = 3, CD8 = 3))
#' PhenotypeSummary(obj)
#'
#' @export
PhenotypeSummary <- function(object) {
  as.data.frame(.summarise_phenotypes(object@meta_data))
}

#' Identify marker columns (non-metadata)
#' @noRd
.marker_columns <- function(dt) {
  meta <- c("sample_id", "cell_id", "x", "y", "cell_area", "nucleus_area",
            "classification", "parent", "phenotype", "cluster",
            "nn_distance", "density")
  cols <- setdiff(names(dt), meta)
  # Keep only numeric columns
  is_num <- vapply(cols, function(col) is.numeric(dt[[col]]), logical(1L))
  cols[is_num]
}
