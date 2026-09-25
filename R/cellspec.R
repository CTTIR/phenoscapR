#' Import a Canonical Cell Table Without Losing Spatial Identity
#'
#' Converts a validated cellspecR object to a SpatialCellData object. Each image
#' is an independent coordinate frame: output sample_id is image_id, while
#' source_sample_id preserves the original biological sample identifier.
#' Cell identifiers remain unchanged and are unique jointly with image_id.
#' Coordinates remain in micrometres and area remains in square micrometres;
#' calibration is validated but is not applied a second time.
#'
#' Feature identifiers retain their complete compartment/marker/statistic names.
#' No marker guessing, normalisation, filtering, imputation or removal of all-NA
#' features occurs. Functions requiring complete intensities need an explicit
#' downstream missing-feature policy. Existing phenotype metadata is preserved;
#' import does not verify or authorize review decisions.
#'
#' The metadata attribute cellspec_import holds an original-import snapshot of
#' dictionary, image/channel tables, input provenance, adjacency and raw feature
#' support. Its scope remains original_import after subsetting: adjacency and
#' support in this snapshot are not current subset results or active graphs.
#' No reviewed tissue window or observation area is inferred from cell centroids.
#'
#' @param x A structurally valid cellspec object. Requires cellspecR.
#' @param features Unique ordered feature identifiers, or NULL for all features.
#' @param project Character scalar naming the project.
#' @return A SpatialCellData object with unchanged selected measurements and
#'   explicit image-local sample IDs. Read provenance via
#'   attr(Meta(object), "cellspec_import").
#' @examples
#' if (requireNamespace("cellspecR", quietly = TRUE)) {
#'   object <- FromCellspec(cellspecR::cs_example())
#'   Coords(object)
#' }
#' @export
FromCellspec <- function(x, features = NULL, project = "SpatialProject") {
  if (!requireNamespace("cellspecR", quietly = TRUE)) {
    stop("FromCellspec requires the cellspecR package.", call. = FALSE)
  }
  cellspecR::cs_assert_valid(x)
  if (!is.character(project) || length(project) != 1L || is.na(project) ||
      !nzchar(trimws(project))) {
    stop("project must be one non-empty character value.", call. = FALSE)
  }
  if (is.null(features)) features <- x$dictionary$feature_id
  if (!is.character(features) || anyNA(features) || anyDuplicated(features) ||
      any(!features %in% x$dictionary$feature_id)) {
    stop("features must be unique known feature identifiers.", call. = FALSE)
  }
  meta <- x$cells
  if (!is.null(attr(meta, "cellspec_import", exact = TRUE))) {
    stop("Input already carries a cellspec_import snapshot.", call. = FALSE)
  }
  reserved <- intersect(c("source_sample_id", "cell_area"), names(meta))
  if (length(reserved)) {
    stop("Input metadata uses reserved import names: ",
         paste(reserved, collapse = ", "), ".", call. = FALSE)
  }
  meta$source_sample_id <- meta$sample_id
  meta$sample_id <- meta$image_id
  if ("area" %in% names(meta)) meta$cell_area <- meta$area
  if ("subject_id" %in% names(x$images)) {
    meta$subject_id <- x$images$subject_id[match(meta$image_id, x$images$image_id)]
  }
  selected <- match(features, x$dictionary$feature_id)
  attr(meta, "cellspec_import") <- list(
    scope = "original_import", source_n_cells = nrow(meta),
    coordinate_unit = "um", area_unit = "um2", frame_column = "image_id",
    selected_features = features, dictionary = x$dictionary,
    images = x$images, channels = x$channels, provenance = x$provenance,
    adjacency = x$adjacency,
    feature_support = cellspecR::cs_feature_support(x, features = features)
  )
  counts <- x$measurements[, selected, drop = FALSE]
  methods::new("SpatialCellData", counts = counts, data = counts,
               coords = meta[, c("x", "y"), drop = FALSE],
               meta_data = meta, project = project, spatial = list())
}
