#' Synthetic multiplexed-imaging example dataset
#'
#' A small, fully synthetic two-sample
#' [SpatialCellData][SpatialCellData-class] object used throughout the examples,
#' tests, and vignettes. It is simulated to resemble a multiplexed
#' immunofluorescence assay of tonsil tissue, with realistic spatial niche
#' structure so that the spatial statistics return meaningful, non-trivial
#' results.
#'
#' The data contain two samples (`"tonsil_A"`, `"tonsil_B"`), each built from six
#' cell populations placed in distinct spatial niches:
#' \itemize{
#'   \item a tight \strong{B-cell follicle},
#'   \item an overlapping \strong{T-cell zone} (helper, cytotoxic, and a few
#'     regulatory T cells),
#'   \item an \strong{epithelial/tumour} region, and
#'   \item scattered \strong{macrophages}.
#' }
#' Per-population marker intensities are drawn from log-normal distributions
#' anchored on canonical lineage markers, so unsupervised phenotyping and
#' neighbourhood-enrichment analyses recover the planted structure.
#'
#' @format A [SpatialCellData][SpatialCellData-class] object with 640 cells across 2 samples and 8
#'   markers (`CD3`, `CD4`, `CD8`, `CD20`, `CD68`, `PanCK`, `FoxP3`, `Ki67`).
#'   The `meta_data` slot carries `cell_id`, `sample_id`, `cell_area`, and a
#'   `phenotype_true` column recording the ground-truth population for each cell.
#'   Coordinates lie within a 1000 x 1000 (arbitrary unit) imaging window.
#'
#' @source Simulated by `data-raw/make_example_data.R` with `set.seed(2024)`.
#'   Entirely synthetic; not derived from any real specimen.
#'
#' @examples
#' data(phenoscapR_example)
#' phenoscapR_example
#' table(phenoscapR_example$sample_id, phenoscapR_example$phenotype_true)
"phenoscapR_example"
