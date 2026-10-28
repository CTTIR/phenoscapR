# Group-level displays: strips of unit values per group, scatter plots and
# per-unit dot rows coloured by group, and bar charts with per-unit labels.

#' Unit Values by Group
#'
#' Jittered points of one value per unit (patient) for each group, with a
#' bar at the group median. With `category`, groups are drawn side by side
#' within each category (for example one neighbourhood per category) with
#' faint separators between categories. On a logarithmic axis, values at or
#' below zero are not drawn and counted in a note at the bottom.
#'
#' @param data Tidy data: one row per unit (and category).
#' @param value,group Columns.
#' @param groups Group order.
#' @param group_labels Named tick labels per group (for example short
#'   names).
#' @param group_colours Named colours per group.
#' @param colour_by Optional column colouring the points instead of the group
#'   (for example the clinical group of each unit), with `point_colours`.
#' @param point_colours Named colours per value of `colour_by`.
#' @param category Optional category column; `category_order` and
#'   `category_labels` order and label it.
#' @param category_order,category_labels Category order and tick labels.
#' @param dodge Offset between groups within a category.
#' @param jitter Half-width of the horizontal jitter.
#' @param seed Seed of the jitter (presentation only).
#' @param point_size Point area (pt^2).
#' @param median_width Half-width of the median bar (x units).
#' @param median_linewidth Its width in points.
#' @param log_y Logarithmic y axis.
#' @param zero_text Template for the count of values at or below zero
#'   (field `{n}`).
#' @param y_limits,y_breaks,y_nbins y axis.
#' @param y_label,x_label Axis titles.
#' @param tick_size Tick label size.
#' @param title_size Axis title size.
#' @param box_mm Size of the data area `c(width, height)` in millimetres, passed
#'   by [RenderFigure()]; used by `"auto"` tick intervals (see [NiceBreaks()]).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' d <- data.frame(group = rep(c("A", "B", "C"), c(5, 2, 4)), value = c(1:5, 2.5, 4, 3:6))
#' PlotGroupStrip(d, group_colours = c(A = "#009E73", B = "#D55E00", C = "#0072B2"))
#' @export
PlotGroupStrip <- function(data, value = "value", group = "group", groups = NULL, group_labels = NULL,
                           group_colours = NULL, colour_by = NULL, point_colours = NULL, category = NULL,
                           category_order = NULL, category_labels = NULL,
                           dodge = 0.27, jitter = NULL, seed = 3, point_size = 10, median_width = NULL,
                           median_linewidth = 1, log_y = FALSE, zero_text = "{n} at zero", y_limits = NULL,
                           y_breaks = NULL, y_nbins = 9, y_label = NULL, x_label = NULL, tick_size = NULL,
                           title_size = 5.6, box_mm = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  .fig_require_columns(data, c(value, group, category, colour_by))
  data <- as.data.frame(data, check.names = FALSE)
  if (is.null(groups)) groups <- unique(as.character(data[[group]]))
  k <- style$colour
  d <- data.frame(g = as.character(data[[group]]), v = as.numeric(data[[value]]),
                  cb = if (is.null(colour_by)) NA_character_ else as.character(data[[colour_by]]))
  d$gi <- match(d$g, groups)
  if (is.null(category)) {
    d$x0 <- d$gi
    if (is.null(jitter)) jitter <- 0.15
    if (is.null(median_width)) median_width <- 0.25
  } else {
    if (is.null(category_order)) category_order <- unique(as.character(data[[category]]))
    d$ci <- match(as.character(data[[category]]), category_order)
    d$x0 <- d$ci + (d$gi - (length(groups) + 1) / 2) * dodge
    if (is.null(jitter)) jitter <- 0.06
    if (is.null(median_width)) median_width <- 0.1
  }
  d <- d[!is.na(d$x0) & !is.na(d$v), , drop = FALSE]
  d$colour <- if (is.null(colour_by)) .figA_lookup(d$g, group_colours, k$ink, style) else
    .figA_lookup(d$cb, point_colours, k$ink, style)
  d$x <- d$x0
  key <- if (is.null(category)) d$gi else paste(d$ci, d$gi)
  for (kk in unique(key)) {
    i <- which(key == kk)
    d$x[i] <- d$x0[i] + .figA_jitter(length(i), jitter, if (is.null(seed)) NULL else seed + match(kk, unique(key)))
  }
  med <- stats::aggregate(v ~ x0, d, stats::median)
  if (log_y) med <- med[med$v > 0, , drop = FALSE]
  if (is.null(category)) {
    xl <- c(0.5, length(groups) + 0.5)
    breaks <- seq_along(groups)
    labs <- if (is.null(group_labels)) groups else {
      gl <- unlist(group_labels)
      ifelse(groups %in% names(gl), gl[groups], groups)
    }
  } else {
    xl <- c(0.5, length(category_order) + 0.5)
    breaks <- seq_along(category_order)
    labs <- if (is.null(category_labels)) category_order else {
      cl <- unlist(category_labels)
      ifelse(category_order %in% names(cl), cl[category_order], category_order)
    }
  }
  yl <- if (log_y) .figA_limits(d$v, y_limits, log = TRUE) else .figA_limits(d$v, y_limits)
  shown <- (if (log_y) d$v > 0 else rep(TRUE, nrow(d))) &
    .figA_inside(d$x, if (log_y) pmax(d$v, .Machine$double.xmin) else d$v, xl, yl)
  p <- ggplot2::ggplot()
  if (!is.null(category) && length(category_order) > 1L) {
    p <- p + ggplot2::geom_vline(xintercept = seq_len(length(category_order) - 1L) + 0.5, colour = k$grid,
                                 linewidth = PtLinewidth(style$line$grid))
  }
  med <- med[med$v >= yl[1] & med$v <= yl[2], , drop = FALSE]
  p <- p + ggplot2::geom_point(data = d[shown, , drop = FALSE], ggplot2::aes(.data$x, .data$v),
                               colour = d$colour[shown], shape = 16, size = .figA_size_filled(point_size),
                               stroke = 0) +
    ggplot2::geom_segment(data = med, ggplot2::aes(x = .data$x0 - median_width, xend = .data$x0 + median_width,
                                                   y = .data$v, yend = .data$v),
                          colour = k$ink, linewidth = PtLinewidth(median_linewidth), lineend = "butt")
  if (log_y && any(d$v <= 0)) {
    z <- stats::aggregate(v ~ x0, d[d$v <= 0, , drop = FALSE], length)
    p <- p + .figA_text_layer(data.frame(x = z$x0, y = yl[1], dy_npc = 0.02,
                                         label = vapply(z$v, function(n) FormatTemplate(zero_text, data.frame(n = n)),
                                                        character(1)),
                                         hjust = 0.5, vjust = 0, fontsize = 4.4, colour = k$muted), style)
  }
  ys <- if (log_y) .fig_scale_log10("y", yl) else .figA_scale("y", yl, y_breaks, y_nbins, box_mm = box_mm, tick_size = tick_size)
  if (log_y) ys$expand <- c(0, 0)
  p + ggplot2::scale_x_continuous(limits = xl, breaks = breaks, labels = .figA_tick_labels(labs), expand = c(0, 0),
                                  oob = .figA_keep) +
    ys + ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = .figA_axis_title(x_label), y = .figA_axis_title(y_label)) +
    .figA_theme(style, grid = "y", tick_size = tick_size, title_size = title_size)
}

#' Scatter or Dot Rows Coloured by Group
#'
#' Points coloured by the group of each unit, with optional open symbols
#' for flagged units, labels with offsets in points, lines connecting the
#' points of a unit across conditions (paired values), median bars and
#' categorical axes. A categorical y axis gives one row per unit (dot rows),
#' with tick labels coloured by group, separators between groups and a
#' "not estimable" text where the value is missing.
#'
#' @param data Tidy data.
#' @param x,y Columns. Character columns are categorical.
#' @param group Group column.
#' @param group_colours Named colours per group.
#' @param id Unit column (for connections, labels and offsets).
#' @param x_order,x_labels Order and tick labels of a categorical x.
#' @param y_order,y_labels Order (top to bottom) and tick labels of a
#'   categorical y; `y_labels = FALSE` hides them.
#' @param colour_ticks Colour categorical y tick labels by group.
#' @param open Optional logical column: open symbols (and dashed
#'   connections) when `TRUE`.
#' @param size Point area (pt^2).
#' @param stroke Edge width of filled points (pt); open symbols use
#'   `open_stroke`.
#' @param open_stroke Edge of open symbols.
#' @param connect Connect the points of each `id` across x.
#' @param linewidth,line_alpha Connection style (points).
#' @param open_linewidth,open_linetype Width and dash pattern of connections
#'   of open units (default: `linewidth`, dashed).
#' @param open_shift Horizontal shift of open units (x units); a named list
#'   gives shifts per `id` overriding `open_shift_default`.
#' @param open_shift_default Shift for open units without an entry.
#' @param summary Draw a median bar per x over units that are not open.
#' @param summary_half,summary_linewidth Half-width (points) and width of
#'   median bars.
#' @param label Optional label column; labels of points outside the axes are
#'   not drawn.
#' @param label_only Optional logical column: label only these rows.
#' @param label_first Label only the first point (lowest x) of each unit.
#' @param label_offset Default label offset in points (`c(dx, dy)`).
#' @param label_offsets Named list of offsets per `id`.
#' @param label_size Label size; `label_colour` `"group"` uses group colours.
#' @param label_vjust Vertical justification of labels at their offset (0.2 is
#'   close to baseline alignment).
#' @param label_colour Label colour.
#' @param missing_text Text for missing x values on a categorical y axis.
#' @param missing_size Its size.
#' @param separators Draw lines between rows of different groups
#'   (categorical y).
#' @param x_limits,y_limits,x_breaks,y_breaks,x_nbins,y_nbins Axes.
#' @param log_y Logarithmic y axis (values at or below zero are not drawn).
#' @param x_label,y_label Axis titles.
#' @param grid `"y"`, `"x"`, `"both"` or `"none"`.
#' @param tick_size Tick label size, or `c(x, y)`.
#' @param title_size Axis title size, or `c(x, y)`.
#' @param stats Optional one-row data frame for `note` (default: first row of
#'   `data`).
#' @param note Optional template (see [FormatTemplate()]) written at `note_xy`
#'   (panel fractions), for example a correlation coefficient.
#' @param note_xy,note_hjust,note_vjust,note_size,note_colour Note placement
#'   and style.
#' @param reference Optional data frame of vertical reference lines (for
#'   example the value chosen in each analysis), one per row.
#' @param reference_x Column of `reference` with the x positions.
#' @param reference_group Optional column of `reference` whose values take
#'   their colour from `group_colours`.
#' @param reference_linewidth,reference_linetype Reference line width (points)
#'   and dash pattern.
#' @param ties Draw units at the same position side by side (`tie_dodge` x
#'   units apart) and write their `label`s once, joined by commas, right of
#'   the group at `tie_label_dx[1] + tie_label_dx[2] * n` x units.
#' @param tie_dodge,tie_label_dx,tie_label_size,tie_label_colour Layout and
#'   style of tied units and their labels.
#' @param box_mm Size of the data area `c(width, height)` in millimetres, passed
#'   by [RenderFigure()]; used by `"auto"` tick intervals (see [NiceBreaks()]).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' d <- data.frame(id = paste0("u", 1:5), group = c("A", "A", "B", "B", "B"),
#'                 x = c(0.1, 0.4, 0.2, 0.8, 0.5), y = c(1, 3, 2, 5, 4))
#' PlotScatterGroups(d, id = "id", label = "id", group_colours = c(A = "#009E73", B = "#0072B2"))
#' @export
PlotScatterGroups <- function(data, x = "x", y = "y", group = "group", group_colours = NULL, id = NULL,
                              x_order = NULL, x_labels = NULL, y_order = NULL, y_labels = NULL,
                              colour_ticks = TRUE, open = NULL, size = 20, stroke = 0, open_stroke = 0.7,
                              connect = FALSE, linewidth = 0.65, line_alpha = 0.85, open_linewidth = NULL,
                              open_linetype = "32", open_shift = NULL,
                              open_shift_default = 0, summary = FALSE, summary_half = 5.9,
                              summary_linewidth = 1.4, label = NULL, label_only = NULL, label_first = FALSE,
                              label_offset = c(5, 0), label_offsets = NULL, label_size = 5.3, label_vjust = 0.5,
                              label_colour = "group", missing_text = "NE", missing_size = 5.3, separators = FALSE,
                              x_limits = NULL, y_limits = NULL, x_breaks = NULL, y_breaks = NULL, x_nbins = 6,
                              y_nbins = 9, log_y = FALSE, x_label = NULL, y_label = NULL,
                              grid = c("y", "x", "both", "none"), tick_size = NULL, title_size = NULL,
                              stats = NULL, note = NULL, note_xy = c(0.97, 0.96), note_hjust = 1, note_vjust = 1,
                              note_size = 4.8, note_colour = "muted", reference = NULL, reference_x = "x",
                              reference_group = NULL, reference_linewidth = 0.5, reference_linetype = "32",
                              ties = FALSE, tie_dodge = 0.16, tie_label_dx = c(0.12, 0.08), tie_label_size = 4.3,
                              tie_label_colour = "muted", box_mm = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  grid <- match.arg(grid)
  .fig_require_columns(data, c(x, y, group, id, open, label, label_only))
  data <- as.data.frame(data, check.names = FALSE)
  k <- style$colour
  xcat <- is.character(data[[x]]) || is.factor(data[[x]]) || !is.null(x_order)
  ycat <- is.character(data[[y]]) || is.factor(data[[y]]) || !is.null(y_order)
  d <- data.frame(row = seq_len(nrow(data)), g = as.character(data[[group]]),
                  id = if (is.null(id)) as.character(seq_len(nrow(data))) else as.character(data[[id]]),
                  stringsAsFactors = FALSE)
  if (xcat) {
    if (is.null(x_order)) x_order <- unique(as.character(data[[x]]))
    d$x <- match(as.character(data[[x]]), x_order)
  } else {
    d$x <- as.numeric(data[[x]])
  }
  if (ycat) {
    if (is.null(y_order)) y_order <- unique(as.character(data[[y]]))
    d$y <- length(y_order) + 1 - match(as.character(data[[y]]), y_order)
  } else {
    d$y <- as.numeric(data[[y]])
    if (log_y) d$y <- ifelse(d$y > 0, log10(d$y), NA_real_)
  }
  d$open <- if (is.null(open)) FALSE else as.logical(data[[open]])
  d$open[is.na(d$open)] <- FALSE
  d$colour <- .figA_lookup(d$g, group_colours, k$ink, style)
  if (!is.null(open_shift) || open_shift_default != 0) {
    sh <- unlist(open_shift)
    shift <- ifelse(d$id %in% names(sh), sh[d$id], open_shift_default)
    d$x <- d$x + ifelse(d$open, as.numeric(shift), 0)
  }
  tie_rows <- NULL
  if (isTRUE(ties)) {
    fin <- which(is.finite(d$x) & is.finite(d$y))
    key <- paste(d$x[fin], d$y[fin], sep = "\r")
    tie_rows <- lapply(unique(key), function(k) fin[key == k])
    x0 <- d$x
    for (r in tie_rows) d$x[r] <- x0[r] + (seq_along(r) - 1 - (length(r) - 1) / 2) * tie_dodge
  }
  xl <- if (xcat) {
    if (is.null(x_limits)) c(0.6, length(x_order) + 0.4) else as.numeric(unlist(x_limits))
  } else {
    .figA_limits(d$x, x_limits)
  }
  yl <- if (ycat) {
    if (is.null(y_limits)) c(0.3, length(y_order) + 0.7) else as.numeric(unlist(y_limits))
  } else if (log_y) {
    log10(.figA_limits(10^d$y, y_limits, log = TRUE))
  } else {
    .figA_limits(d$y, y_limits)
  }
  ok <- is.finite(d$x) & is.finite(d$y)
  vis <- .figA_inside(d$x, d$y, xl, yl)
  p <- ggplot2::ggplot()
  if (ycat && separators) {
    gy <- d[!duplicated(d$y) & is.finite(d$y), c("y", "g")]
    gy <- gy[order(-gy$y), , drop = FALSE]
    cut <- which(gy$g[-1] != gy$g[-nrow(gy)])
    if (length(cut)) {
      p <- p + ggplot2::geom_hline(yintercept = (gy$y[cut] + gy$y[cut + 1]) / 2, colour = "#CCCCCC",
                                   linewidth = PtLinewidth(0.5))
    }
  }
  if (isTRUE(connect)) {
    for (u in unique(d$id)) {
      z <- d[d$id == u, , drop = FALSE]
      if (nrow(z) < 2L || any(!is.finite(c(z$x, z$y)))) next
      z <- z[order(z$x), , drop = FALSE]
      zc <- .figA_clip_path(z, xl, yl)
      if (!nrow(zc)) next
      p <- p + ggplot2::geom_path(data = zc, ggplot2::aes(.data$x, .data$y, group = .data$piece), colour = z$colour[1],
                                  alpha = line_alpha,
                                  linewidth = PtLinewidth(if (any(z$open) && !is.null(open_linewidth)) open_linewidth else linewidth),
                                  linetype = if (any(z$open)) open_linetype else "solid")
    }
  }
  op <- vis & d$open
  if (any(op)) {
    e <- .figA_size_edged(size, open_stroke)
    p <- p + ggplot2::geom_point(data = d[op, , drop = FALSE], ggplot2::aes(.data$x, .data$y), shape = 21,
                                 fill = "white", colour = d$colour[op], size = e$size, stroke = e$stroke)
  }
  filled <- vis & !d$open
  if (stroke > 0) {
    e <- .figA_size_edged(size, stroke)
    p <- p + ggplot2::geom_point(data = d[filled, , drop = FALSE], ggplot2::aes(.data$x, .data$y), shape = 21,
                                 fill = d$colour[filled], colour = d$colour[filled], size = e$size, stroke = e$stroke)
  } else {
    p <- p + ggplot2::geom_point(data = d[filled, , drop = FALSE], ggplot2::aes(.data$x, .data$y), shape = 16,
                                 colour = d$colour[filled], size = .figA_size_filled(size), stroke = 0)
  }
  if (!is.null(reference) && nrow(reference)) {
    .fig_require_columns(reference, c(reference_x, reference_group), "reference")
    rc <- if (is.null(reference_group)) rep(k$ink, nrow(reference)) else
      .figA_lookup(reference[[reference_group]], group_colours, k$ink, style)
    p <- p + ggplot2::geom_vline(xintercept = as.numeric(reference[[reference_x]]), colour = rc,
                                 linewidth = PtLinewidth(reference_linewidth), linetype = reference_linetype)
  }
  if (isTRUE(summary)) {
    s <- d[ok & !d$open, , drop = FALSE]
    if (nrow(s)) {
      med <- if (log_y) stats::aggregate(y ~ x, s, function(v) log10(stats::median(10^v))) else
        stats::aggregate(y ~ x, s, stats::median)
      p <- p + .figA_bar_layer(med[.figA_inside(med$x, med$y, xl, yl), , drop = FALSE], k$ink, summary_half,
                               summary_linewidth)
    }
  }
  if (!is.null(label) && isTRUE(ties)) {
    labs_all <- as.character(data[[label]])
    tl <- do.call(rbind, lapply(tie_rows, function(r) {
      data.frame(x = x0[r[1]] + tie_label_dx[1] + tie_label_dx[2] * length(r), y = d$y[r[1]],
                 label = paste(labs_all[d$row[r]], collapse = ", "), stringsAsFactors = FALSE)
    }))
    tl <- tl[.figA_inside(tl$x, tl$y, xl, yl), , drop = FALSE]
    if (nrow(tl)) {
      tl$hjust <- 0
      tl$vjust <- 0.5
      tl$fontsize <- tie_label_size
      tl$colour <- .figA_col(tie_label_colour, style)
      p <- p + .figA_text_layer(tl, style)
    }
  } else if (!is.null(label)) {
    lab <- d[ok, , drop = FALSE]
    lab$label <- as.character(data[[label]])[lab$row]
    if (!is.null(label_only)) lab <- lab[as.logical(data[[label_only]])[lab$row] %in% TRUE, , drop = FALSE]
    if (label_first) {
      lab <- lab[order(lab$id, lab$x), , drop = FALSE]
      lab <- lab[!duplicated(lab$id), , drop = FALSE]
    }
    lab <- lab[.figA_inside(lab$x, lab$y, xl, yl), , drop = FALSE]
    if (nrow(lab)) {
      off <- as.numeric(unlist(label_offset))
      lo <- label_offsets
      lab$dx <- vapply(lab$id, function(u) if (!is.null(lo[[u]])) as.numeric(unlist(lo[[u]]))[1] else off[1], numeric(1))
      lab$dy <- vapply(lab$id, function(u) if (!is.null(lo[[u]])) as.numeric(unlist(lo[[u]]))[2] else off[2], numeric(1))
      lab$hjust <- ifelse(lab$dx >= 0, 0, 1)
      lab$vjust <- label_vjust
      lab$fontsize <- label_size
      lab$colour <- if (identical(label_colour, "group")) lab$colour else .figA_col(label_colour, style)
      p <- p + .figA_text_layer(lab[c("x", "y", "label", "dx", "dy", "hjust", "vjust", "fontsize", "colour")], style)
    }
  }
  if (!is.null(note)) {
    p <- p + .figA_text_layer(.figA_npc_text(.figA_note(note, if (is.null(stats)) data else stats), note_xy[1], note_xy[2],
                                             note_hjust, note_vjust, note_size, .figA_col(note_colour, style),
                                             x_base = xl[1], y_base = yl[1]), style)
  }
  if (ycat && !is.null(missing_text)) {
    miss <- d[!is.finite(d$x) & is.finite(d$y), , drop = FALSE]
    if (nrow(miss)) {
      p <- p + .figA_text_layer(data.frame(x = -Inf, y = miss$y, dx_npc = 0.03, label = missing_text, hjust = 0,
                                           vjust = 0.5, fontsize = missing_size, colour = "#666666"), style)
    }
  }
  if (xcat) {
    xs <- ggplot2::scale_x_continuous(limits = xl, breaks = seq_along(x_order),
                                      labels = .figA_tick_labels(if (is.null(x_labels)) x_order else x_labels),
                                      expand = c(0, 0), oob = .figA_keep)
  } else {
    xs <- .figA_scale("x", xl, x_breaks, x_nbins, box_mm = box_mm, tick_size = tick_size[1])
  }
  if (ycat) {
    gcol <- NULL
    if (colour_ticks) gcol <- d$colour[match(rev(seq_along(y_order)), d$y)]
    ylabs <- if (isFALSE(y_labels)) rep("", length(y_order)) else .figA_tick_labels(
      if (is.null(y_labels)) y_order else y_labels, gcol)
    ys <- ggplot2::scale_y_continuous(limits = yl, breaks = rev(seq_along(y_order)), labels = ylabs, expand = c(0, 0),
                                      oob = .figA_keep)
  } else if (log_y) {
    ys <- .figA_scale_log_space("y", yl)
  } else {
    ys <- .figA_scale("y", yl, y_breaks, y_nbins, box_mm = box_mm, tick_size = tick_size[length(tick_size)])
  }
  p + xs + ys + ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = .figA_axis_title(x_label), y = .figA_axis_title(y_label)) +
    .figA_theme(style, grid = grid, tick_size_x = tick_size[1], tick_size_y = tick_size[length(tick_size)],
                title_size_x = title_size[1], title_size_y = title_size[length(title_size)],
                ticks_y = !(ycat && isFALSE(y_labels)))
}

#' Bars per Unit
#'
#' Vertical or horizontal bars per unit (patient), single, side by side or
#' stacked by a series column, with tick labels coloured by group, an
#' optional reference line with a label from summary data, text at the end
#' of each bar and a corner note.
#'
#' @param data Tidy data: one row per unit (and series).
#' @param x Unit column; `y` the bar value.
#' @param y Value column.
#' @param series Optional series column (bars side by side or stacked).
#' @param x_order Unit order (left to right, or top to bottom when
#'   horizontal).
#' @param x_labels Tick labels.
#' @param fills Colour (one, or named per series).
#' @param series_order Series order (stacking from the bottom; side by side
#'   from the left).
#' @param position `"identity"`, `"dodge"` or `"stack"`.
#' @param width Total bar width per unit.
#' @param edge_colour,edge_linewidth Bar outline.
#' @param horizontal Horizontal bars.
#' @param log_y Logarithmic value axis.
#' @param tick_group Optional group column colouring the unit tick labels.
#' @param group_colours Named group colours.
#' @param tick_angle Rotation of unit tick labels.
#' @param tick_size Unit tick label size.
#' @param stats Optional one-row data frame for the reference line and the
#'   note.
#' @param reference Column of `stats` giving a reference value line.
#' @param reference_label Template written above the right end of the line.
#' @param reference_label_dy Its offset in value units.
#' @param reference_label_size Its size.
#' @param bar_label Optional template written at the end of each bar.
#' @param bar_label_d Offset in value units.
#' @param bar_label_scale Further offset as a fraction of the bar value.
#' @param bar_label_colour Colour of the bar labels.
#' @param bar_label_size Size.
#' @param note Optional template (first row of `stats`) at `note_xy`.
#' @param note_xy,note_size,note_hjust,note_vjust Note placement.
#' @param value_limits,value_breaks,value_nbins Value axis.
#' @param value_labels Optional tick labels for `value_breaks`.
#' @param value_expand Optional upper value limit as a multiple of the
#'   largest bar (the lower limit is then zero).
#' @param x_label,y_label Axis titles (x is the unit axis).
#' @param title_size Axis title size.
#' @param grid Grid lines along the value axis.
#' @param box_mm Size of the data area `c(width, height)` in millimetres, passed
#'   by [RenderFigure()]; used by `"auto"` tick intervals (see [NiceBreaks()]).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' d <- data.frame(id = c("p1", "p2", "p3"), v = c(20, 55, 70), g = c("A", "A", "B"))
#' PlotBars(d, x = "id", y = "v", tick_group = "g", group_colours = c(A = "#009E73", B = "#0072B2"),
#'          stats = data.frame(m = 48), reference = "m", reference_label = "Mean, {m|f0}%")
#' @export
PlotBars <- function(data, x = "x", y = "value", series = NULL, x_order = NULL, x_labels = NULL, fills = "#D9D9D9",
                     series_order = NULL, position = c("identity", "dodge", "stack"), width = 0.74, edge_colour = NA,
                     edge_linewidth = 0, horizontal = FALSE, log_y = FALSE, tick_group = NULL,
                     group_colours = NULL, tick_angle = 0, tick_size = NULL, stats = NULL, reference = NULL,
                     reference_label = NULL, reference_label_dy = 1.5, reference_label_size = 4.6,
                     bar_label = NULL, bar_label_d = 2, bar_label_scale = 0, bar_label_size = 4.4,
                     bar_label_colour = "muted", note = NULL, note_xy = c(0.02, 0.97),
                     note_size = 4.8, note_hjust = 0, note_vjust = 1, value_limits = NULL, value_breaks = NULL,
                     value_labels = NULL, value_expand = NULL,
                     value_nbins = 9, x_label = NULL, y_label = NULL, title_size = 5.6, grid = TRUE,
                     box_mm = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  position <- match.arg(position)
  .fig_require_columns(data, c(x, y, series, tick_group))
  data <- as.data.frame(data, check.names = FALSE)
  k <- style$colour
  if (is.null(x_order)) x_order <- unique(as.character(data[[x]]))
  if (is.null(x_labels)) x_labels <- x_order
  d <- data.frame(xi = match(as.character(data[[x]]), x_order), v = as.numeric(data[[y]]),
                  s = if (is.null(series)) "all" else as.character(data[[series]]), row = seq_len(nrow(data)))
  d <- d[!is.na(d$xi), , drop = FALSE]
  if (is.null(series_order)) series_order <- unique(d$s)
  d$si <- match(d$s, series_order)
  d <- d[!is.na(d$si), , drop = FALSE]
  ns <- length(series_order)
  cols <- .figA_lookup(series_order, fills, "#D9D9D9", style)
  d$pos <- if (horizontal) length(x_order) + 1 - d$xi else d$xi
  w <- if (position == "dodge") width / ns else width
  d$c <- if (position == "dodge") d$pos + (d$si - (ns + 1) / 2) * w else d$pos
  if (position == "stack") {
    d <- d[order(d$pos, d$si), , drop = FALSE]
    d$top <- stats::ave(ifelse(is.na(d$v), 0, d$v), d$pos, FUN = cumsum)
    d$bottom <- d$top - ifelse(is.na(d$v), 0, d$v)
  } else {
    d$top <- d$v
    d$bottom <- 0
  }
  rv <- NULL
  if (!is.null(reference)) {
    .fig_require_columns(stats, reference, "stats")
    rv <- as.numeric(stats[[reference]][1])
  }
  if (!is.null(value_expand)) value_limits <- c(0, max(d$top, na.rm = TRUE) * value_expand)
  vl <- if (log_y) .figA_limits(d$top, value_limits, log = TRUE) else .figA_limits(c(d$top, d$bottom, rv), value_limits)
  ul <- range(c(d$c - w / 2, d$c + w / 2))
  ul <- ul + c(-1, 1) * 0.05 * diff(ul)
  d$bottom <- if (log_y) rep(vl[1], nrow(d)) else pmin(pmax(d$bottom, vl[1]), vl[2])
  d$top <- pmin(pmax(d$top, vl[1]), vl[2])
  d$fillc <- cols[d$si]
  rect <- if (horizontal) {
    ggplot2::geom_rect(data = d, ggplot2::aes(xmin = .data$bottom, xmax = .data$top, ymin = .data$c - w / 2,
                                              ymax = .data$c + w / 2),
                       fill = d$fillc, colour = .figA_col(edge_colour, style), linewidth = PtLinewidth(edge_linewidth))
  } else {
    ggplot2::geom_rect(data = d, ggplot2::aes(xmin = .data$c - w / 2, xmax = .data$c + w / 2, ymin = .data$bottom,
                                              ymax = .data$top),
                       fill = d$fillc, colour = .figA_col(edge_colour, style), linewidth = PtLinewidth(edge_linewidth))
  }
  p <- ggplot2::ggplot() + rect
  if (!is.null(rv)) {
    p <- p + (if (horizontal) ggplot2::geom_vline(xintercept = rv, colour = k$muted, linewidth = PtLinewidth(0.6),
                                                  linetype = "32")
              else ggplot2::geom_hline(yintercept = rv, colour = k$muted, linewidth = PtLinewidth(0.6), linetype = "32"))
    if (!is.null(reference_label)) {
      # Beside the line, between the last two categories (transposed for
      # horizontal bars, whose last category is at the bottom).
      text <- .figA_note(reference_label, stats)
      lab <- if (horizontal) {
        data.frame(x = rv + reference_label_dy, y = 1.5, label = text, hjust = 0, vjust = 0,
                   fontsize = reference_label_size, colour = k$muted)
      } else {
        data.frame(x = length(x_order) - 0.5, y = rv + reference_label_dy, label = text, hjust = 1, vjust = 0,
                   fontsize = reference_label_size, colour = k$muted)
      }
      p <- p + .figA_text_layer(lab, style)
    }
  }
  if (!is.null(bar_label)) {
    txt <- FormatTemplate(bar_label, data[d$row, , drop = FALSE])
    lab <- if (horizontal) {
      data.frame(x = d$top * (1 + bar_label_scale) + bar_label_d, y = d$c, label = txt, hjust = 0, vjust = 0.5)
    } else {
      data.frame(x = d$c, y = d$top * (1 + bar_label_scale) + bar_label_d, label = txt, hjust = 0.5, vjust = 0)
    }
    lab$fontsize <- bar_label_size
    lab$colour <- .figA_col(bar_label_colour, style)
    p <- p + .figA_text_layer(lab, style)
  }
  if (!is.null(note)) {
    p <- p + .figA_text_layer(.figA_npc_text(.figA_note(note, stats), note_xy[1], note_xy[2], note_hjust, note_vjust,
                                             note_size, k$muted,
                                             x_base = if (horizontal) vl[1] else ul[1],
                                             y_base = if (horizontal) ul[1] else vl[1]), style)
  }
  tcol <- NULL
  if (!is.null(tick_group)) {
    g <- as.character(data[[tick_group]])[match(x_order, as.character(data[[x]]))]
    tcol <- .figA_lookup(g, group_colours, k$ink, style)
  }
  tl <- .figA_tick_labels(x_labels, tcol)
  vs <- if (log_y) {
    .fig_scale_log10(if (horizontal) "x" else "y", vl)
  } else {
    .figA_scale(if (horizontal) "x" else "y", vl, value_breaks, value_nbins, box_mm = box_mm,
                labels = if (is.null(value_labels)) ggplot2::waiver() else as.character(unlist(value_labels)))
  }
  if (log_y) vs$expand <- c(0, 0)
  if (horizontal) {
    us <- ggplot2::scale_y_continuous(limits = ul, breaks = rev(seq_along(x_order)), labels = tl, expand = c(0, 0),
                                      oob = .figA_keep)
    p + vs + us + ggplot2::coord_cartesian(clip = "off") +
      ggplot2::labs(x = .figA_axis_title(y_label), y = .figA_axis_title(x_label)) +
      .figA_theme(style, grid = if (grid) "x" else "none", tick_size_y = tick_size, title_size = title_size)
  } else {
    us <- ggplot2::scale_x_continuous(limits = ul, breaks = seq_along(x_order), labels = tl, expand = c(0, 0),
                                      oob = .figA_keep)
    p + us + vs + ggplot2::coord_cartesian(clip = "off") +
      ggplot2::labs(x = .figA_axis_title(x_label), y = .figA_axis_title(y_label)) +
      .figA_theme(style, grid = if (grid) "y" else "none", tick_size_x = tick_size, x_angle = tick_angle,
                  title_size = title_size)
  }
}
