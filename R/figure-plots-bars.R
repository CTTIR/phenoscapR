#' Stacked Bars
#'
#' One bar per category (for example per patient), stacked by a second
#' variable (cell types, neighbourhoods, clinical groups) in a fixed order,
#' with thin white separators between the segments. Bars can run upwards or
#' to the right. Category labels are drawn as rotated figure tick labels and
#' can be coloured (for example by clinical group); a short text above each
#' bar (for example the tissue area) and a horizontal reference line can be
#' added. A single stack level gives plain bars.
#'
#' @param data Long data: one row per category and stack level.
#' @param x,stack,value Column names: category, stack level and segment size.
#' @param x_order Category order: character vector or data frame (ordered by
#'   a `rank` column if present); default first appearance.
#' @param x_order_by Optional numeric column giving the category order.
#' @param stacks Stack order from the baseline outwards; default first
#'   appearance.
#' @param colours Named colours per stack level.
#' @param fill_column Optional column with explicit segment colours.
#' @param scale Factor applied to `value` (for example 100 for fractions).
#' @param width Bar width in category units.
#' @param edge_colour,edge_width Segment outline (points; 0 for none).
#' @param horizontal Bars running to the right, first category on top.
#' @param limits,breaks,break_labels Value axis limits, breaks and labels;
#'   default limits from zero to 5% beyond the tallest bar.
#' @param nbins Optional maximum number of value-axis intervals; default
#'   breaks then follow [NiceBreaks()] instead of [pretty()].
#' @param value_expand Default upper limit as a multiple of the tallest bar.
#' @param category_limits Category axis limits; default half a category
#'   beyond the outer bars (5% of the bar extent for horizontal bars).
#' @param value_label,value_label_size,value_label_angle Value axis title.
#' @param tick_size,tick_length Value axis tick label size and tick length.
#' @param category_label,category_label_size Category axis title.
#' @param show_categories,x_labels,x_label_colours Category labels: shown or
#'   not, display mapping and named text colours.
#' @param category_angle,category_size Category label rotation and size.
#' @param category_ticks Draw tick marks at the categories.
#' @param axes Draw the value and category axis lines.
#' @param top_text Optional column with one value per category, printed
#'   above the bar (right of it for horizontal bars) with `top_format` at
#'   `top_at` (value units).
#' @param top_format,top_at,top_size,top_colour Format and placement.
#' @param top_offset Optional offset (value units) of the top values above
#'   each bar instead of the fixed position `top_at`.
#' @param top_title Optional text left (or right) of the top values, at
#'   `top_title_at` category units from the first bar centre (above or below
#'   them for horizontal bars).
#' @param top_title_at,top_title_hjust Placement of `top_title`.
#' @param reference Optional reference line: list of `value`, `colour`,
#'   `width` (points) and `linetype`.
#' @param legend Optional legend of the stack colours, as the `legend` of
#'   [PlotEmbedding()] (use `shapes` `"s"` for squares).
#' @param texts,values Free texts and template values, as in
#'   [PlotAnnotatedHeatmap()].
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' d <- data.frame(x = rep(c("p1", "p2"), each = 3), stack = rep(c("a", "b", "c"), 2),
#'                 value = c(0.2, 0.5, 0.3, 0.6, 0.1, 0.3), area = rep(c(6.2, 118), each = 3))
#' PlotStackedBars(d, scale = 100, limits = c(0, 100),
#'                 colours = c(a = "#e34948", b = "#2a78d6", c = "#D9D9D9"),
#'                 top_text = "area", top_title = "Area (mm2)", value_label = "Cells (%)")
#' @export
PlotStackedBars <- function(data, x = "x", stack = "stack", value = "value", x_order = NULL,
                            x_order_by = NULL, stacks = NULL, colours = NULL, fill_column = NULL, scale = 1,
                            width = 0.82, edge_colour = "white", edge_width = 0.6, horizontal = FALSE,
                            limits = NULL, breaks = NULL, break_labels = NULL, category_limits = NULL,
                            value_label = NULL, value_label_size = 5.8, value_label_angle = NULL,
                            tick_size = 5.5, tick_length = 2, category_label = NULL,
                            category_label_size = 5.5, show_categories = TRUE, x_labels = NULL,
                            x_label_colours = NULL, category_angle = 50, category_size = 5.1,
                            category_ticks = TRUE, axes = TRUE, top_text = NULL, top_format = "%.0f",
                            top_at = 101.5, top_size = 4.4, top_colour = "muted", top_offset = NULL, nbins = NULL,
                            value_expand = 1.05,
                            top_title = NULL,
                            top_title_at = -0.6, top_title_hjust = 1, reference = NULL, legend = NULL, texts = NULL,
                            values = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  .fig_require_columns(data, c(x, stack, value, fill_column, top_text, x_order_by))
  data <- as.data.frame(data)
  if (is.null(x_order) && !is.null(x_order_by)) {
    o <- unique(data[order(data[[x_order_by]]), c(x, x_order_by)])
    x_order <- as.character(o[[x]])
  }
  cats <- .figb_levels(x_order, data[[x]])
  stacks <- .figb_levels(stacks, data[[stack]])
  d <- data[as.character(data[[x]]) %in% cats & as.character(data[[stack]]) %in% stacks, , drop = FALSE]
  d$.c <- match(as.character(d[[x]]), cats)
  d$.s <- match(as.character(d[[stack]]), stacks)
  d$.v <- as.numeric(d[[value]]) * scale
  d$.v[!is.finite(d$.v)] <- 0
  d$.fill <- if (!is.null(fill_column)) as.character(d[[fill_column]]) else .figb_colours(colours, as.character(d[[stack]]), "#BBBBBB", style)
  d <- d[order(d$.c, d$.s), , drop = FALSE]
  d$.top <- stats::ave(d$.v, d$.c, FUN = cumsum)
  d$.bottom <- d$.top - d$.v
  n <- length(cats)
  pos <- if (horizontal) n - d$.c + 1 else d$.c
  totals <- tapply(d$.v, d$.c, sum)
  if (is.null(limits)) limits <- c(0, max(c(totals, 0)) * value_expand)
  limits <- as.numeric(unlist(limits))
  if (is.null(category_limits)) {
    category_limits <- if (horizontal) {
      ext <- c(1 - width / 2, n + width / 2)
      ext + c(-1, 1) * 0.05 * diff(ext)
    } else c(0.5, n + 0.5)
  }
  category_limits <- as.numeric(unlist(category_limits))
  rects <- if (horizontal) {
    data.frame(xmin = d$.bottom, xmax = d$.top, ymin = pos - width / 2, ymax = pos + width / 2, fill = d$.fill)
  } else {
    data.frame(xmin = pos - width / 2, xmax = pos + width / 2, ymin = d$.bottom, ymax = d$.top, fill = d$.fill)
  }
  k <- style$colour
  edge <- if (edge_width > 0) .fig_colour(edge_colour, style) else NA
  p <- ggplot2::ggplot() +
    ggplot2::geom_rect(data = rects, ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax, ymin = .data$ymin,
                                                  ymax = .data$ymax, fill = .data$fill),
                       colour = edge, linewidth = PtLinewidth(max(edge_width, 0)), inherit.aes = FALSE) +
    ggplot2::scale_fill_identity()
  vbreaks <- if (!is.null(breaks)) as.numeric(unlist(breaks)) else if (!is.null(nbins)) NiceBreaks(limits, nbins) else
    pretty(limits)
  vbreaks <- vbreaks[vbreaks >= min(limits) - 1e-9 & vbreaks <= max(limits) + 1e-9]
  vlabels <- if (!is.null(break_labels)) {
    as.character(unlist(break_labels))
  } else if (!is.null(nbins)) {
    .figA_number_labels(vbreaks)
  } else {
    gsub("-", "\u2212", format(vbreaks, trim = TRUE, drop0trailing = TRUE))
  }
  cbreaks <- if (category_ticks) seq_len(n) else NULL
  value_scale <- function(f) f(limits = limits, breaks = vbreaks, labels = vlabels, expand = c(0, 0), oob = .figb_keep_oob)
  cat_scale <- function(f) f(limits = category_limits, breaks = cbreaks, labels = NULL, expand = c(0, 0), oob = .figb_keep_oob)
  if (horizontal) {
    p <- p + value_scale(ggplot2::scale_x_continuous) + cat_scale(ggplot2::scale_y_continuous)
  } else {
    p <- p + cat_scale(ggplot2::scale_x_continuous) + value_scale(ggplot2::scale_y_continuous)
  }
  if (!is.null(reference)) {
    ref <- reference
    lt <- if (is.null(ref$linetype)) "32" else ref$linetype
    col <- if (is.null(ref$colour)) k$muted else .fig_colour(ref$colour, style)
    lw <- PtLinewidth(if (is.null(ref$width)) 0.5 else ref$width)
    p <- p + if (horizontal) ggplot2::geom_vline(xintercept = ref$value, colour = col, linewidth = lw, linetype = lt) else
      ggplot2::geom_hline(yintercept = ref$value, colour = col, linewidth = lw, linetype = lt)
  }
  p <- p + ggplot2::coord_cartesian(clip = "off") +
    ThemeManuscript(style, grid = "none", axes = if (isTRUE(axes)) "xy" else "none") +
    ggplot2::theme(
      axis.ticks.length = ggplot2::unit(tick_length, "pt"),
      axis.ticks = ggplot2::element_line(colour = k$ink, linewidth = PtLinewidth(style$line$tick)),
      legend.position = "none"
    )
  title_el <- function(size, angle, h) .figb_el(size = size, colour = k$ink, family = style$family,
                                                              angle = angle, hjust = h, lineheight = 1.1)
  if (horizontal) {
    p <- p + ggplot2::theme(
      axis.text.x = .figb_el(size = tick_size, colour = k$ink, family = style$family,
                                          margin = ggplot2::margin(t = 3.5)),
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = if (category_ticks) ggplot2::element_line(colour = k$ink, linewidth = PtLinewidth(style$line$tick)) else
        ggplot2::element_blank(),
      axis.title.x = title_el(value_label_size, 0, 0.5),
      axis.title.y = title_el(category_label_size, 90, 0.5)
    ) + ggplot2::labs(x = if (is.null(value_label)) NULL else TypesetLabel(value_label),
                      y = if (is.null(category_label)) NULL else TypesetLabel(category_label))
  } else {
    va <- if (is.null(value_label_angle)) 90 else value_label_angle
    p <- p + ggplot2::theme(
      axis.text.y = .figb_el(size = tick_size, colour = k$ink, family = style$family,
                                          margin = ggplot2::margin(r = 3.5)),
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = if (category_ticks) ggplot2::element_line(colour = k$ink, linewidth = PtLinewidth(style$line$tick)) else
        ggplot2::element_blank(),
      axis.title.y = if (va == 0) {
        .figb_el(size = value_label_size, colour = k$ink, family = style$family, angle = 0,
                              hjust = 1, vjust = 0.5, lineheight = 1.1, margin = ggplot2::margin(r = 4))
      } else title_el(value_label_size, va, 0.5),
      axis.title.x = title_el(category_label_size, 0, 0.5)
    ) + ggplot2::labs(y = if (is.null(value_label)) NULL else TypesetLabel(value_label),
                      x = if (is.null(category_label)) NULL else TypesetLabel(category_label))
  }
  if (show_categories) {
    lab <- .figb_display(x_labels, cats)
    cols <- .figb_colours(x_label_colours, cats, k$ink, style)
    pad <- (if (category_ticks) tick_length else 0) + 3.5
    if (horizontal) {
      at <- (n - seq_len(n) + 1 - category_limits[1]) / diff(category_limits)
      g <- .figb_tick_labels(lab, at, style, size = category_size, pad = pad, colours = cols, side = "left")
    } else {
      at <- (seq_len(n) - category_limits[1]) / diff(category_limits)
      g <- .figb_tick_labels(lab, at, style, size = category_size, angle = category_angle, pad = pad,
                             colours = cols, side = "bottom")
    }
    p <- p + .figb_annotation(g)
  }
  if (!is.null(top_text)) {
    tv <- tapply(d[[top_text]], d$.c, function(v) v[1])
    tt <- data.frame(pos = as.integer(names(tv)), v = unlist(tv))
    tt$text <- if (is.numeric(tt$v)) sprintf(top_format, tt$v) else as.character(tt$v)
    tc <- .fig_colour(top_colour, style)
    ty <- if (is.null(top_offset)) top_at else unname(totals[as.character(tt$pos)]) + top_offset
    if (horizontal) {
      # Beyond the bar end on the value axis, at the category position.
      p <- p + ggplot2::annotate("text", x = ty, y = n - tt$pos + 1, label = tt$text, colour = tc,
                                 size = .fig_text_size(top_size), family = style$family, hjust = 0, vjust = 0.5)
    } else {
      p <- p + ggplot2::annotate("text", x = tt$pos, y = ty, label = tt$text, colour = tc,
                                 size = .fig_text_size(top_size), family = style$family, vjust = 0)
    }
    if (!is.null(top_title)) {
      p <- p + if (horizontal) {
        ggplot2::annotate("text", x = top_at, y = n - top_title_at, label = TypesetLabel(top_title, rich = FALSE),
                          colour = tc, size = .fig_text_size(top_size), family = style$family,
                          hjust = 0, vjust = 1 - top_title_hjust)
      } else {
        ggplot2::annotate("text", x = 1 + top_title_at, y = top_at, label = TypesetLabel(top_title, rich = FALSE),
                          colour = tc, size = .fig_text_size(top_size), family = style$family,
                          vjust = 0, hjust = top_title_hjust)
      }
    }
  }
  if (!is.null(legend)) p <- p + .figb_annotation(.figb_marker_key(legend, colours, NULL, style))
  if (!is.null(texts)) p <- p + .figb_texts_layer(texts, .figb_template_values(values, data, NULL), style)
  p
}
