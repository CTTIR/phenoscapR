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

  p <- ggplot2::ggplot(dt, ggplot2::aes(
    x = .data[["x"]], y = .data[["y"]],
    colour = .data[[colour_by]]
  )) +
    ggplot2::geom_point(size = point_size) +
    ggplot2::coord_fixed() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "X", y = "Y", colour = colour_by, title = title)

  if (!is.null(colours)) {
    p <- p + ggplot2::scale_colour_manual(values = colours)
  }

  p
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

  ggplot2::ggplot(dt, ggplot2::aes(
    x = .data[["x"]], y = .data[["y"]],
    colour = .data[["density"]]
  )) +
    ggplot2::geom_point(size = point_size) +
    ggplot2::scale_colour_viridis_c() +
    ggplot2::coord_fixed() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "X", y = "Y", colour = "Density", title = title)
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
  ggplot2::ggplot(interactions, ggplot2::aes(
    x = .data[["to"]], y = .data[["from"]],
    fill = .data[["interaction_score"]]
  )) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_gradient2(
      low = "blue", mid = "white", high = "red", midpoint = 0,
      name = "log2(obs/exp)"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "To", y = "From", title = title)
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

  # Melt to long format
  long <- data.table::melt(agg, id.vars = "phenotype",
                           variable.name = "marker",
                           value.name = "mean_intensity")

  ggplot2::ggplot(long, ggplot2::aes(
    x = .data[["marker"]], y = .data[["phenotype"]],
    fill = .data[["mean_intensity"]]
  )) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_viridis_c() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Marker", y = "Phenotype", fill = "Mean\nIntensity",
                  title = title)
}
