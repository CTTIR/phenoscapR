# ============================================================================
# read.R -- Data import for single-cell spatial biology data
# ============================================================================
# Supports three input formats:
#   1. QuPath Full Export  -- Object ID, Classification, multi-compartment markers
#   2. QuPath Minimal      -- Centroid coords + "{Marker}: Cell: Mean" columns
#   3. Flat Format         -- Cell ID, Cell X/Y Position, flat marker columns
# ============================================================================

# ---------------------------------------------------------------------------
# Internal helpers: format and delimiter detection
# ---------------------------------------------------------------------------

#' Detect CSV delimiter from first line
#' @noRd
.detect_sep <- function(file) {
  line1 <- readLines(file, n = 1L, encoding = "UTF-8", warn = FALSE)
  line1 <- sub("^\ufeff", "", line1)
  n_semi  <- nchar(gsub("[^;]", "", line1))
  n_comma <- nchar(gsub("[^,]", "", line1))
  if (n_semi > n_comma) ";" else ","
}

#' Detect input format from column names
#'
#' @return One of \code{"qupath_full"}, \code{"minimal"}, or \code{"processor"}.
#' @noRd
.detect_format <- function(nms) {
  lower <- tolower(nms)
  if (any(lower == "object id")) return("qupath_full")
  if (any(grepl(": cell: mean$", lower))) return("minimal")
  "processor"
}

#' Extract unique marker names from QuPath full-format columns
#'
#' Column pattern: \code{{Compartment}: {Marker} {statistic}}
#'
#' @param nms Character vector of column names.
#' @return Character vector of unique marker names.
#' @noRd
.get_markers_full <- function(nms) {
  pat <- "^(Nucleus|Cell|Cytoplasm): (.+) (mean|sum|std dev|max|min|range)$"
  m <- regmatches(nms, regexec(pat, nms, ignore.case = TRUE))
  markers <- vapply(m, function(x) {
    if (length(x) >= 3L) x[3L] else NA_character_
  }, character(1L))
  unique(markers[!is.na(markers)])
}

#' Extract unique marker names from QuPath minimal-format columns
#'
#' Column pattern: \code{{Marker}: Cell: Mean}
#'
#' @param nms Character vector of column names.
#' @return Character vector of unique marker names.
#' @noRd
.get_markers_minimal <- function(nms) {
  pat <- "^(.+): Cell: Mean$"
  m <- regmatches(nms, regexec(pat, nms, ignore.case = TRUE))
  markers <- vapply(m, function(x) {
    if (length(x) >= 2L) x[2L] else NA_character_
  }, character(1L))
  markers[!is.na(markers)]
}

#' Find the column matching a QuPath full-format intensity value
#' @noRd
.intensity_col <- function(nms, marker, compartment = "Cell",
                           statistic = "mean") {
  target <- tolower(paste0(compartment, ": ", marker, " ", statistic))
  idx <- which(tolower(nms) == target)
  if (length(idx) > 0L) nms[idx[1L]] else NA_character_
}

# ---------------------------------------------------------------------------
# Column standardisation per format
# ---------------------------------------------------------------------------

#' Standardise QuPath full-format columns
#' @noRd
.standardise_qupath_full <- function(dt, compartment, statistic) {
  nms <- names(dt)
  lower <- tolower(nms)

  # --- Spatial coordinates ---
  x_idx <- which(grepl("^centroid x", lower))
  y_idx <- which(grepl("^centroid y", lower))
  if (length(x_idx) == 0L || length(y_idx) == 0L) {
    stop("Could not find Centroid X / Centroid Y columns.", call. = FALSE)
  }
  data.table::setnames(dt, nms[x_idx[1L]], "x")
  data.table::setnames(dt, nms[y_idx[1L]], "y")

  # --- Cell ID ---
  id_idx <- which(lower == "object id")
  if (length(id_idx) > 0L) {
    data.table::setnames(dt, nms[id_idx[1L]], "cell_id")
  } else {
    dt[, cell_id := as.character(seq_len(.N))]
  }

  # --- Sample identity from Image column ---
  img_idx <- which(lower == "image")
  if (length(img_idx) > 0L) {
    dt[, sample_id := sub(" - .*$", "", dt[[nms[img_idx[1L]]]])]
  }

  # --- Classification ---
  cls_idx <- which(lower == "classification")
  if (length(cls_idx) > 0L) {
    vals <- dt[[nms[cls_idx[1L]]]]
    vals[is.na(vals) | vals == ""] <- NA_character_
    dt[, classification := vals]
  }

  # --- Parent (ROI) ---
  par_idx <- which(lower == "parent")
  if (length(par_idx) > 0L) {
    data.table::setnames(dt, nms[par_idx[1L]], "parent")
  }

  # --- Cell area from morphology ---
  nms_now <- names(dt)
  lower_now <- tolower(nms_now)
  area_idx <- which(lower_now == "cell: area")
  if (length(area_idx) > 0L) {
    data.table::setnames(dt, nms_now[area_idx[1L]], "cell_area")
  }
  nuc_area_idx <- which(lower_now == "nucleus: area")
  if (length(nuc_area_idx) > 0L) {
    data.table::setnames(dt, nms_now[nuc_area_idx[1L]], "nucleus_area")
  }

  # --- Build marker intensity columns ---
  nms_now <- names(dt)
  markers <- .get_markers_full(nms_now)
  if (length(markers) == 0L) {
    warning("No marker intensity columns detected.", call. = FALSE)
    return(dt)
  }

  for (mk in markers) {
    col <- .intensity_col(names(dt), mk, compartment, statistic)
    if (!is.na(col) && col %in% names(dt)) {
      data.table::setnames(dt, col, mk)
    }
  }

  # Drop remaining raw compartment intensity columns
  remaining <- names(dt)
  drop_pat <- "^(Nucleus|Cell|Cytoplasm): .+ (mean|sum|std dev|max|min|range)$"
  drop_cols <- remaining[grepl(drop_pat, remaining, ignore.case = TRUE)]
  if (length(drop_cols) > 0L) {
    dt[, (drop_cols) := NULL]
  }

  # Drop morphology columns
  morph_pat <- "^(Nucleus|Cell): (Perimeter|Circularity|Max caliper|Min caliper|Eccentricity)$"
  morph_drop <- names(dt)[grepl(morph_pat, names(dt), ignore.case = TRUE)]
  ratio_col <- names(dt)[grepl("area ratio", tolower(names(dt)))]
  drop_extra <- c(morph_drop, ratio_col)
  for (col_name in c("Object type", "Name", "ROI", "Image")) {
    idx <- which(tolower(names(dt)) == tolower(col_name))
    if (length(idx) > 0L) drop_extra <- c(drop_extra, names(dt)[idx])
  }
  drop_extra <- intersect(drop_extra, names(dt))
  if (length(drop_extra) > 0L) {
    dt[, (drop_extra) := NULL]
  }

  dt
}

#' Standardise QuPath minimal-format columns
#' @noRd
.standardise_minimal <- function(dt) {
  nms <- names(dt)
  lower <- tolower(nms)

  x_idx <- which(grepl("^centroid x", lower))
  y_idx <- which(grepl("^centroid y", lower))
  if (length(x_idx) == 0L || length(y_idx) == 0L) {
    stop("Could not find Centroid X / Centroid Y columns.", call. = FALSE)
  }
  data.table::setnames(dt, nms[x_idx[1L]], "x")
  data.table::setnames(dt, nms[y_idx[1L]], "y")

  dt[, cell_id := as.character(seq_len(.N))]

  # Rename "{Marker}: Cell: Mean" -> "{Marker}"
  markers <- .get_markers_minimal(names(dt))
  for (mk in markers) {
    old_name <- names(dt)[tolower(names(dt)) ==
                            tolower(paste0(mk, ": Cell: Mean"))]
    if (length(old_name) > 0L) {
      data.table::setnames(dt, old_name[1L], mk)
    }
  }

  dt
}

#' Standardise flat-format columns
#' @noRd
.standardise_processor <- function(dt) {
  nms <- names(dt)
  lower <- tolower(nms)

  id_pat <- which(lower %in% c("cell id", "cell_id", "cellid"))
  if (length(id_pat) > 0L) {
    data.table::setnames(dt, nms[id_pat[1L]], "cell_id")
  } else {
    dt[, cell_id := as.character(seq_len(.N))]
  }

  x_pat <- which(
    grepl("cell.*(x|centroid.*x|x.*pos)|^centroid.*x", lower) |
      lower %in% c("x", "x_position", "x position", "centroid x",
                    "centroid_x")
  )
  if (length(x_pat) > 0L) {
    data.table::setnames(dt, nms[x_pat[1L]], "x")
  }

  y_pat <- which(
    grepl("cell.*(y|centroid.*y|y.*pos)|^centroid.*y", lower) |
      lower %in% c("y", "y_position", "y position", "centroid y",
                    "centroid_y")
  )
  if (length(y_pat) > 0L) {
    data.table::setnames(dt, nms[y_pat[1L]], "y")
  }

  area_pat <- which(
    grepl("cell.*area|area.*px|area.*pixel", lower) |
      lower %in% c("cell_area", "area")
  )
  if (length(area_pat) > 0L) {
    data.table::setnames(dt, nms[area_pat[1L]], "cell_area")
  }

  if (!"x" %in% names(dt) || !"y" %in% names(dt)) {
    stop("Could not identify x and y coordinate columns.", call. = FALSE)
  }

  dt
}

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

#' Read Single-Cell Spatial Biology Data
#'
#' Reads cell segmentation CSV files from spatial biology imaging platforms or
#' image analysis software. The function auto-detects the column naming
#' convention, delimiter, and BOM encoding.
#'
#' Three input formats are supported:
#' \describe{
#'   \item{QuPath Full}{Contains \code{Object ID}, \code{Classification},
#'     multi-compartment marker intensities
#'     (Compartment: Marker statistic).}
#'   \item{QuPath Minimal}{Contains only spatial coordinates and
#'     Marker: Cell: Mean columns.}
#'   \item{Flat Format}{Contains \code{Cell ID}, \code{Cell X Position},
#'     \code{Cell Y Position}, and flat marker intensity columns.}
#' }
#'
#' @param path Character string. Path to a CSV file or a directory containing
#'   CSV files. When a directory is given, all \code{.csv} files are read and
#'   combined.
#' @param sample_id Character string or \code{NULL}. An identifier appended to
#'   each row. When \code{path} is a directory and \code{sample_id} is
#'   \code{NULL}, the file name (without extension) is used. For QuPath
#'   full-format files with an \code{Image} column, the scan identity is
#'   parsed automatically.
#' @param markers Character vector or \code{NULL}. If provided, only these
#'   marker columns are retained. Matching is case-insensitive.
#' @param compartment Character. For QuPath full-format data, which
#'   compartment to extract intensities from. One of \code{"Cell"} (default),
#'   \code{"Nucleus"}, or \code{"Cytoplasm"}.
#' @param statistic Character. For QuPath full-format data, which summary
#'   statistic to extract. One of \code{"mean"} (default), \code{"sum"},
#'   \code{"std dev"}, \code{"max"}, \code{"min"}, or \code{"range"}.
#' @param sep Character or \code{"auto"}. Column delimiter. Default
#'   \code{"auto"} detects comma vs. semicolon from the first line.
#'
#' @return A \code{data.table} with standardised column names:
#'   \describe{
#'     \item{sample_id}{Sample identifier.}
#'     \item{cell_id}{Unique cell identifier (per sample).}
#'     \item{x}{Cell centroid x-coordinate.}
#'     \item{y}{Cell centroid y-coordinate.}
#'     \item{cell_area}{Cell area (if available).}
#'     \item{classification}{Cell classification label (if available).}
#'   }
#'   Additional columns contain marker intensities (one per marker).
#'
#' @examples
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
#' dat <- read_spatial(tmp)
#' head(dat)
#' unlink(tmp)
#'
#' @export
read_spatial <- function(path, sample_id = NULL, markers = NULL,
                         compartment = "Cell", statistic = "mean",
                         sep = "auto") {
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
      .read_single(f, sid, markers, compartment, statistic, sep)
    })
    dt <- data.table::rbindlist(dts, use.names = TRUE, fill = TRUE)
  } else {
    sid <- if (is.null(sample_id)) {
      tools::file_path_sans_ext(basename(path))
    } else {
      sample_id
    }
    dt <- .read_single(path, sid, markers, compartment, statistic, sep)
  }

  dt
}

#' Read a single CSV file
#' @noRd
.read_single <- function(file, sample_id, markers, compartment, statistic,
                         sep) {
  if (identical(sep, "auto")) {
    sep <- .detect_sep(file)
  }

  dt <- data.table::fread(file, sep = sep, check.names = FALSE,
                          encoding = "UTF-8")

  fmt <- .detect_format(names(dt))
  dt <- switch(fmt,
    qupath_full = .standardise_qupath_full(dt, compartment, statistic),
    minimal     = .standardise_minimal(dt),
    processor   = .standardise_processor(dt)
  )

  if (!"sample_id" %in% names(dt)) {
    dt[, sample_id := sample_id]
  } else {
    na_rows <- is.na(dt$sample_id) | dt$sample_id == ""
    if (any(na_rows)) {
      dt[na_rows, sample_id := sample_id]
    }
  }

  if (!is.null(markers)) {
    markers_lower <- tolower(markers)
    meta_cols <- c("sample_id", "cell_id", "x", "y", "cell_area",
                   "nucleus_area", "classification", "parent")
    marker_cols <- names(dt)[tolower(names(dt)) %in% markers_lower]
    keep <- intersect(c(meta_cols, marker_cols), names(dt))
    dt <- dt[, keep, with = FALSE]
  }

  meta <- intersect(
    c("sample_id", "cell_id", "x", "y", "cell_area", "nucleus_area",
      "classification", "parent"),
    names(dt)
  )
  rest <- setdiff(names(dt), meta)
  data.table::setcolorder(dt, c(meta, rest))

  dt
}

#' Create a SpatialCellData Object from Existing Data
#'
#' Constructs a \code{\link{SpatialCellData-class}} object from a counts matrix,
#' coordinate data frame, and optional metadata.
#'
#' @param counts Numeric matrix (cells x markers). Row names are optional.
#' @param coords Data frame with columns \code{x} and \code{y}.
#' @param meta_data Data frame of per-cell metadata, or \code{NULL}.
#' @param sample_id Character. Sample identifier. Default \code{"sample1"}.
#' @param project Character. Project name. Default \code{"SpatialProject"}.
#'
#' @return A \code{\link{SpatialCellData-class}} object.
#'
#' @examples
#' counts <- matrix(rnorm(50), nrow = 10,
#'                  dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
#' coords <- data.frame(x = runif(10, 0, 500), y = runif(10, 0, 500))
#' obj <- CreateSpatialObject(counts, coords, sample_id = "mysample")
#' obj
#'
#' @export
CreateSpatialObject <- function(counts, coords, meta_data = NULL,
                                sample_id = "sample1",
                                project = "SpatialProject") {
  counts <- as.matrix(counts)
  coords <- as.data.frame(coords)
  n <- nrow(counts)

  # --- Marker-matrix robustness -------------------------------------------
  # Unnamed columns get stable default names; columns that are entirely NA are
  # dropped (they break normalisation and spatial statistics downstream).
  # Genuinely duplicated marker names are left for the validity check to reject,
  # since silently renaming them would mask a labelling error in the input.
  if (is.null(colnames(counts)) && ncol(counts) > 0L) {
    colnames(counts) <- paste0("M", seq_len(ncol(counts)))
  }
  all_na <- colSums(!is.na(counts)) == 0L
  if (any(all_na)) {
    warning("Dropping ", sum(all_na), " all-NA marker column(s): ",
            paste(colnames(counts)[all_na], collapse = ", "), ".",
            call. = FALSE)
    counts <- counts[, !all_na, drop = FALSE]
  }

  if (is.null(meta_data)) {
    meta_data <- data.frame(
      cell_id   = as.character(seq_len(n)),
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

  methods::new("SpatialCellData",
    counts    = counts,
    data      = counts,
    coords    = coords,
    meta_data = meta_data,
    project   = project,
    spatial   = list()
  )
}

#' Read Cell Segmentation Data into a SpatialCellData Object
#'
#' Reads cell segmentation CSV files and returns a
#' \code{\link{SpatialCellData-class}} object. This is the recommended
#' high-level entry point.
#'
#' @param path Character. Path to a CSV file or a directory containing CSV
#'   files.
#' @param sample_id Character or \code{NULL}. An identifier for the sample.
#' @param markers Character vector or \code{NULL}. If provided, only these
#'   marker columns are retained.
#' @param filter Character or \code{NA}. Regex pattern for marker names to
#'   exclude. Default \code{"DAPI|Blank|Empty"}.
#' @param compartment Character. Compartment for intensity extraction
#'   (QuPath full format). Default \code{"Cell"}.
#' @param statistic Character. Summary statistic to extract
#'   (QuPath full format). Default \code{"mean"}.
#' @param sep Character or \code{"auto"}. Column delimiter. Default
#'   \code{"auto"}.
#' @param project Character. Project name. Default \code{"SpatialProject"}.
#'
#' @return A \code{\link{SpatialCellData-class}} object.
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
#' obj <- ReadSpatial(tmp, filter = NA)
#' obj
#' unlink(tmp)
#'
#' @export
ReadSpatial <- function(path, sample_id = NULL, markers = NULL,
                        filter = "DAPI|Blank|Empty",
                        compartment = "Cell", statistic = "mean",
                        sep = "auto",
                        project = "SpatialProject") {
  dt <- read_spatial(path, sample_id = sample_id, markers = markers,
                     compartment = compartment, statistic = statistic,
                     sep = sep)

  if (!is.na(filter) && nzchar(filter)) {
    marker_cols <- .marker_columns(dt)
    drop <- marker_cols[grepl(filter, marker_cols, ignore.case = TRUE)]
    if (length(drop) > 0L) {
      dt[, (drop) := NULL]
    }
  }

  meta_names <- c("sample_id", "cell_id", "cell_area", "nucleus_area",
                  "classification", "parent")
  meta_cols <- intersect(meta_names, names(dt))
  marker_cols <- .marker_columns(dt)

  counts <- as.matrix(dt[, marker_cols, with = FALSE])
  coords <- data.frame(x = dt$x, y = dt$y)
  meta_data <- as.data.frame(dt[, meta_cols, with = FALSE])

  # Route through CreateSpatialObject so duplicate / all-NA marker handling and
  # the cell_id / sample_id defaults are applied in one shared place.
  CreateSpatialObject(counts, coords, meta_data = meta_data, project = project)
}
