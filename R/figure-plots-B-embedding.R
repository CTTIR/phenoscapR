# Embedding grammars: dense two-dimensional embeddings (for example UMAP)
# drawn as rasterised point layers, and per-group density outlines on the
# same coordinates.

# Display limits as c(xmin, xmax, ymin, ymax) from a numeric vector, a list
# or a one-row data frame with these columns.
.figb_limits <- function(limits) {
  if (is.null(limits)) return(NULL)
  if (is.data.frame(limits)) {
    .fig_require_columns(limits, c("xmin", "xmax", "ymin", "ymax"), "limits")
    return(as.numeric(limits[1, c("xmin", "xmax", "ymin", "ymax")]))
  }
  v <- as.numeric(unlist(limits))
  if (length(v) != 4L) stop("limits must be c(xmin, xmax, ymin, ymax).", call. = FALSE)
  v
}

# Values per key from a named vector/list, a data frame (key, value) or a
# scalar.
.figb_per_key <- function(spec, keys, default, column = NULL) {
  if (is.null(spec)) return(rep(default, length(keys)))
  if (is.data.frame(spec)) {
    vcol <- if (!is.null(column) && column %in% names(spec)) column else names(spec)[2L]
    spec <- stats::setNames(spec[[vcol]], as.character(spec[[1L]]))
  }
  if (is.list(spec)) spec <- unlist(spec)
  if (is.null(names(spec))) return(rep_len(spec, length(keys)))
  out <- spec[as.character(keys)]
  out[is.na(out)] <- default
  unname(out)
}

# Arrow axes (two short arrows from the lower left corner) or plain axis
# titles for an embedding without frame.
.figb_embedding_axes <- function(axis_style, titles, lim, style, arrow_fraction = 0.16,
                                 arrow_text_size = 4, title_size = 4.6, title_pad = 1.5) {
  if (axis_style == "none") return(list())
  k <- style$colour
  if (axis_style == "titles") {
    g <- .figb_deferred(function() list(
      .figb_text_grob(titles[1], grid::unit(0.5, "npc"), grid::unit(-title_pad, "pt"), title_size, k$ink,
                      style, hjust = 0.5, vjust = 1, typeset = FALSE),
      .figb_text_grob(titles[2], grid::unit(-title_pad, "pt"), grid::unit(0.5, "npc"), title_size, k$ink,
                      style, hjust = 0.5, vjust = 0, rot = 90, typeset = FALSE)
    ))
    return(list(.figb_annotation(g)))
  }
  xr <- lim[2] - lim[1]
  yr <- lim[4] - lim[3]
  x0 <- lim[1] + 0.02 * xr
  y0 <- lim[3] + 0.02 * yr
  d <- arrow_fraction * xr
  arrow <- grid::arrow(angle = 26.57, length = grid::unit(1.6, "pt"), type = "closed")
  seg <- data.frame(x = c(x0, x0), y = c(y0, y0), xend = c(x0 + d, x0), yend = c(y0, y0 + d))
  list(
    ggplot2::geom_segment(data = seg, ggplot2::aes(x = .data$x, y = .data$y, xend = .data$xend, yend = .data$yend),
                          colour = k$ink, arrow.fill = k$ink, linewidth = PtLinewidth(0.5), arrow = arrow,
                          linejoin = "mitre", inherit.aes = FALSE),
    ggplot2::annotate("text", x = x0 + d / 2, y = y0 - 0.012 * yr, label = titles[1], vjust = 1, hjust = 0.5,
                      size = .fig_text_size(arrow_text_size), colour = k$ink, family = style$family),
    ggplot2::annotate("text", x = x0 - 0.012 * xr, y = y0 + d / 2, label = titles[2], angle = 90, vjust = 0,
                      hjust = 0.5, size = .fig_text_size(arrow_text_size), colour = k$ink, family = style$family)
  )
}

#' Embedding Scatter
#'
#' Draws cells on two embedding coordinates (for example UMAP) as small
#' points without frame, coloured by a key (cell type, cluster,
#' neighbourhood). Points are drawn in layers in the order of the data rows,
#' as given by [EmbeddingLayers()], and rasterised at the style resolution so
#' that vector output stays small. Point sizes follow figure scatter areas
#' (squared points); individual keys can be drawn as diamonds with an
#' outline. Optional cluster labels with a white halo, arrow axes or plain
#' axis titles, and texts filled from plot data complete the panel.
#'
#' @param data Point data with coordinate and key columns.
#' @param x,y,key Column names.
#' @param limits Display limits `c(xmin, xmax, ymin, ymax)` or a one-row data
#'   frame with these columns (see [EmbeddingLimits()]).
#' @param subset Optional named list: keep rows whose columns take these
#'   values (for example one clinical group per panel).
#' @param colours Colours per key: named vector or list, or a data frame of
#'   key and colour.
#' @param default_colour Colour of keys without a colour.
#' @param sizes Scatter areas in squared points, one value or per key.
#' @param shapes Optional marker per key: `"o"` (circle) or `"D"` (diamond).
#' @param edge_colours,edge_widths Optional outline colour and width
#'   (points) per key.
#' @param labels Optional data frame of text labels (`label`, `x`, `y`), for
#'   example from [ClusterLabelPositions()], drawn bold with a white halo.
#' @param label_size,label_colour,halo Label size, colour and halo width.
#' @param axis_style `"none"`, `"arrows"` (two arrows in the lower left
#'   corner) or `"titles"` (axis titles beside the panel).
#' @param axis_titles Titles of the two axes.
#' @param arrow_fraction Arrow length as a fraction of the x range.
#' @param arrow_text_size,title_size,title_pad Text sizes and the distance of
#'   axis titles from the panel (points).
#' @param raster Rasterise the points (default) or draw vectors.
#' @param legend Optional legend: list of `keys`, `labels`, `at` (upper left
#'   corner in panel fractions), `ncol`, `size`, `marker_size` (points),
#'   `label_spacing`, `column_spacing`, `handle_text_pad`, `handle_length`
#'   (in font sizes), `title`, `title_size`, `title_align`, and optional
#'   `colours` and `shapes` overriding those of the points. Columns are
#'   filled first.
#' @param texts,values Free texts and template values, as in
#'   [PlotAnnotatedHeatmap()]; templates are filled from `values` restricted
#'   to `subset`, or from the subset data.
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' set.seed(1)
#' d <- data.frame(x = rnorm(500), y = rnorm(500), key = sample(c("a", "b"), 500, TRUE))
#' PlotEmbedding(d, limits = c(-4, 4, -4, 4), colours = c(a = "#e34948", b = "#2a78d6"),
#'               axis_style = "arrows", axis_titles = c("Dim 1", "Dim 2"))
#' @export
PlotEmbedding <- function(data, x = "x", y = "y", key = "key", limits = NULL, subset = NULL,
                          colours = NULL, default_colour = "#BBBBBB", sizes = 0.3, shapes = NULL, edge_colours = NULL,
                          edge_widths = NULL, labels = NULL, label_size = 4.2, label_colour = "ink",
                          halo = 0.6, axis_style = c("none", "arrows", "titles"),
                          axis_titles = c("UMAP 1", "UMAP 2"), arrow_fraction = 0.16,
                          arrow_text_size = 4, title_size = 4.6, title_pad = 1.5, raster = TRUE,
                          legend = NULL, texts = NULL, values = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  axis_style <- match.arg(axis_style)
  .fig_require_columns(data, c(x, y, key))
  d <- .figb_subset(as.data.frame(data), subset)
  lim <- .figb_limits(limits)
  if (is.null(lim)) lim <- c(range(d[[x]], finite = TRUE), range(d[[y]], finite = TRUE))
  keys <- as.character(d[[key]])
  col <- .figb_per_key(colours, keys, default_colour, "colour")
  col <- .fig_colour(col, style)
  size <- sqrt(as.numeric(.figb_per_key(sizes, keys, 0.3)))
  shape <- .figb_per_key(shapes, keys, "o")
  edge <- .figb_per_key(edge_colours, keys, NA)
  edge[!is.na(edge)] <- .fig_colour(edge[!is.na(edge)], style)
  ew <- as.numeric(.figb_per_key(edge_widths, keys, 0))
  pts <- .figb_points_grob(d[[x]], d[[y]], unname(col), size, lim[1:2], lim[3:4], shape = shape,
                           edge = edge, edge_width = ew, dpi = style$page$dpi, raster = raster)
  p <- .figb_canvas(lim[1:2], lim[3:4], style) + .figb_annotation(pts)
  if (!is.null(labels) && nrow(labels)) {
    .fig_require_columns(labels, c("label", "x", "y"), "labels")
    g <- .figb_halo_text(as.character(labels$label), grid::unit(labels$x, "native"),
                         grid::unit(labels$y, "native"), label_size, .fig_colour(label_colour, style),
                         halo = halo, family = style$family)
    g$vp <- grid::viewport(xscale = lim[1:2], yscale = lim[3:4])
    p <- p + .figb_annotation(grid::gTree(children = grid::gList(g)))
  }
  for (l in .figb_embedding_axes(axis_style, as.character(unlist(axis_titles)), lim, style, arrow_fraction,
                                 arrow_text_size, title_size, title_pad)) p <- p + l
  if (!is.null(legend)) p <- p + .figb_annotation(.figb_marker_key(legend, colours, shapes, style))
  if (!is.null(texts)) p <- p + .figb_texts_layer(texts, .figb_template_values(values, d, subset), style)
  p
}

#' Density Outlines on an Embedding
#'
#' Draws, for each group (for example each patient), the region of the
#' embedding inside a density level as a lightly filled area with an
#' outline, as computed by [DensityLevelContour()]. Each group takes the
#' colour of its slot; a compact key of line segments with the group labels
#' is set centred below the panel.
#'
#' @param data Contour data from [DensityLevelContour()]: the group column,
#'   `slot`, `label`, `kind` (`"band"` or `"line"`), `piece`, `x`, `y`.
#' @param group Name of the group column.
#' @param limits Display limits as in [PlotEmbedding()].
#' @param subset Optional named list of columns and values to keep.
#' @param colours Colours by slot (vector) or named by group.
#' @param fill_alpha Opacity of the filled region.
#' @param line_width Outline width in points.
#' @param key Draw the key below the panel.
#' @param key_size Key text size in points.
#' @param key_ncol Key columns.
#' @param texts,values Free texts and template values.
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' set.seed(2)
#' pts <- data.frame(x = c(rnorm(300), rnorm(300, 2)), y = c(rnorm(300), rnorm(300, 1)),
#'                   g = rep(c("p1", "p2"), each = 300))
#' lim <- c(-4, 6, -4, 5)
#' cont <- DensityLevelContour(pts, group = "g", limits = lim, bins = 40)
#' PlotDensityOutlines(cont, group = "g", limits = lim, colours = c("#e34948", "#eda100"))
#' @export
PlotDensityOutlines <- function(data, group = "group", limits = NULL, subset = NULL, colours = NULL, fill_alpha = 0.14,
                                line_width = 0.5, key = TRUE, key_size = 4.2, key_ncol = 6, texts = NULL,
                                values = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  .fig_require_columns(data, c(group, "slot", "kind", "piece", "x", "y"))
  d <- .figb_subset(as.data.frame(data), subset)
  d$.g <- as.character(d[[group]])
  lim <- .figb_limits(limits)
  if (is.null(lim)) lim <- c(range(d$x, finite = TRUE), range(d$y, finite = TRUE))
  groups <- unique(d[, intersect(c(".g", "slot", "label"), names(d)), drop = FALSE])
  groups <- groups[order(groups$slot), , drop = FALSE]
  gcol <- if (is.null(colours)) ManuscriptPalettes()$clusters[groups$slot] else {
    cl <- unlist(colours)
    if (is.null(names(cl))) cl[(groups$slot - 1L) %% length(cl) + 1L] else unname(cl[groups$.g])
  }
  gcol <- .fig_colour(as.character(gcol), style)
  names(gcol) <- groups$.g
  p <- .figb_canvas(lim[1:2], lim[3:4], style)
  for (g in groups$.g) {
    band <- d[d$.g == g & d$kind == "band", , drop = FALSE]
    line <- d[d$.g == g & d$kind == "line", , drop = FALSE]
    if (nrow(band)) {
      p <- p + ggplot2::geom_polygon(data = band, ggplot2::aes(x = .data$x, y = .data$y, subgroup = .data$piece),
                                     fill = grDevices::adjustcolor(gcol[[g]], alpha.f = fill_alpha), colour = NA,
                                     inherit.aes = FALSE)
    }
    if (nrow(line)) {
      p <- p + ggplot2::geom_path(data = line, ggplot2::aes(x = .data$x, y = .data$y, group = .data$piece),
                                  colour = gcol[[g]], linewidth = PtLinewidth(line_width), inherit.aes = FALSE)
    }
  }
  if (isTRUE(key) && nrow(groups)) {
    labs <- if ("label" %in% names(groups)) as.character(groups$label) else groups$.g
    p <- p + .figb_annotation(grid::gTree(labels = labs, colours = unname(gcol), size = key_size,
                                          ncol = key_ncol, style = style, cl = "phenoscapR_linekey"))
  }
  if (!is.null(texts)) p <- p + .figb_texts_layer(texts, .figb_template_values(values, d, subset), style)
  p
}

# A one- or few-row key of short line segments, centred below the panel as
# a figure legend anchored at the lower edge of its axes.
#' @exportS3Method grid::makeContent
makeContent.phenoscapR_linekey <- function(x) {
  fs <- x$size
  em <- fs
  n <- length(x$labels)
  probes <- lapply(x$labels, function(l) .figb_text_grob(l, grid::unit(0, "pt"), grid::unit(0, "pt"), fs,
                                                          x$style$colour$ink, x$style, hjust = 0, vjust = 0.5,
                                                          typeset = FALSE))
  w <- vapply(probes, function(g) grid::convertWidth(grid::grobWidth(g), "pt", valueOnly = TRUE), numeric(1))
  handle <- 0.8 * em
  gap <- 0.25 * em
  colgap <- 0.5 * em
  ncol <- max(1L, min(x$ncol, n))
  nrow <- ceiling(n / ncol)
  item_w <- handle + gap + w
  col_w <- vapply(seq_len(ncol), function(j) max(item_w[seq(j, n, by = ncol)]), numeric(1))
  total <- sum(col_w) + colgap * (ncol - 1)
  row_h <- fs * 1.5
  top <- -(0.1 + 0.4 + 0.5) * em
  kids <- list()
  for (i in seq_len(n)) {
    j <- (i - 1L) %% ncol + 1L
    r <- (i - 1L) %/% ncol + 1L
    x0 <- -total / 2 + sum(col_w[seq_len(j - 1L)]) + colgap * (j - 1L)
    yc <- top - (r - 0.5) * row_h
    kids[[length(kids) + 1L]] <- grid::segmentsGrob(
      grid::unit(0.5, "npc") + grid::unit(x0, "pt"), grid::unit(yc, "pt"),
      grid::unit(0.5, "npc") + grid::unit(x0 + handle, "pt"), grid::unit(yc, "pt"),
      gp = grid::gpar(col = x$colours[i], lwd = .figb_lwd(1.1), lineend = "butt"))
    kids[[length(kids) + 1L]] <- .figb_text_grob(
      x$labels[i], grid::unit(0.5, "npc") + grid::unit(x0 + handle + gap, "pt"), grid::unit(yc, "pt"),
      fs, x$style$colour$ink, x$style, hjust = 0, vjust = 0.5, typeset = FALSE)
  }
  grid::setChildren(x, do.call(grid::gList, kids))
}
