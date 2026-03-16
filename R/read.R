#' Read Akoya Cell Segmentation Data
#'
#' Reads cell segmentation CSV files produced by Akoya Biosciences platforms
#' (PhenoCycler, CODEX, PhenoImager) or QuPath and returns an
#' \code{\link{AkoyaExperiment}} object. Supports three input formats
#' (\code{"processor"}, \code{"inform"}, \code{"qupath"}) as well as
#' automatic column detection.
#'
#' @param path Character. Path to a CSV file or a directory containing CSV
#'   files. When a directory is given, all \code{.csv} files are read and
#'   combined into a single object.
#' @param type Character. Input format: \code{"auto"} (default),
#'   \code{"processor"}, \code{"inform"}, or \code{"qupath"}.
#'   \code{"auto"} inspects column names to choose the correct parser.
#' @param sample_id Character or \code{NULL}. An identifier for the sample.
#'   When \code{path} is a directory and \code{sample_id} is \code{NULL}, the
#'   file name (without extension) is used.
#' @param markers Character vector or \code{NULL}. If provided, only these
#'   marker columns are retained. Matching is case-insensitive.
#' @param filter Character or \code{NA}. Regular expression pattern for
#'   marker names to exclude (e.g. \code{"DAPI|Blank|Empty"}). Set to
#'   \code{NA} to keep all markers. Default \code{"DAPI|Blank|Empty"}.
#' @param recursive Logical. When \code{path} is a directory, search
#'   subdirectories recursively? Default \code{TRUE}.
#' @param project Character. Project name stored in the object. Default
#'   \code{"AkoyaProject"}.
#'
#' @return An \code{\link{AkoyaExperiment}} object.
#'
#' @details
#' \strong{Format detection (\code{type = "auto"}):}
#' \itemize{
#'   \item \strong{processor}: columns contain \code{"cell_id:cell_id"} or
#'     start with \code{"cyc"}.
#'   \item \strong{inform}: tab-separated or contains \code{"Cell ID"} and
#'     \code{"Normalized Counts"} in column names.
#'   \item \strong{qupath}: columns contain \code{"Cell: "} or
#'     \code{"Centroid X"}.
#'   \item Falls back to generic auto-detection if no pattern matches.
#' }
#'
#' @examples
#' # Create a temporary example file
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
#' @importFrom data.table fread
#' @importFrom methods new validObject
ReadAkoya <- function(path, type = c("auto", "processor", "inform", "qupath"),
                      sample_id = NULL, markers = NULL,
                      filter = "DAPI|Blank|Empty",
                      recursive = TRUE,
                      project = "AkoyaProject") {
  type <- match.arg(type)
  if (!file.exists(path)) {
    stop("Path does not exist: ", path, call. = FALSE)
  }

  if (dir.exists(path)) {
    files <- list.files(path, pattern = "\\.csv$", full.names = TRUE,
                        ignore.case = TRUE, recursive = recursive)
    if (length(files) == 0L) {
      stop("No CSV files found in directory: ", path, call. = FALSE)
    }
    parts <- lapply(files, function(f) {
      sid <- if (is.null(sample_id)) {
        tools::file_path_sans_ext(basename(f))
      } else {
        sample_id
      }
      .parse_akoya_csv(f, sid, markers, filter, type)
    })
    counts <- do.call(rbind, lapply(parts, `[[`, "counts"))
    coords <- do.call(rbind, lapply(parts, `[[`, "coords"))
    meta   <- do.call(rbind, lapply(parts, `[[`, "meta"))
    rownames(counts) <- NULL
    rownames(coords) <- NULL
    rownames(meta) <- NULL
  } else {
    sid <- if (is.null(sample_id)) {
      tools::file_path_sans_ext(basename(path))
    } else {
      sample_id
    }
    parsed <- .parse_akoya_csv(path, sid, markers, filter, type)
    counts <- parsed$counts
    coords <- parsed$coords
    meta   <- parsed$meta
  }

  methods::new("AkoyaExperiment",
    counts    = counts,
    data      = counts,
    coords    = coords,
    meta_data = meta,
    project   = project,
    spatial   = list()
  )
}

#' Create an AkoyaExperiment from Existing Data
#'
#' Constructs an \code{\link{AkoyaExperiment}} from a counts matrix,
#' coordinate data frame, and optional metadata.
#'
#' @param counts Numeric matrix (cells x markers). Row names are optional.
#' @param coords Data frame with columns \code{x} and \code{y}.
#' @param meta_data Data frame of per-cell metadata, or \code{NULL}.
#' @param sample_id Character. Sample identifier. Default \code{"sample1"}.
#' @param project Character. Project name. Default \code{"AkoyaProject"}.
#'
#' @return An \code{\link{AkoyaExperiment}} object.
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
  n <- nrow(counts)

  if (!is.data.frame(coords)) coords <- as.data.frame(coords)
  if (!all(c("x", "y") %in% names(coords))) {
    stop("coords must contain columns 'x' and 'y'.", call. = FALSE)
  }

  if (is.null(meta_data)) {
    meta_data <- data.frame(
      cell_id   = seq_len(n),
      sample_id = rep(sample_id, n),
      stringsAsFactors = FALSE
    )
  } else {
    if (!"cell_id" %in% names(meta_data)) {
      meta_data$cell_id <- seq_len(n)
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

# --- Internal helpers --------------------------------------------------------

#' Parse a single Akoya CSV file
#' @noRd
.parse_akoya_csv <- function(file, sample_id, markers, filter, type) {
  # Detect separator for inform (tab-separated)
  first_line <- readLines(file, n = 1L, warn = FALSE)
  sep <- if (grepl("\t", first_line)) "\t" else ","

  raw <- data.table::fread(file, sep = sep, check.names = FALSE,
                           data.table = FALSE)
  nms <- names(raw)

  # Auto-detect type
  if (type == "auto") {
    type <- .detect_type(nms)
  }

  switch(type,
    processor = .parse_processor(raw, nms, sample_id, markers, filter),
    inform    = .parse_inform(raw, nms, sample_id, markers, filter),
    qupath    = .parse_qupath(raw, nms, sample_id, markers, filter),
    .parse_generic(raw, nms, sample_id, markers, filter)
  )
}

#' Detect Akoya format from column names
#' @noRd
.detect_type <- function(nms) {
  lower <- tolower(nms)
  if (any(grepl("cell_id:cell_id", lower)) || any(grepl("^cyc", lower))) {
    return("processor")
  }
  if (any(grepl("normalized counts", lower, fixed = TRUE))) {
    return("inform")
  }
  if (any(grepl("cell:.*mean", lower))) {
    return("qupath")
  }
  "auto"
}

#' Parse Akoya Processor format
#' @noRd
.parse_processor <- function(raw, nms, sample_id, markers, filter) {
  lower <- tolower(nms)

  # Coordinates
  x_col <- nms[match("x:x", lower)]
  y_col <- nms[match("y:y", lower)]
  if (is.na(x_col) || is.na(y_col)) {
    stop("Processor format requires 'x:x' and 'y:y' columns.", call. = FALSE)
  }
  coords <- data.frame(x = raw[[x_col]], y = raw[[y_col]])

  # Cell IDs
  id_col <- nms[match("cell_id:cell_id", lower)]
  cell_ids <- if (!is.na(id_col)) as.character(raw[[id_col]]) else seq_len(nrow(raw))
  rownames(raw) <- cell_ids

  # Metadata: non-cyc columns
  meta_idx <- which(!grepl("^cyc", lower))
  md <- raw[, meta_idx, drop = FALSE]
  colnames(md) <- vapply(strsplit(colnames(md), ":"), function(x) {
    if (length(x) > 1L) x[2L] else x[1L]
  }, character(1L))
  md$cell_id <- cell_ids
  md$sample_id <- sample_id

  # Expression matrix: cyc columns
  cyc_idx <- which(grepl("^cyc", lower))
  mtx <- raw[, cyc_idx, drop = FALSE]
  colnames(mtx) <- vapply(strsplit(colnames(mtx), ":"), function(x) {
    if (length(x) > 1L) x[2L] else x[1L]
  }, character(1L))

  # Filter
  if (!is.na(filter) && nzchar(filter)) {
    keep <- !grepl(filter, colnames(mtx), ignore.case = TRUE)
    mtx <- mtx[, keep, drop = FALSE]
  }

  # Marker subset
  if (!is.null(markers)) {
    markers_lower <- tolower(markers)
    keep <- tolower(colnames(mtx)) %in% markers_lower
    mtx <- mtx[, keep, drop = FALSE]
  }

  counts <- as.matrix(mtx)
  storage.mode(counts) <- "double"

  list(counts = counts, coords = coords, meta = md)
}

#' Parse Akoya inForm format
#' @noRd
.parse_inform <- function(raw, nms, sample_id, markers, filter,
                          quant = "mean") {
  quant_key <- c(mean = "Mean", total = "Total", min = "Min",
                 max = "Max", std = "Std Dev")
  expr_key <- quant_key[quant]
  expr_pattern <- "\\(Normalized Counts, Total Weighting\\)"

  # Cell IDs
  id_col <- .detect_col(nms, tolower(nms), c("cell id"))
  cell_ids <- if (!is.null(id_col)) as.character(raw[[id_col]]) else seq_len(nrow(raw))
  rownames(raw) <- cell_ids

  # Coordinates
  x_col <- .detect_col(nms, tolower(nms), c("cell x position"))
  y_col <- .detect_col(nms, tolower(nms), c("cell y position"))
  if (is.null(x_col) || is.null(y_col)) {
    stop("inForm format requires 'Cell X Position' and 'Cell Y Position'.",
         call. = FALSE)
  }
  coords <- data.frame(x = raw[[x_col]], y = raw[[y_col]])

  # Metadata: columns not matching expression pattern
  expr_cols <- grep(expr_pattern, nms, value = TRUE)
  pos_cols <- c(x_col, y_col, id_col)
  meta_cols <- setdiff(nms, c(expr_cols, pos_cols))
  md <- raw[, meta_cols, drop = FALSE]
  md$cell_id <- cell_ids
  md$sample_id <- sample_id

  # Expression: match quant + pattern
  target_cols <- grep(paste(expr_key, expr_pattern), nms, value = TRUE)
  if (length(target_cols) == 0L) {
    # Fallback: take all numeric columns not in metadata
    target_cols <- setdiff(nms, c(names(md), pos_cols))
    target_cols <- target_cols[vapply(target_cols, function(c) is.numeric(raw[[c]]), logical(1L))]
  }

  mtx <- raw[, target_cols, drop = FALSE]
  # Clean column names: extract marker name
  clean_names <- gsub(paste0(".*", expr_key, "\\s*"), "", colnames(mtx))
  clean_names <- gsub(expr_pattern, "", clean_names)
  clean_names <- trimws(clean_names)
  # Get last word and remove parens
  clean_names <- vapply(clean_names, function(x) {
    parts <- unlist(strsplit(x, " "))
    last <- parts[length(parts)]
    gsub("\\(|\\)", "", last)
  }, character(1L), USE.NAMES = FALSE)
  colnames(mtx) <- clean_names

  # Filter
  if (!is.na(filter) && nzchar(filter)) {
    keep <- !grepl(filter, colnames(mtx), ignore.case = TRUE)
    mtx <- mtx[, keep, drop = FALSE]
  }

  if (!is.null(markers)) {
    markers_lower <- tolower(markers)
    keep <- tolower(colnames(mtx)) %in% markers_lower
    mtx <- mtx[, keep, drop = FALSE]
  }

  counts <- as.matrix(mtx)
  storage.mode(counts) <- "double"

  list(counts = counts, coords = coords, meta = md)
}

#' Parse QuPath format
#' @noRd
.parse_qupath <- function(raw, nms, sample_id, markers, filter) {
  lower <- tolower(nms)

  # Cell IDs
  cell_ids <- as.character(seq_len(nrow(raw)))
  rownames(raw) <- cell_ids

  # Coordinates: Centroid X / Centroid Y
  x_candidates <- sort(grep("centroid x", nms, value = TRUE,
                             ignore.case = TRUE), decreasing = TRUE)
  y_candidates <- sort(grep("centroid y", nms, value = TRUE,
                             ignore.case = TRUE), decreasing = TRUE)
  if (length(x_candidates) == 0L || length(y_candidates) == 0L) {
    stop("QuPath format requires 'Centroid X' and 'Centroid Y' columns.",
         call. = FALSE)
  }
  x_col <- x_candidates[1L]
  y_col <- y_candidates[1L]
  coords <- data.frame(x = raw[[x_col]], y = raw[[y_col]])

  # Expression: "Cell: ... mean" columns
  expr_idx <- which(grepl("Cell:.*mean", nms, ignore.case = TRUE))
  if (length(expr_idx) == 0L) {
    # Fallback: try "mean" columns
    expr_idx <- which(grepl("mean", lower))
  }

  mtx <- raw[, expr_idx, drop = FALSE]
  # Clean column names
  colnames(mtx) <- gsub("[:/\\s]+", ".", colnames(mtx))
  colnames(mtx) <- gsub("\\.+", ".", colnames(mtx))
  colnames(mtx) <- gsub("^\\.|\\.$", "", colnames(mtx))

  # Metadata: everything else
  meta_idx <- setdiff(seq_along(nms), c(expr_idx, which(nms %in% c(x_col, y_col))))
  md <- raw[, meta_idx, drop = FALSE]
  md$cell_id <- cell_ids
  md$sample_id <- sample_id

  # Filter
  if (!is.na(filter) && nzchar(filter)) {
    keep <- !grepl(filter, colnames(mtx), ignore.case = TRUE)
    mtx <- mtx[, keep, drop = FALSE]
  }

  if (!is.null(markers)) {
    markers_lower <- tolower(markers)
    keep <- tolower(colnames(mtx)) %in% markers_lower
    mtx <- mtx[, keep, drop = FALSE]
  }

  counts <- as.matrix(mtx)
  storage.mode(counts) <- "double"

  list(counts = counts, coords = coords, meta = md)
}

#' Parse generic format (auto-detect columns)
#' @noRd
.parse_generic <- function(raw, nms, sample_id, markers, filter) {
  lower <- tolower(nms)

  # Identify metadata columns
  id_col   <- .detect_col(nms, lower, c("cell id", "cell_id", "object id",
                                         "object_id", "cellid"))
  x_col    <- .detect_col(nms, lower, c("cell x position", "cell_x_position",
                                         "x_position", "x position",
                                         "centroid x", "centroid_x", "x"))
  y_col    <- .detect_col(nms, lower, c("cell y position", "cell_y_position",
                                         "y_position", "y position",
                                         "centroid y", "centroid_y", "y"))
  area_col <- .detect_col(nms, lower, NULL,
                           pattern = "cell.*area|area.*px|area.*pixel|^area$")

  if (is.null(x_col) || is.null(y_col)) {
    if (is.null(x_col)) {
      x_idx <- grep("x.*pos|centroid.*x", lower)
      if (length(x_idx) > 0L) x_col <- nms[x_idx[1L]]
    }
    if (is.null(y_col)) {
      y_idx <- grep("y.*pos|centroid.*y", lower)
      if (length(y_idx) > 0L) y_col <- nms[y_idx[1L]]
    }
  }

  if (is.null(x_col) || is.null(y_col)) {
    stop("Could not identify x and y coordinate columns in the file.",
         call. = FALSE)
  }

  coords <- data.frame(x = raw[[x_col]], y = raw[[y_col]])

  cell_ids <- if (!is.null(id_col)) raw[[id_col]] else seq_len(nrow(raw))
  meta <- data.frame(cell_id = cell_ids, sample_id = sample_id,
                     stringsAsFactors = FALSE)
  if (!is.null(area_col)) {
    meta$cell_area <- raw[[area_col]]
  }

  # Marker columns: everything not identified as metadata
  meta_cols <- c(id_col, x_col, y_col, area_col)
  marker_idx <- which(!nms %in% meta_cols)
  is_num <- vapply(marker_idx, function(i) is.numeric(raw[[i]]), logical(1L))
  marker_idx <- marker_idx[is_num]

  # Filter
  if (!is.na(filter) && nzchar(filter)) {
    keep <- !grepl(filter, nms[marker_idx], ignore.case = TRUE)
    marker_idx <- marker_idx[keep]
  }

  if (!is.null(markers)) {
    markers_lower <- tolower(markers)
    marker_idx <- marker_idx[tolower(nms[marker_idx]) %in% markers_lower]
  }

  counts <- as.matrix(raw[, marker_idx, drop = FALSE])
  storage.mode(counts) <- "double"

  list(counts = counts, coords = coords, meta = meta)
}

#' Detect a column by exact match or pattern
#' @noRd
.detect_col <- function(nms, lower, exact_matches = NULL, pattern = NULL) {
  if (!is.null(exact_matches)) {
    idx <- which(lower %in% exact_matches)
    if (length(idx) > 0L) return(nms[idx[1L]])
  }
  if (!is.null(pattern)) {
    idx <- grep(pattern, lower)
    if (length(idx) > 0L) return(nms[idx[1L]])
  }
  NULL
}
