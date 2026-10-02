#' Assign Physical Cell Coordinates to Fixed Square Grids
#'
#' Assigns every supplied cell independently in each setting. Bins are half-open
#' intervals: an exact boundary belongs to the bin on its positive side. Negative
#' coordinates use floor division. No rounding or tolerance is applied. Samples
#' remain separate even when coordinates overlap. Select eligible cells explicitly
#' before calling; this function does not filter, classify, or infer review status.
#'
#' The result describes detection locations, not tissue regions. Square bin area
#' is not observed tissue area and must not be used as an inferred tissue-density
#' denominator. Frame identifiers bind already calibrated coordinates; no unit,
#' origin, axis, crop or registration conversion is performed.
#'
#' @param cells Data frame with character `cell_id`, `sample_id`, `frame_id` and
#'   finite numeric `x`, `y` coordinates in micrometres. Keys are unique within
#'   each sample. An empty, correctly typed table is supported.
#' @param settings Nonempty data frame with unique character `setting_id`,
#'   positive finite numeric `size_um`, and finite numeric `offset_x_um`,
#'   `offset_y_um`. Each setting applies separately to every sample.
#' @param frames Data frame with unique character `sample_id`, character
#'   `frame_id` and character `unit`, which must be `"um"`. Each cell must match
#'   its sample's frame exactly. Extra frame rows are permitted.
#'
#' @return Data frame ordered by setting, sample and cell ID (radix order), with
#'   those keys, frame ID, integer grid indices, physical bounds and grid size.
#'   Bins are keyed by `(setting_id, sample_id, grid_x, grid_y)`, never coordinates
#'   alone. Unrepresentable bounds and indices outside the R integer range fail.
#'   Floating-point cancellation that produces bounds excluding an assigned cell
#'   also fails; no tolerance or silent coordinate correction is introduced.
#'   Extra input columns are ignored; inputs are not modified.
#' @examples
#' cells <- data.frame(cell_id = c("a", "b"), sample_id = "s",
#'   frame_id = "physical", x = c(-1, 10), y = c(0, 0))
#' settings <- data.frame(setting_id = "g", size_um = 10,
#'   offset_x_um = 0, offset_y_um = 0)
#' frames <- data.frame(sample_id = "s", frame_id = "physical", unit = "um")
#' AssignFixedGrid(cells, settings, frames)
#' @export
AssignFixedGrid <- function(cells, settings, frames) {
  .exact_table(cells, c("cell_id", "sample_id", "frame_id", "x", "y"), "cells")
  .exact_table(settings, c("setting_id", "size_um", "offset_x_um", "offset_y_um"),
               "settings")
  .exact_table(frames, c("sample_id", "frame_id", "unit"), "frames")
  # Convert data.table inputs before base column selection; never mutate callers.
  cells <- as.data.frame(cells)
  settings <- as.data.frame(settings)
  frames <- as.data.frame(frames)
  .exact_assert(!anyDuplicated(.exact_keys(cells, c("sample_id", "cell_id"))),
                "Duplicate cell within sample")
  .exact_keys(cells, "frame_id")
  .exact_assert(!anyDuplicated(.exact_keys(frames, "sample_id")),
                "Duplicate frame mapping for sample")
  .exact_keys(frames, "frame_id")
  .exact_assert(is.character(frames$unit) && !anyNA(frames$unit) &&
                  all(frames$unit == "um"), "Frames require micrometre units (um)")
  .exact_assert(nrow(settings) > 0L, "At least one setting is required")
  .exact_assert(!anyDuplicated(.exact_keys(settings, "setting_id")),
                "Duplicate setting ID")
  for (column in c("x", "y")) {
    .exact_assert(is.numeric(cells[[column]]) &&
                    all(is.finite(cells[[column]])),
                  "Coordinates must be finite numeric values")
  }
  .exact_assert(is.numeric(settings$size_um) &&
                  all(is.finite(settings$size_um) & settings$size_um > 0),
                "Grid sizes must be positive finite numeric values")
  for (column in c("offset_x_um", "offset_y_um")) {
    .exact_assert(is.numeric(settings[[column]]) &&
                    all(is.finite(settings[[column]])),
                  "Offsets must be finite numeric values")
  }
  frame_index <- match(cells$sample_id, frames$sample_id)
  .exact_assert(!anyNA(frame_index), "Unknown sample frame")
  .exact_assert(all(cells$frame_id == frames$frame_id[frame_index]),
                "Frame mismatch between cells and registry")
  cells <- cells[order(cells$sample_id, cells$cell_id, method = "radix"), ]
  settings <- settings[order(settings$setting_id, method = "radix"), ]
  template <- data.frame(setting_id = character(), sample_id = character(),
    cell_id = character(), frame_id = character(), grid_x = integer(),
    grid_y = integer(), size_um = numeric(), xmin_um = numeric(),
    xmax_um = numeric(), ymin_um = numeric(), ymax_um = numeric())
  if (!nrow(cells)) return(template)
  parts <- lapply(seq_len(nrow(settings)), function(i) {
    setting <- settings[i, ]
    size <- setting$size_um
    ox <- setting$offset_x_um
    oy <- setting$offset_y_um
    gx <- floor((cells$x - ox) / size)
    gy <- floor((cells$y - oy) / size)
    index_ok <- function(x) all(is.finite(x) & abs(x) <= .Machine$integer.max)
    .exact_assert(index_ok(gx) && index_ok(gy), "Grid index range exceeded")
    xmin <- ox + gx * size
    xmax <- ox + (gx + 1) * size
    ymin <- oy + gy * size
    ymax <- oy + (gy + 1) * size
    .exact_assert(all(is.finite(c(xmin, xmax, ymin, ymax))) &&
                    all(xmin < xmax) && all(ymin < ymax),
                  "Grid bounds are not representable at this precision")
    .exact_assert(all(cells$x >= xmin & cells$x < xmax) &&
                    all(cells$y >= ymin & cells$y < ymax),
                  "Rounded grid bounds do not contain assigned coordinates")
    data.frame(setting_id = setting$setting_id, sample_id = cells$sample_id,
      cell_id = cells$cell_id, frame_id = cells$frame_id,
      grid_x = as.integer(gx), grid_y = as.integer(gy), size_um = size,
      xmin_um = xmin, xmax_um = xmax, ymin_um = ymin, ymax_um = ymax)
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result
}
