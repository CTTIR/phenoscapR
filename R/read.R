#' Read Akoya Cell Segmentation Data
#'
#' Reads cell segmentation CSV files produced by Akoya Biosciences platforms
#' (PhenoCycler, CODEX, PhenoImager) and returns an
#' \code{\link{AkoyaExperiment}} object. Column names are auto-detected and
#' standardised.
#'
#' @param path Character. Path to a CSV file or a directory containing CSV
#'   files. When a directory is given, all \code{.csv} files are read and
#'   combined into a single object.
#' @param sample_id Character or \code{NULL}. An identifier for the sample.
#'   When \code{path} is a directory and \code{sample_id} is \code{NULL}, the
#'   file name (without extension) is used.
#' @param markers Character vector or \code{NULL}. If provided, only these
#'   marker columns are retained. Matching is case-insensitive.
#' @param project Character. Project name stored in the object. Default
#'   \code{"AkoyaProject"}.
#'
#' @return An \code{\link{AkoyaExperiment}} object.
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
#' obj <- ReadAkoya(tmp)
#' obj
#' unlink(tmp)
#'
#' @export
#' @importFrom data.table fread
#' @importFrom methods new validObject
ReadAkoya <- function(path, sample_id = NULL, markers = NULL,
                      project = "AkoyaProject") {
  if (!file.exists(path)) {
    stop("Path does not exist: ", path, call. = FALSE)
  }

  if (dir.exists(path)) {
    files <- list.files(path, pattern = "\\.csv$", full.names = TRUE,
                        ignore.case = TRUE)
    if (length(files) == 0L) {
      stop("No CSV files found in directory: ", path, call. = FALSE)
    }
    parts <- lapply(files, function(f) {
      sid <- if (is.null(sample_id)) {
        tools::file_path_sans_ext(basename(f))
      } else {
        sample_id
      }
      .parse_akoya_csv(f, sid, markers)
    })
    counts <- do.call(rbind, lapply(parts, `[[`, "counts"))
    coords <- do.call(rbind, lapply(parts, `[[`, "coords"))
    meta   <- do.call(rbind, lapply(parts, `[[`, "meta"))
    rownames(coords) <- NULL
    rownames(meta) <- NULL
  } else {
    sid <- if (is.null(sample_id)) {
      tools::file_path_sans_ext(basename(path))
    } else {
      sample_id
    }
    parsed <- .parse_akoya_csv(path, sid, markers)
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
.parse_akoya_csv <- function(file, sample_id, markers) {
  raw <- data.table::fread(file, check.names = FALSE, data.table = FALSE)
  nms <- names(raw)
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
    # Try regex fallback
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
    stop("Could not identify x and y coordinate columns in: ", file,
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
  # Keep only numeric columns
  is_num <- vapply(marker_idx, function(i) is.numeric(raw[[i]]), logical(1L))
  marker_idx <- marker_idx[is_num]

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
