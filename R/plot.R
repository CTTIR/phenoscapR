#' Plot Cell Map
#'
#' Scatter plot of cell positions coloured by phenotype, cluster, or any
#' metadata column. Analogous to Seurat's \code{DimPlot} but in tissue
#' space.
#'
#' @param object An \code{\link{AkoyaExperiment}} object.
#' @param colour_by Character. Column name in \code{meta_data} to colour
#'   by. Default \code{"phenotype"}.
#' @param colours Named character vector or \code{NULL} for automatic
#'   colours.
#' @param pt_size Numeric. Point size. Default \code{0.5}.
#' @param title Character or \code{NULL}. Plot title.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 500), y = runif(50, 0, 500))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0, CD8 = 0))
#' CellMap(obj)
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_point coord_fixed theme_minimal labs
#'   scale_colour_manual .data
CellMap <- function(object, colour_by = "phenotype", colours = NULL,
                     pt_size = 0.5, title = NULL) {
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
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "X", y = "Y", colour = colour_by, title = title)

  if (!is.null(colours)) {
    p <- p + ggplot2::scale_colour_manual(values = colours)
  }

  p
}

#' Plot Cell Density
#'
#' Scatter plot with colour scaled by local cell density. Requires
#' \code{\link{CellDensity}} to have been run.
#'
#' @param object An \code{\link{AkoyaExperiment}} object with a
#'   \code{density} column.
#' @param pt_size Numeric. Point size. Default \code{1}.
#' @param title Character or \code{NULL}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(100), nrow = 50,
#'                  dimnames = list(NULL, c("CD3", "CD8")))
#' coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
#' obj <- CreateAkoyaObject(counts, coords)
#' obj <- CellDensity(obj, radius = 20)
#' DensityPlot(obj)
#'
#' @export
#' @importFrom ggplot2 scale_fill_viridis_c scale_colour_viridis_c
DensityPlot <- function(object, pt_size = 1, title = NULL) {
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
    ggplot2::scale_colour_viridis_c() +
    ggplot2::coord_fixed() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "X", y = "Y", colour = "Density", title = title)
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
#' @param object An \code{\link{AkoyaExperiment}} object with a
#'   \code{phenotype} column.
#' @param markers Character vector or \code{NULL}. Markers to include. If
#'   \code{NULL}, all markers are shown.
#' @param slot Character. Data slot to use: \code{"data"} (default) or
#'   \code{"counts"}.
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
#' obj <- CreateAkoyaObject(counts, coords, meta)
#' MarkerHeatmap(obj)
#'
#' @export
MarkerHeatmap <- function(object, markers = NULL, slot = "data",
                           title = NULL) {
  if (!"phenotype" %in% names(object@meta_data)) {
    stop("No 'phenotype' column. Run PhenotypeCells() first.", call. = FALSE)
  }

  mat <- GetData(object, slot = slot)
  cols <- if (!is.null(markers)) intersect(markers, colnames(mat)) else colnames(mat)
  if (length(cols) == 0L) stop("No marker columns found.", call. = FALSE)

  mat <- mat[, cols, drop = FALSE]
  pheno <- object@meta_data$phenotype
  phenotypes <- sort(unique(pheno))

  # Compute mean per phenotype
  means <- do.call(rbind, lapply(phenotypes, function(ph) {
    colMeans(mat[pheno == ph, , drop = FALSE], na.rm = TRUE)
  }))
  rownames(means) <- phenotypes

  # Long format
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
    ggplot2::scale_fill_viridis_c() +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = "Marker", y = "Phenotype", fill = "Mean\nIntensity",
                  title = title)
}
