#' Read Akoya Cell Segmentation Data
#'
#' Reads cell segmentation CSV files produced by Akoya Biosciences platforms
#' (PhenoCycler, CODEX, PhenoImager). The function auto-detects column naming
#' conventions and standardises them for downstream analysis.
#'
#' @param path Character string. Path to a CSV file or a directory containing
#'   CSV files. When a directory is given, all `.csv` files in that directory
#'   are read and combined.
#' @param sample_id Character string or `NULL`. An identifier appended to each
#'   row. When `path` is a directory and `sample_id` is `NULL`, the file name
#'   (without extension) is used as the sample identifier.
#' @param markers Character vector or `NULL`. If provided, only these marker
#'   columns are retained. Column matching is case-insensitive.
#'
#' @return A `data.table` with standardised column names:
#'   \describe{
#'     \item{sample_id}{Sample identifier.}
#'     \item{cell_id}{Unique cell identifier (per sample).}
#'     \item{x}{Cell centroid x-coordinate.}
#'     \item{y}{Cell centroid y-coordinate.}
#'     \item{cell_area}{Cell area in pixels (if available).}
#'   }
#'   Additional columns contain marker intensities.
#'
#' @examples
#' # Create a temporary example file
#' tmp <- tempfile(fileext = ".csv")
#' write.csv(data.frame(
#'   `Cell ID` = 1:5,
#'   `Cell X Position` = runif(5, 0, 1000),
#'   `Cell Y Position` = runif(5, 0, 1000),
#'   `Cell Area (px)` = runif(5, 50, 200),
#'   DAPI = rnorm(5, 500, 100),
#'   CD3 = rnorm(5, 300, 80),
#'   check.names = FALSE
#' ), tmp, row.names = FALSE)
#' dat <- read_akoya(tmp)
#' head(dat)
#' unlink(tmp)
#'
#' @export
read_akoya <- function(path, sample_id = NULL, markers = NULL) {
  if (!file.exists(path)) {
    stop("Path does not exist: ", path, call. = FALSE)
  }

  if (dir.exists(path)) {
    files <- list.files(path, pattern = "\\.csv$", full.names = TRUE,
                        ignore.case = TRUE)
    if (length(files) == 0L) {
      stop("No CSV files found in directory: ", path, call. = FALSE)
    }
    dts <- lapply(files, function(f) {
      sid <- if (is.null(sample_id)) {
        tools::file_path_sans_ext(basename(f))
      } else {
        sample_id
      }
      .read_single(f, sid, markers)
    })
    dt <- data.table::rbindlist(dts, use.names = TRUE, fill = TRUE)
  } else {
    sid <- if (is.null(sample_id)) {
      tools::file_path_sans_ext(basename(path))
    } else {
      sample_id
    }
    dt <- .read_single(path, sid, markers)
  }

  dt
}

#' Read a single Akoya CSV file
#' @noRd
.read_single <- function(file, sample_id, markers) {
  dt <- data.table::fread(file, check.names = FALSE)
  dt <- .standardise_columns(dt)
  dt[, sample_id := sample_id]

  if (!is.null(markers)) {
    markers_lower <- tolower(markers)
    keep <- c("sample_id", "cell_id", "x", "y", "cell_area")
    marker_cols <- names(dt)[tolower(names(dt)) %in% markers_lower]
    keep <- intersect(c(keep, marker_cols), names(dt))
    dt <- dt[, keep, with = FALSE]
  }

  # Reorder so metadata columns come first
  meta <- intersect(c("sample_id", "cell_id", "x", "y", "cell_area"),
                    names(dt))
  rest <- setdiff(names(dt), meta)
  data.table::setcolorder(dt, c(meta, rest))

  dt
}

#' Create an AkoyaExperiment from Existing Data
#'
#' Constructs an \code{\link{AkoyaExperiment-class}} from a counts matrix,
#' coordinate data frame, and optional metadata.
#'
#' @param counts Numeric matrix (cells x markers). Row names are optional.
#' @param coords Data frame with columns \code{x} and \code{y}.
#' @param meta_data Data frame of per-cell metadata, or \code{NULL}.
#' @param sample_id Character. Sample identifier. Default \code{"sample1"}.
#' @param project Character. Project name. Default \code{"AkoyaProject"}.
#'
#' @return An \code{\link{AkoyaExperiment-class}} object.
#'
#' @examples
#' counts <- matrix(rnorm(50), nrow = 10,
#'                  dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
#' coords <- data.frame(x = runif(10, 0, 500), y = runif(10, 0, 500))
#' obj <- CreateAkoyaObject(counts, coords, sample_id = "mysample")
#' obj
#'
#' @export
CreateAkoyaObject <- function(counts, coords, meta_data = NULL,
                              sample_id = "sample1",
                              project = "AkoyaProject") {
  counts <- as.matrix(counts)
  coords <- as.data.frame(coords)
  n <- nrow(counts)

  if (is.null(meta_data)) {
    meta_data <- data.frame(
      cell_id = as.character(seq_len(n)),
      sample_id = rep(sample_id, n),
      stringsAsFactors = FALSE
    )
  } else {
    meta_data <- as.data.frame(meta_data)
    if (!"cell_id" %in% names(meta_data)) {
      meta_data$cell_id <- as.character(seq_len(n))
    }
    if (!"sample_id" %in% names(meta_data)) {
      meta_data$sample_id <- rep(sample_id, n)
    }
  }

  methods::new("AkoyaExperiment",
    counts    = counts,
    data      = counts,
    coords    = coords,
    meta_data = meta_data,
    project   = project,
    spatial   = list()
  )
}

#' Read Akoya Cell Segmentation Data (S4 interface)
#'
#' Reads cell segmentation CSV files produced by Akoya Biosciences platforms
#' (PhenoCycler, CODEX, PhenoImager) and returns an
#' \code{\link{AkoyaExperiment-class}} object.
#'
#' @param path Character. Path to a CSV file or a directory containing CSV
#'   files.
#' @param type Character. Input format: \code{"auto"} (default),
#'   \code{"processor"}, \code{"inform"}, or \code{"qupath"}.
#' @param sample_id Character or \code{NULL}. An identifier for the sample.
#' @param markers Character vector or \code{NULL}. If provided, only these
#'   marker columns are retained.
#' @param filter Character or \code{NA}. Regex pattern for marker names to
#'   exclude. Default \code{"DAPI|Blank|Empty"}.
#' @param recursive Logical. Search subdirectories? Default \code{TRUE}.
#' @param project Character. Project name. Default \code{"AkoyaProject"}.
#'
#' @return An \code{\link{AkoyaExperiment-class}} object.
#'
#' @examples
#' tmp <- tempfile(fileext = ".csv")
#' write.csv(data.frame(
#'   `Cell ID` = 1:5,
#'   `Cell X Position` = runif(5, 0, 1000),
#'   `Cell Y Position` = runif(5, 0, 1000),
#'   CD3 = rnorm(5, 300, 80),
#'   CD8 = rnorm(5, 200, 60),
#'   check.names = FALSE
#' ), tmp, row.names = FALSE)
#' obj <- ReadAkoya(tmp, filter = NA)
#' obj
#' unlink(tmp)
#'
#' @export
ReadAkoya <- function(path, type = c("auto", "processor", "inform", "qupath"),
                      sample_id = NULL, markers = NULL,
                      filter = "DAPI|Blank|Empty",
                      recursive = TRUE,
                      project = "AkoyaProject") {
  type <- match.arg(type)
  dt <- read_akoya(path, sample_id = sample_id, markers = markers)

  # Filter unwanted markers
  if (!is.na(filter) && nchar(filter) > 0L) {
    marker_cols <- .marker_columns(dt)
    drop <- marker_cols[grepl(filter, marker_cols, ignore.case = TRUE)]
    if (length(drop) > 0L) {
      dt[, (drop) := NULL]
    }
  }

  # Build AkoyaExperiment
  meta_cols <- c("sample_id", "cell_id", "cell_area")
  meta_cols <- intersect(meta_cols, names(dt))
  marker_cols <- .marker_columns(dt)

  counts <- as.matrix(dt[, marker_cols, with = FALSE])
  coords <- data.frame(x = dt$x, y = dt$y)
  meta_data <- as.data.frame(dt[, meta_cols, with = FALSE])

  if (!"cell_id" %in% names(meta_data)) {
    meta_data$cell_id <- as.character(seq_len(nrow(counts)))
  }
  if (!"sample_id" %in% names(meta_data)) {
    meta_data$sample_id <- "sample1"
  }

  methods::new("AkoyaExperiment",
    counts    = counts,
    data      = counts,
    coords    = coords,
    meta_data = meta_data,
    project   = project,
    spatial   = list()
  )
}

#' Standardise Akoya column names
#' @noRd
.standardise_columns <- function(dt) {
  nms <- names(dt)
  lower <- tolower(nms)

  # Cell ID
  id_pat <- which(lower %in% c("cell id", "cell_id", "object id",
                                "object_id", "cellid"))
  if (length(id_pat) > 0L) {
    data.table::setnames(dt, nms[id_pat[1L]], "cell_id")
  } else {
    dt[, cell_id := seq_len(.N)]
  }

  # X position
  x_pat <- which(grepl("cell.*(x|centroid.*x|x.*pos)|^centroid.*x", lower) |
                   lower %in% c("x", "x_position", "x position",
                                "centroid x", "centroid_x"))
  if (length(x_pat) > 0L) {
    data.table::setnames(dt, nms[x_pat[1L]], "x")
  }

  # Y position
  y_pat <- which(grepl("cell.*(y|centroid.*y|y.*pos)|^centroid.*y", lower) |
                   lower %in% c("y", "y_position", "y position",
                                "centroid y", "centroid_y"))
  if (length(y_pat) > 0L) {
    data.table::setnames(dt, nms[y_pat[1L]], "y")
  }

  # Cell area
  area_pat <- which(grepl("cell.*area|area.*px|area.*pixel", lower) |
                      lower %in% c("cell_area", "area"))
  if (length(area_pat) > 0L) {
    data.table::setnames(dt, nms[area_pat[1L]], "cell_area")
  }

  if (!"x" %in% names(dt) || !"y" %in% names(dt)) {
    stop("Could not identify x and y coordinate columns.", call. = FALSE)
  }

  dt
}
