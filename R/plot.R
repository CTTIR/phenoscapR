#' Plot Cell Map
#'
#' Scatter plot of cell positions coloured by phenotype, cluster, or any
#' metadata column. Analogous to Seurat's \code{DimPlot} but in tissue
#' space.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param colour_by Character. Column name in \code{meta_data} to colour
#'   by. Default \code{"phenotype"}.
#' @param colours Named character vector or \code{NULL} for automatic
#'   colours via the global palette.
#' @param pt_size Numeric. Point size. Default \code{0.5}.
#' @param title Character or \code{NULL}. Plot title.
#' @param dark_theme Logical. Use a dark background (useful for tissue
#'   images). Default \code{FALSE}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0))
#' CellMap(obj)
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_point coord_fixed theme_minimal labs
#'   scale_colour_manual theme element_rect element_text element_blank .data
CellMap <- function(object, colour_by = "phenotype", colours = NULL,
                     pt_size = 0.5, title = NULL, dark_theme = FALSE) {
  if (!colour_by %in% names(object@meta_data)) {
    stop("Column '", colour_by, "' not found in meta_data.", call. = FALSE)
  }

  df <- data.frame(
    x = object@coords$x,
    y = object@coords$y,
    colour = object@meta_data[[colour_by]],
    stringsAsFactors = FALSE
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[["x"]], y = .data[["y"]], colour = .data[["colour"]]
  )) +
    ggplot2::geom_point(size = pt_size) +
    ggplot2::coord_fixed() +
    ggplot2::labs(x = "X", y = "Y", colour = colour_by, title = title)

  if (!is.null(colours)) {
    p <- p + ggplot2::scale_colour_manual(values = colours)
  } else {
    n_vals <- length(unique(df$colour))
    p <- p + .gg_discrete_scale("colour", n_vals)
  }

  if (dark_theme) {
    p <- p + .theme_dark_tissue()
  } else {
    p <- p + ggplot2::theme_minimal()
  }

  p
}

#' Feature Plot in Tissue Space
#'
#' Plots marker expression intensity on spatial coordinates. Each marker
#' gets its own panel. Similar to Seurat's \code{FeaturePlot} but in
#' tissue space.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param features Character vector. Marker names to plot.
#' @param slot Character. \code{"data"} or \code{"counts"}.
#' @param pt_size Numeric. Point size. Default \code{0.3}.
#' @param ncol Integer. Number of columns in the faceted layout. Default
#'   \code{NULL} (auto).
#' @param palette Character or character vector. Colour palette. Default
#'   \code{NULL} uses the global palette.
#' @param dark_theme Logical. Dark background. Default \code{FALSE}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(150), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8", "PanCK")))
#' coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
#' obj <- CreateSpatialObject(counts, coords)
#' FeaturePlot(obj, features = c("CD3", "CD8"))
#'
#' @export
#' @importFrom ggplot2 facet_wrap
FeaturePlot <- function(object, features, slot = "data", pt_size = 0.3,
                         ncol = NULL, palette = NULL, dark_theme = FALSE) {
  mat <- GetData(object, slot = slot)
  features <- intersect(features, colnames(mat))
  if (length(features) == 0L) {
    stop("No matching features found.", call. = FALSE)
  }

  df_list <- lapply(features, function(f) {
    data.frame(
      x = object@coords$x,
      y = object@coords$y,
      value = mat[, f],
      feature = f,
      stringsAsFactors = FALSE
    )
  })
  df <- do.call(rbind, df_list)

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[["x"]], y = .data[["y"]], colour = .data[["value"]]
  )) +
    ggplot2::geom_point(size = pt_size) +
    .gg_continuous_scale("colour", palette) +
    ggplot2::coord_fixed() +
    ggplot2::facet_wrap(~ feature, ncol = ncol) +
    ggplot2::labs(x = "X", y = "Y", colour = "Expression")

  if (dark_theme) {
    p <- p + .theme_dark_tissue()
  } else {
    p <- p + ggplot2::theme_minimal()
  }

  p
}

#' Violin Plot of Marker Expression
#'
#' Violin plot showing the distribution of marker expression across
#' phenotypes or other grouping variables.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param features Character vector. Marker names to plot.
#' @param group_by Character. Metadata column to group by. Default
#'   \code{"phenotype"}.
#' @param slot Character. \code{"data"} or \code{"counts"}.
#' @param colours Named character vector or \code{NULL}.
#' @param ncol Integer or \code{NULL}. Number of columns for facets.
#' @param pt_size Numeric. Jitter point size. \code{0} to hide. Default
#'   \code{0}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(c(rnorm(30, 5), rnorm(30, 1)), ncol = 2,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(30), y = runif(30))
#' meta <- data.frame(cell_id = 1:30, sample_id = "s1",
#'                    phenotype = rep(c("T cell", "Other"), each = 15))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' ViolinPlot(obj, features = c("CD3", "CD8"))
#'
#' @export
#' @importFrom ggplot2 geom_violin geom_jitter position_jitter
ViolinPlot <- function(object, features, group_by = "phenotype",
                        slot = "data", colours = NULL, ncol = NULL,
                        pt_size = 0) {
  if (!group_by %in% names(object@meta_data)) {
    stop("Column '", group_by, "' not found in meta_data.", call. = FALSE)
  }
  mat <- GetData(object, slot = slot)
  features <- intersect(features, colnames(mat))
  if (length(features) == 0L) {
    stop("No matching features found.", call. = FALSE)
  }

  groups <- object@meta_data[[group_by]]
  df_list <- lapply(features, function(f) {
    data.frame(
      group = groups,
      value = mat[, f],
      feature = f,
      stringsAsFactors = FALSE
    )
  })
  df <- do.call(rbind, df_list)

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[["group"]], y = .data[["value"]], fill = .data[["group"]]
  )) +
    ggplot2::geom_violin(scale = "width", trim = TRUE) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = group_by, y = "Expression", fill = group_by)

  if (pt_size > 0) {
    p <- p + ggplot2::geom_jitter(
      width = 0.2, size = pt_size, alpha = 0.3,
      show.legend = FALSE
    )
  }

  if (length(features) > 1L) {
    p <- p + ggplot2::facet_wrap(~ feature, ncol = ncol, scales = "free_y")
  }

  if (!is.null(colours)) {
    p <- p + ggplot2::scale_fill_manual(values = colours)
  } else {
    n_groups <- length(unique(groups))
    p <- p + .gg_discrete_scale("fill", n_groups)
  }

  p
}

#' Box Plot of Marker Expression
#'
#' Box plot showing the distribution of marker expression across
#' phenotypes or other grouping variables.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param features Character vector. Marker names to plot.
#' @param group_by Character. Metadata column to group by. Default
#'   \code{"phenotype"}.
#' @param slot Character. \code{"data"} or \code{"counts"}.
#' @param colours Named character vector or \code{NULL}.
#' @param ncol Integer or \code{NULL}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(c(rnorm(30, 5), rnorm(30, 1)), ncol = 2,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(30), y = runif(30))
#' meta <- data.frame(cell_id = 1:30, sample_id = "s1",
#'                    phenotype = rep(c("T cell", "Other"), each = 15))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' BoxPlot(obj, features = c("CD3", "CD8"))
#'
#' @export
#' @importFrom ggplot2 geom_boxplot
BoxPlot <- function(object, features, group_by = "phenotype",
                     slot = "data", colours = NULL, ncol = NULL) {
  if (!group_by %in% names(object@meta_data)) {
    stop("Column '", group_by, "' not found in meta_data.", call. = FALSE)
  }
  mat <- GetData(object, slot = slot)
  features <- intersect(features, colnames(mat))
  if (length(features) == 0L) {
    stop("No matching features found.", call. = FALSE)
  }

  groups <- object@meta_data[[group_by]]
  df_list <- lapply(features, function(f) {
    data.frame(
      group = groups,
      value = mat[, f],
      feature = f,
      stringsAsFactors = FALSE
    )
  })
  df <- do.call(rbind, df_list)

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[["group"]], y = .data[["value"]], fill = .data[["group"]]
  )) +
    ggplot2::geom_boxplot(outlier.size = 0.5) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = group_by, y = "Expression", fill = group_by)

  if (length(features) > 1L) {
    p <- p + ggplot2::facet_wrap(~ feature, ncol = ncol, scales = "free_y")
  }

  if (!is.null(colours)) {
    p <- p + ggplot2::scale_fill_manual(values = colours)
  } else {
    n_groups <- length(unique(groups))
    p <- p + .gg_discrete_scale("fill", n_groups)
  }

  p
}

#' Dot Plot of Marker Expression
#'
#' Dot plot where dot size represents the percentage of cells expressing a
#' marker (above a threshold) and colour represents the mean expression.
#' Analogous to Seurat's \code{DotPlot}.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param features Character vector. Marker names to plot.
#' @param group_by Character. Metadata column to group by. Default
#'   \code{"phenotype"}.
#' @param slot Character. \code{"data"} or \code{"counts"}.
#' @param threshold Numeric. Expression threshold to call a cell
#'   "expressing". Default \code{0}.
#' @param palette Character or character vector. Colour palette for mean
#'   expression. Default \code{NULL} (global palette).
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(c(rnorm(60, 5), rnorm(60, 0)), ncol = 4,
#'                  dimnames = list(NULL, c("CD3", "CD8", "CD20", "PanCK")))
#' coords <- data.frame(x = runif(30), y = runif(30))
#' meta <- data.frame(cell_id = 1:30, sample_id = "s1",
#'                    phenotype = rep(c("T cell", "B cell", "Other"), each = 10))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' DotPlot(obj, features = c("CD3", "CD8", "CD20", "PanCK"))
#'
#' @export
#' @importFrom ggplot2 scale_size_continuous
DotPlot <- function(object, features, group_by = "phenotype",
                     slot = "data", threshold = 0, palette = NULL) {
  if (!group_by %in% names(object@meta_data)) {
    stop("Column '", group_by, "' not found in meta_data.", call. = FALSE)
  }
  mat <- GetData(object, slot = slot)
  features <- intersect(features, colnames(mat))
  if (length(features) == 0L) {
    stop("No matching features found.", call. = FALSE)
  }

  groups <- object@meta_data[[group_by]]
  grp_levels <- sort(unique(groups))

  records <- list()
  for (f in features) {
    for (g in grp_levels) {
      vals <- mat[groups == g, f]
      records[[length(records) + 1L]] <- data.frame(
        feature = f,
        group = g,
        avg_exp = mean(vals, na.rm = TRUE),
        pct_exp = 100 * mean(vals > threshold, na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    }
  }
  df <- do.call(rbind, records)
  df$feature <- factor(df$feature, levels = features)

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[["feature"]], y = .data[["group"]],
    size = .data[["pct_exp"]], colour = .data[["avg_exp"]]
  )) +
    ggplot2::geom_point() +
    .gg_continuous_scale("colour", palette, name = "Mean\nExpression") +
    ggplot2::scale_size_continuous(range = c(0, 8), name = "% Expressing") +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Marker", y = group_by) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  p
}

#' Stacked Bar Plot of Phenotype Composition
#'
#' Stacked bar plot showing the proportion or count of each phenotype
#' within each sample (or other grouping variable). Matches the stacked
#' bar composition plots from the images.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object with a
#'   \code{phenotype} column.
#' @param group_by Character. Metadata column for the x-axis grouping.
#'   Default \code{"sample_id"}.
#' @param proportion Logical. Show proportions instead of counts? Default
#'   \code{TRUE}.
#' @param colours Named character vector or \code{NULL}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' meta <- data.frame(cell_id = 1:50,
#'                    sample_id = rep(c("S1", "S2"), each = 25),
#'                    phenotype = sample(c("T cell", "B cell", "Mac"), 50, TRUE))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' CompositionPlot(obj)
#'
#' @export
#' @importFrom ggplot2 geom_bar position_fill
CompositionPlot <- function(object, group_by = "sample_id",
                              proportion = TRUE, colours = NULL) {
  md <- object@meta_data
  if (!"phenotype" %in% names(md)) {
    stop("No 'phenotype' column. Run PhenotypeCells() first.", call. = FALSE)
  }
  if (!group_by %in% names(md)) {
    stop("Column '", group_by, "' not found in meta_data.", call. = FALSE)
  }

  df <- data.frame(
    group = md[[group_by]],
    phenotype = md$phenotype,
    stringsAsFactors = FALSE
  )

  pos <- if (proportion) ggplot2::position_fill() else "stack"
  y_lab <- if (proportion) "Proportion" else "Count"

  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[["group"]], fill = .data[["phenotype"]]
  )) +
    ggplot2::geom_bar(position = pos) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = group_by, y = y_lab, fill = "Phenotype") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  if (!is.null(colours)) {
    p <- p + ggplot2::scale_fill_manual(values = colours)
  } else {
    n_pheno <- length(unique(df$phenotype))
    p <- p + .gg_discrete_scale("fill", n_pheno)
  }

  p
}

#' Ridge Plot of Marker Expression
#'
#' Ridge (joy) plot showing the distribution of marker expression for
#' each group. Implemented with overlapping density plots.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param features Character vector. Marker names to plot.
#' @param group_by Character. Metadata column to group by. Default
#'   \code{"phenotype"}.
#' @param slot Character. \code{"data"} or \code{"counts"}.
#' @param colours Named character vector or \code{NULL}.
#' @param ncol Integer or \code{NULL}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(c(rnorm(30, 5), rnorm(30, 1)), ncol = 2,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(30), y = runif(30))
#' meta <- data.frame(cell_id = 1:30, sample_id = "s1",
#'                    phenotype = rep(c("T cell", "Other"), each = 15))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' RidgePlot(obj, features = "CD3")
#'
#' @export
#' @importFrom ggplot2 geom_density
RidgePlot <- function(object, features, group_by = "phenotype",
                       slot = "data", colours = NULL, ncol = NULL) {
  if (!group_by %in% names(object@meta_data)) {
    stop("Column '", group_by, "' not found in meta_data.", call. = FALSE)
  }
  mat <- GetData(object, slot = slot)
  features <- intersect(features, colnames(mat))
  if (length(features) == 0L) {
    stop("No matching features found.", call. = FALSE)
  }

  groups <- object@meta_data[[group_by]]
  df_list <- lapply(features, function(f) {
    data.frame(
      group = groups,
      value = mat[, f],
      feature = f,
      stringsAsFactors = FALSE
    )
  })
  df <- do.call(rbind, df_list)

  # Horizontal density distributions per group (ridge-style)
  p <- ggplot2::ggplot(df, ggplot2::aes(
    x = .data[["value"]], fill = .data[["group"]],
    colour = .data[["group"]]
  )) +
    ggplot2::geom_density(alpha = 0.5, trim = TRUE) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Expression", y = "Density", fill = group_by,
                  colour = group_by)

  if (length(features) > 1L) {
    p <- p + ggplot2::facet_wrap(~ feature, ncol = ncol, scales = "free_x")
  }

  if (!is.null(colours)) {
    p <- p + ggplot2::scale_fill_manual(values = colours)
  } else {
    n_groups <- length(unique(groups))
    p <- p + .gg_discrete_scale("fill", n_groups)
  }

  p
}

#' Plot Cell Density
#'
#' Scatter plot with colour scaled by local cell density. Requires
#' \code{\link{CellDensity}} to have been run.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object with a
#'   \code{density} column.
#' @param pt_size Numeric. Point size. Default \code{1}.
#' @param title Character or \code{NULL}.
#' @param palette Character or character vector. Default \code{NULL}
#'   (global palette).
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- CellDensity(obj, radius = 20)
#' DensityPlot(obj)
#'
#' @export
DensityPlot <- function(object, pt_size = 1, title = NULL, palette = NULL) {
  if (!"density" %in% names(object@meta_data)) {
    stop("No 'density' column. Run CellDensity() first.", call. = FALSE)
  }

  df <- data.frame(
    x = object@coords$x,
    y = object@coords$y,
    density = object@meta_data$density
  )

  ggplot2::ggplot(df, ggplot2::aes(
    x = .data[["x"]], y = .data[["y"]], colour = .data[["density"]]
  )) +
    ggplot2::geom_point(size = pt_size) +
    .gg_continuous_scale("colour", palette, name = "Density") +
    ggplot2::coord_fixed() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "X", y = "Y", title = title)
}

#' Plot Spatial Interaction Heatmap
#'
#' Heatmap of pairwise spatial interaction scores between phenotypes.
#'
#' @param interactions Data frame as returned by
#'   \code{\link{InteractionMatrix}}.
#' @param title Character or \code{NULL}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' interactions <- data.frame(
#'   from = rep(c("CD3+", "CD8+"), each = 2),
#'   to = rep(c("CD3+", "CD8+"), 2),
#'   observed = c(50, 30, 25, 40),
#'   expected = rep(35, 4),
#'   interaction_score = log2(c(50, 30, 25, 40) / 35)
#' )
#' InteractionPlot(interactions)
#'
#' @export
#' @importFrom ggplot2 geom_tile scale_fill_gradient2
InteractionPlot <- function(interactions, title = NULL) {
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
#' Heatmap of mean marker intensity per phenotype. Analogous to Seurat's
#' \code{DoHeatmap}.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object with a
#'   \code{phenotype} column.
#' @param markers Character vector or \code{NULL}. Markers to include. If
#'   \code{NULL}, all markers are shown.
#' @param slot Character. Data slot to use: \code{"data"} (default) or
#'   \code{"counts"}.
#' @param palette Character or character vector. Default \code{NULL}
#'   (global palette).
#' @param title Character or \code{NULL}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(c(rnorm(30, 1), rnorm(30, 0), rnorm(30, 0),
#'                    rnorm(30, 1)), ncol = 2,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(60), y = runif(60))
#' meta <- data.frame(cell_id = 1:60, sample_id = "s1",
#'                    phenotype = rep(c("A", "B"), each = 30))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' MarkerHeatmap(obj)
#'
#' @export
MarkerHeatmap <- function(object, markers = NULL, slot = "data",
                           palette = NULL, title = NULL) {
  if (!"phenotype" %in% names(object@meta_data)) {
    stop("No 'phenotype' column. Run PhenotypeCells() first.", call. = FALSE)
  }

  mat <- GetData(object, slot = slot)
  cols <- if (!is.null(markers)) intersect(markers, colnames(mat)) else colnames(mat)
  if (length(cols) == 0L) stop("No marker columns found.", call. = FALSE)

  mat <- mat[, cols, drop = FALSE]
  pheno <- object@meta_data$phenotype
  phenotypes <- sort(unique(pheno))

  means <- do.call(rbind, lapply(phenotypes, function(ph) {
    colMeans(mat[pheno == ph, , drop = FALSE], na.rm = TRUE)
  }))
  rownames(means) <- phenotypes

  long <- data.frame(
    phenotype = rep(phenotypes, times = length(cols)),
    marker    = rep(cols, each = length(phenotypes)),
    value     = as.vector(means),
    stringsAsFactors = FALSE
  )

  ggplot2::ggplot(long, ggplot2::aes(
    x = .data[["marker"]], y = .data[["phenotype"]],
    fill = .data[["value"]]
  )) +
    ggplot2::geom_tile() +
    .gg_continuous_scale("fill", palette, name = "Mean\nIntensity") +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Marker", y = "Phenotype", title = title) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

#' Plot Spatial Network
#'
#' Plots cells as circles connected by edges from Delaunay triangulation
#' or nearest-neighbour graph, coloured by phenotype. Matches the
#' network visualisation style with coloured nodes on dark background.
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param edges Data frame with columns \code{from} and \code{to}
#'   (row indices), as returned by \code{\link{DelaunayNetwork}} or
#'   \code{\link{FindNeighbours}}. If \code{NULL} and the spatial slot
#'   contains \code{delaunay_edges}, those are used.
#' @param colour_by Character. Metadata column for node colour. Default
#'   \code{"phenotype"}.
#' @param colours Named character vector or \code{NULL}.
#' @param pt_size Numeric. Node size. Default \code{2}.
#' @param edge_alpha Numeric. Edge transparency. Default \code{0.15}.
#' @param edge_colour Character. Edge colour. Default \code{"grey60"}.
#' @param dark_theme Logical. Default \code{TRUE}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
#' meta <- data.frame(cell_id = 1:50, sample_id = "s1",
#'                    phenotype = sample(c("A", "B"), 50, TRUE))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' obj <- DelaunayNetwork(obj)
#' SpatialNetworkPlot(obj)
#'
#' @export
#' @importFrom ggplot2 geom_segment
SpatialNetworkPlot <- function(object, edges = NULL, colour_by = "phenotype",
                                colours = NULL, pt_size = 2,
                                edge_alpha = 0.15, edge_colour = "grey60",
                                dark_theme = TRUE) {
  if (is.null(edges)) {
    edges <- object@spatial$delaunay_edges
  }
  if (is.null(edges)) {
    stop("No edges found. Run DelaunayNetwork() first or provide edges.",
         call. = FALSE)
  }
  if (!colour_by %in% names(object@meta_data)) {
    stop("Column '", colour_by, "' not found in meta_data.", call. = FALSE)
  }

  xy <- object@coords
  edge_df <- data.frame(
    x    = xy$x[edges$from],
    y    = xy$y[edges$from],
    xend = xy$x[edges$to],
    yend = xy$y[edges$to]
  )

  node_df <- data.frame(
    x = xy$x,
    y = xy$y,
    colour = object@meta_data[[colour_by]],
    stringsAsFactors = FALSE
  )

  p <- ggplot2::ggplot() +
    ggplot2::geom_segment(
      data = edge_df,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   xend = .data[["xend"]], yend = .data[["yend"]]),
      colour = edge_colour, alpha = edge_alpha
    ) +
    ggplot2::geom_point(
      data = node_df,
      ggplot2::aes(x = .data[["x"]], y = .data[["y"]],
                   colour = .data[["colour"]]),
      size = pt_size
    ) +
    ggplot2::coord_fixed() +
    ggplot2::labs(colour = colour_by, x = "X", y = "Y")

  if (!is.null(colours)) {
    p <- p + ggplot2::scale_colour_manual(values = colours)
  } else {
    n_vals <- length(unique(node_df$colour))
    p <- p + .gg_discrete_scale("colour", n_vals)
  }

  if (dark_theme) {
    p <- p + .theme_dark_tissue()
  } else {
    p <- p + ggplot2::theme_minimal()
  }

  p
}

#' Histogram of Marker Expression
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param feature Character. Single marker name.
#' @param group_by Character or \code{NULL}. Metadata column for
#'   fill grouping.
#' @param slot Character. \code{"data"} or \code{"counts"}.
#' @param bins Integer. Number of bins. Default \code{50}.
#' @param colours Named character vector or \code{NULL}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' obj <- CreateSpatialObject(counts, coords)
#' HistogramPlot(obj, feature = "CD3")
#'
#' @export
#' @importFrom ggplot2 geom_histogram
HistogramPlot <- function(object, feature, group_by = NULL,
                            slot = "data", bins = 50L, colours = NULL) {
  mat <- GetData(object, slot = slot)
  if (!feature %in% colnames(mat)) {
    stop("Feature '", feature, "' not found.", call. = FALSE)
  }

  df <- data.frame(value = mat[, feature])

  if (!is.null(group_by) && group_by %in% names(object@meta_data)) {
    df$group <- object@meta_data[[group_by]]
    p <- ggplot2::ggplot(df, ggplot2::aes(
      x = .data[["value"]], fill = .data[["group"]]
    )) +
      ggplot2::geom_histogram(bins = bins, alpha = 0.7,
                               position = "identity") +
      ggplot2::labs(fill = group_by)
    if (!is.null(colours)) {
      p <- p + ggplot2::scale_fill_manual(values = colours)
    } else {
      p <- p + .gg_discrete_scale("fill", length(unique(df$group)))
    }
  } else {
    p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[["value"]])) +
      ggplot2::geom_histogram(bins = bins, fill = "steelblue", alpha = 0.8)
  }

  p + ggplot2::theme_minimal() +
    ggplot2::labs(x = feature, y = "Count")
}

#' QC Scatter Plot
#'
#' Scatter plot of two QC metrics (e.g. cell area vs total intensity).
#'
#' @param object An \code{\link[=SpatialCellData-class]{SpatialCellData}} object.
#' @param x Character. Metadata column for x-axis.
#' @param y Character. Metadata column for y-axis.
#' @param colour_by Character or \code{NULL}. Metadata column for colour.
#' @param pt_size Numeric. Default \code{0.5}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' meta <- data.frame(cell_id = 1:50, sample_id = "s1",
#'                    cell_area = runif(50, 10, 500))
#' obj <- CreateSpatialObject(counts, coords, meta)
#' QCPlot(obj, x = "cell_area", y = "cell_id")
#'
#' @export
QCPlot <- function(object, x, y, colour_by = NULL, pt_size = 0.5) {
  md <- object@meta_data
  if (!x %in% names(md)) stop("Column '", x, "' not found.", call. = FALSE)
  if (!y %in% names(md)) stop("Column '", y, "' not found.", call. = FALSE)

  df <- data.frame(xval = md[[x]], yval = md[[y]])

  if (!is.null(colour_by) && colour_by %in% names(md)) {
    df$col <- md[[colour_by]]
    p <- ggplot2::ggplot(df, ggplot2::aes(
      x = .data[["xval"]], y = .data[["yval"]], colour = .data[["col"]]
    ))
  } else {
    p <- ggplot2::ggplot(df, ggplot2::aes(
      x = .data[["xval"]], y = .data[["yval"]]
    ))
  }

  p + ggplot2::geom_point(size = pt_size, alpha = 0.5) +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = x, y = y, colour = colour_by)
}

# --- Internal helpers --------------------------------------------------------

#' Dark theme for tissue plots
#' @noRd
#' @importFrom ggplot2 theme element_rect element_text element_blank
.theme_dark_tissue <- function() {
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "black", colour = NA),
    panel.background = ggplot2::element_rect(fill = "black", colour = NA),
    panel.grid = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(colour = "grey70"),
    axis.title = ggplot2::element_text(colour = "grey80"),
    legend.background = ggplot2::element_rect(fill = "black"),
    legend.text = ggplot2::element_text(colour = "grey80"),
    legend.title = ggplot2::element_text(colour = "grey80"),
    plot.title = ggplot2::element_text(colour = "white")
  )
}
