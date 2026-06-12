#' Plot Cell Map
#'
#' Creates a scatter plot of cell positions, coloured by phenotype or cluster.
#'
#' @param dt A `data.table` with columns `x` and `y`.
#' @param colour_by Character string. Column name to colour cells by.
#'   Default `"phenotype"`.
#' @param colours Named character vector of colours, or `NULL` for automatic
#'   colours.
#' @param point_size Numeric. Size of plotted points. Default `0.5`.
#' @param title Character string or `NULL`. Plot title.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:50,
#'   x = runif(50, 0, 500), y = runif(50, 0, 500),
#'   phenotype = sample(c("CD3+", "CD8+", "Negative"), 50, replace = TRUE)
#' )
#' plot_cell_map(dt)
#'
#' @export
plot_cell_map <- function(dt, colour_by = "phenotype", colours = NULL,
                           point_size = 0.5, title = NULL) {
  if (!colour_by %in% names(dt)) {
    stop("Column '", colour_by, "' not found in data.", call. = FALSE)
  }

  df <- data.frame(x = dt$x, y = dt$y, colour = dt[[colour_by]],
                   stringsAsFactors = FALSE)
  .cell_map_plot(df, colour_by, colours, point_size, title,
                 dark_theme = FALSE)
}

#' Plot Density Map
#'
#' Creates a scatter plot with point size or colour scaled by local cell
#' density.
#'
#' @param dt A `data.table` with columns `x`, `y`, and `density` (as
#'   returned by [cell_density()]).
#' @param point_size Numeric. Base point size. Default `1`.
#' @param title Character string or `NULL`. Plot title.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:50,
#'   x = runif(50, 0, 100), y = runif(50, 0, 100),
#'   density = rpois(50, 5)
#' )
#' plot_density(dt)
#'
#' @export
plot_density <- function(dt, point_size = 1, title = NULL) {
  if (!"density" %in% names(dt)) {
    stop("Column 'density' not found. Run cell_density() first.",
         call. = FALSE)
  }

  df <- data.frame(x = dt$x, y = dt$y, density = dt$density)
  .density_plot(df, point_size, title)
}

#' Plot Interaction Heatmap
#'
#' Visualises the spatial interaction matrix as a heatmap.
#'
#' @param interactions A `data.table` as returned by [interaction_matrix()].
#' @param title Character string or `NULL`. Plot title.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' interactions <- data.table::data.table(
#'   from = rep(c("CD3+", "CD8+"), each = 2),
#'   to = rep(c("CD3+", "CD8+"), 2),
#'   observed = c(50, 30, 25, 40),
#'   expected = c(35, 35, 35, 35),
#'   interaction_score = log2(c(50, 30, 25, 40) / 35)
#' )
#' plot_interactions(interactions)
#'
#' @export
plot_interactions <- function(interactions, title = NULL) {
  # Identical to the SpatialCellData-level InteractionPlot(); delegate so the
  # interaction heatmap is defined in exactly one place.
  InteractionPlot(interactions, title = title)
}

#' Plot Marker Heatmap
#'
#' Displays a heatmap of mean marker intensities per phenotype.
#'
#' @param dt A `data.table` with marker columns and a `phenotype` column.
#' @param markers Character vector or `NULL`. Markers to include. If `NULL`,
#'   all marker columns are used.
#' @param title Character string or `NULL`. Plot title.
#'
#' @return A `ggplot` object.
#'
#' @examples
#' dt <- data.table::data.table(
#'   sample_id = "s1", cell_id = 1:60,
#'   x = runif(60), y = runif(60),
#'   CD3 = c(rnorm(30, 1), rnorm(30, 0)),
#'   CD8 = c(rnorm(30, 0), rnorm(30, 1)),
#'   phenotype = rep(c("CD3+", "CD8+"), each = 30)
#' )
#' plot_heatmap(dt)
#'
#' @export
plot_heatmap <- function(dt, markers = NULL, title = NULL) {
  if (!"phenotype" %in% names(dt)) {
    stop("Column 'phenotype' not found.", call. = FALSE)
  }

  cols <- if (!is.null(markers)) {
    intersect(markers, names(dt))
  } else {
    .marker_columns(dt)
  }

  if (length(cols) == 0L) {
    stop("No marker columns found.", call. = FALSE)
  }

  # Compute mean per phenotype
  agg <- dt[, lapply(.SD, mean, na.rm = TRUE),
            by = "phenotype", .SDcols = cols]

  # Melt to long format with the column names expected by the shared builder
  long <- data.table::melt(agg, id.vars = "phenotype",
                           variable.name = "marker",
                           value.name = "value")
  long$marker <- as.character(long$marker)

  .marker_heatmap_plot(as.data.frame(long), palette = NULL, title = title)
}
