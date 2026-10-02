#' Summarize Cell Annotations Within Fixed Grids
#'
#' Joins annotations by sample and cell key, never by row position or coordinates.
#' Counts only supplied memberships, retaining each sample separately. Unobserved
#' grid bins and unobserved categories are not manufactured as zeros. Additional
#' annotation rows outside the membership are allowed and ignored.
#'
#' Logical indicators retain counts of TRUE, FALSE and unavailable (NA). Their
#' fraction is returned only for complete bins: any unavailable value makes the
#' fraction NA. Category NA is an explicit unavailable bucket, whose fraction is
#' the fraction of memberships with unknown category, not biological absence.
#' These are cell fractions, not tissue densities or patient-level replicates.
#' Supplied annotations do not establish biological identity or review authority.
#'
#' @param membership Data frame returned by [AssignFixedGrid()]. Each cell occurs
#'   at most once per setting and sample. Bin geometry and sample frames must be
#'   internally consistent. No coordinate transformation is performed.
#' @param annotations Data frame with unique character `sample_id`, `cell_id`
#'   keys and requested category/indicator columns. Every membership must match.
#' @param settings The explicit grid settings supplied to [AssignFixedGrid()].
#'   Size and all bounds must exactly match these settings and grid indices.
#' @param categories Character vector of unique category column names. Values
#'   must be character vectors; NA is permitted, but empty values are rejected.
#' @param indicators Character vector of unique logical indicator column names.
#'   NA is permitted. Names must be disjoint from categories and key columns.
#'
#' @return List of data frames: `bins` with geometry and `n_cells`, `categories`
#'   with bin keys, category column, value, count, fraction and known/unavailable
#'   status, and `indicators` with bin keys, indicator column, TRUE/FALSE/NA
#'   counts, fraction and COMPLETE/PARTIAL/UNAVAILABLE status. Results have
#'   deterministic ordering. Empty inputs return empty typed tables.
#' @examples
#' cells <- data.frame(cell_id = c("a", "b"), sample_id = "s",
#'   frame_id = "physical", x = c(1, 2), y = 0)
#' settings <- data.frame(setting_id = "g", size_um = 10,
#'   offset_x_um = 0, offset_y_um = 0)
#' frames <- data.frame(sample_id = "s", frame_id = "physical", unit = "um")
#' membership <- AssignFixedGrid(cells, settings, frames)
#' annotations <- data.frame(sample_id = "s", cell_id = c("a", "b"),
#'   type = c("A", "B"), signal = c(TRUE, NA))
#' SummarizeFixedGrid(membership, annotations, settings, "type", "signal")
#' @export
SummarizeFixedGrid <- function(membership, annotations, settings,
                               categories = character(), indicators = character()) {
  value <- n_cells <- n_cells_total <- n_unavailable <- n_true <- n_false <- NULL
  keys <- c("setting_id", "sample_id", "grid_x", "grid_y")
  geometry <- c("frame_id", "size_um", "xmin_um", "xmax_um", "ymin_um", "ymax_um")
  .exact_table(membership, c(keys, "cell_id", geometry), "membership")
  .exact_table(annotations, c("sample_id", "cell_id", categories, indicators),
               "annotations")
  valid_names <- function(x) {
    is.character(x) && !anyNA(x) && all(nzchar(trimws(x))) && !anyDuplicated(x)
  }
  .exact_assert(valid_names(categories) && valid_names(indicators),
                "Select unique column names")
  .exact_assert(!length(intersect(categories, indicators)) &&
                  !any(c(categories, indicators) %in% c("sample_id", "cell_id")),
                "Category, indicator and key columns must be disjoint")
  membership <- as.data.frame(membership)
  annotations <- as.data.frame(annotations)
  .exact_assert(!anyDuplicated(.exact_keys(membership,
    c("setting_id", "sample_id", "cell_id"))), "Duplicate membership key")
  .exact_keys(membership, "frame_id")
  annotation_keys <- .exact_keys(annotations, c("sample_id", "cell_id"))
  .exact_assert(!anyDuplicated(annotation_keys), "Duplicate annotation key")
  match_index <- match(.exact_keys(membership, c("sample_id", "cell_id")),
                       annotation_keys)
  .exact_assert(!anyNA(match_index), "Missing annotation for membership")
  for (name in c("grid_x", "grid_y")) {
    v <- membership[[name]]
    .exact_assert(is.numeric(v) && is.null(dim(v)) && all(is.finite(v)) &&
                    all(abs(v) <= .Machine$integer.max & v == trunc(v)),
                  "Membership requires finite integer grid indices")
  }
  for (name in geometry[-1]) {
    v <- membership[[name]]
    .exact_assert(is.numeric(v) && is.null(dim(v)) && all(is.finite(v)),
                  "Membership requires finite bin geometry")
  }
  .exact_assert(all(membership$size_um > 0 &
                    membership$xmin_um < membership$xmax_um &
                    membership$ymin_um < membership$ymax_um),
                "Membership requires positive size and increasing bin bounds")
  for (name in categories) {
    v <- annotations[[name]]
    .exact_assert(is.character(v) && is.null(dim(v)) &&
                    all(is.na(v) | nzchar(trimws(v))),
                  "Categories must be character values or NA")
  }
  for (name in indicators) {
    .exact_assert(is.logical(annotations[[name]]) &&
                    is.null(dim(annotations[[name]])), "Indicators must be logical")
  }
  .exact_table(settings, c("setting_id", "size_um", "offset_x_um", "offset_y_um"),
               "settings")
  settings <- as.data.frame(settings)
  .exact_assert(nrow(settings) > 0L &&
                  !anyDuplicated(.exact_keys(settings, "setting_id")),
                "Settings require unique IDs and at least one row")
  for (name in c("size_um", "offset_x_um", "offset_y_um")) {
    .exact_assert(is.numeric(settings[[name]]) && is.null(dim(settings[[name]])) &&
                    all(is.finite(settings[[name]])), "Settings require finite numeric values")
  }
  .exact_assert(all(settings$size_um > 0), "Settings require positive grid sizes")
  setting_index <- match(membership$setting_id, settings$setting_id)
  .exact_assert(!anyNA(setting_index), "Unknown membership setting")
  size <- settings$size_um[setting_index]
  .exact_assert(all(membership$size_um == size), "Membership size differs from settings")
  for (axis in c("x", "y")) {
    offset <- settings[[paste0("offset_", axis, "_um")]][setting_index]
    index <- as.numeric(membership[[paste0("grid_", axis)]])
    lower <- offset + index * size
    upper <- offset + (index + 1) * size
    .exact_assert(all(is.finite(lower) & is.finite(upper)) &&
                    all(membership[[paste0(axis, "min_um")]] == lower &
                        membership[[paste0(axis, "max_um")]] == upper),
                  "Membership bounds differ from settings")
  }
  m <- data.table::as.data.table(membership[c(keys, "cell_id", geometry)])
  sample_frames <- unique(m[, c("sample_id", "frame_id"), with = FALSE])
  .exact_assert(!anyDuplicated(sample_frames$sample_id), "Conflicting sample frame")
  bin_geometry <- unique(m[, c(keys, geometry), with = FALSE])
  .exact_assert(!anyDuplicated(bin_geometry[, keys, with = FALSE]),
                "Conflicting bin geometry")
  bins <- m[, list(n_cells = .N), by = c(keys, geometry)]
  category_parts <- lapply(categories, function(name) {
    z <- data.table::copy(m[, keys, with = FALSE])
    z[, value := annotations[[name]][match_index]]
    z <- z[, list(n_cells = .N), by = c(keys, "value")]
    z <- merge(z, bins[, c(keys, "n_cells"), with = FALSE], by = keys,
               all.x = TRUE, sort = FALSE, suffixes = c("", "_total"))
    z[, `:=`(category = name, fraction = n_cells / n_cells_total,
              status = ifelse(is.na(value), "UNAVAILABLE", "KNOWN"))]
    z[, n_cells_total := NULL]
    data.table::setcolorder(z, c(keys, "category", "value", "n_cells", "fraction", "status"))
    z
  })
  indicator_parts <- lapply(indicators, function(name) {
    z <- data.table::copy(m[, keys, with = FALSE])
    z[, value := annotations[[name]][match_index]]
    z <- z[, list(n_true = sum(value %in% TRUE), n_false = sum(value %in% FALSE),
                  n_unavailable = sum(is.na(value))), by = keys]
    z[, `:=`(indicator = name,
      fraction_true = ifelse(n_unavailable == 0L, n_true / (n_true + n_false), NA_real_),
      status = ifelse(n_unavailable == 0L, "COMPLETE",
        ifelse(n_true + n_false == 0L, "UNAVAILABLE", "PARTIAL")))]
    data.table::setcolorder(z, c(keys, "indicator", "n_true", "n_false",
                               "n_unavailable", "fraction_true", "status"))
    z
  })
  empty_keys <- as.data.frame(m[0, keys, with = FALSE])
  category_table <- if (length(category_parts)) data.table::rbindlist(category_parts) else
    data.table::as.data.table(cbind(empty_keys, category = character(), value = character(),
      n_cells = integer(), fraction = numeric(), status = character()))
  indicator_table <- if (length(indicator_parts)) data.table::rbindlist(indicator_parts) else
    data.table::as.data.table(cbind(empty_keys, indicator = character(), n_true = integer(),
      n_false = integer(), n_unavailable = integer(), fraction_true = numeric(),
      status = character()))
  data.table::setorderv(bins, keys)
  data.table::setorderv(category_table, c(keys, "category", "value"), na.last = TRUE)
  data.table::setorderv(indicator_table, c(keys, "indicator"))
  list(bins = as.data.frame(bins), categories = as.data.frame(category_table),
       indicators = as.data.frame(indicator_table))
}
