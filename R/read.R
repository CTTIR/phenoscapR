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
