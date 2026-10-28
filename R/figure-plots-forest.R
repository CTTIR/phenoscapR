# Row-wise effect displays: interval forests, group-difference segments and
# volcano plots of exact group tests.

#' Interval Forest with Unit Values
#'
#' One row per analysis or cell type: an interval (for example a bootstrap
#' confidence interval of the median), a marked estimate, optional jittered
#' unit (patient) values behind it, a reference line and a statistic text
#' to the right of the panel written from the data. Units flagged in the
#' unit table (for example patients with low support) can be drawn as open
#' symbols in their group colour with a short label.
#'
#' @param data Summary table, one row per row of the forest.
#' @param points Optional unit table with `row` and `value` columns.
#' @param row,estimate,lower,upper Columns of `data`.
#' @param value Value column of `points`.
#' @param row_order Rows from top to bottom (default: order in `data`).
#' @param row_labels Named tick labels per row.
#' @param colours Estimate colours: one colour or named per row.
#' @param interval_colours Interval colours (default: the estimate colours).
#' @param estimate_size Estimate marker area (pt^2), drawn with a white edge
#'   of `estimate_edge` points.
#' @param estimate_edge Edge width.
#' @param interval_linewidth Interval width in points.
#' @param point_colour,point_size Unit points (area in pt^2).
#' @param jitter Half-width of the vertical jitter of unit points (rows are
#'   one unit apart).
#' @param seed Seed of the jitter (presentation only).
#' @param flag Optional logical column of `points` marking units drawn as
#'   open symbols in their group colour instead of grey points; these are
#'   spread over `flag_spread` around the row in their order of appearance.
#' @param flag_group Group column of `points` for flagged units.
#' @param group_colours Named group colours.
#' @param flag_size,flag_edge Open symbol area and edge width.
#' @param flag_label Optional column of `points` written left of flagged
#'   symbols.
#' @param flag_label_size,flag_label_vjust Its size and vertical justification.
#' @param flag_spread Half-range of the vertical spread of flagged symbols.
#' @param label Optional template (see [FormatTemplate()]) written for each
#'   row at `label_x` (panel fraction) to the right.
#' @param label_size,label_colour,label_x Label style and position.
#' @param reference_x Position of the vertical reference line (`NULL` for
#'   none).
#' @param reference_linewidth Its width in points.
#' @param x_limits,y_limits Limits; rows sit at 1 (bottom) to n (top).
#'   Automatic limits add 5% of the data range.
#' @param x_breaks,x_nbins x ticks.
#' @param x_label,y_label Axis titles.
#' @param tick_size_x,tick_size_y Tick label sizes.
#' @param title_size Axis title size.
#' @param grid `"x"` (default) or `"none"`.
#' @param box_mm Size of the data area `c(width, height)` in millimetres, passed
#'   by [RenderFigure()]; used by `"auto"` tick intervals (see [NiceBreaks()]).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' s <- data.frame(row = c("a", "b"), estimate = c(1, -0.5), lower = c(0.2, -1.2),
#'                 upper = c(1.5, 0.1), k = c(9, 7), n = 9, p = c(0.004, 0.1))
#' pts <- data.frame(row = rep(c("a", "b"), each = 5), value = c(rnorm(5, 1), rnorm(5, -0.5)))
#' PlotIntervalForest(s, pts, colours = c(a = "#D9730D", b = "#C2378E"),
#'                    label = "{k|d}/{n|d} patients; p = {p|p}")
#' @export
PlotIntervalForest <- function(data, points = NULL, row = "row", estimate = "estimate", lower = "lower",
                               upper = "upper", value = "value", row_order = NULL, row_labels = NULL,
                               colours = "ink", interval_colours = NULL, estimate_size = 18, estimate_edge = 0.4,
                               interval_linewidth = 1.2, point_colour = "#BDBDBD", point_size = 5, jitter = 0.18,
                               seed = 1, flag = NULL, flag_group = NULL, group_colours = NULL, flag_size = 15,
                               flag_edge = 0.8, flag_label = NULL, flag_label_size = 4.8, flag_label_vjust = 0.5,
                               flag_spread = 0.17,
                               label = NULL, label_size = 4.8, label_colour = "muted", label_x = 1.03,
                               reference_x = 0, reference_linewidth = 0.6, x_limits = NULL, y_limits = NULL,
                               x_breaks = NULL, x_nbins = 6, x_label = NULL, y_label = NULL, tick_size_x = NULL,
                               tick_size_y = NULL, title_size = NULL, grid = c("x", "none"),
                               box_mm = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  grid <- match.arg(grid)
  .fig_require_columns(data, c(row, estimate, lower, upper))
  data <- as.data.frame(data, check.names = FALSE)
  if (is.null(row_order)) row_order <- unique(as.character(data[[row]]))
  n <- length(row_order)
  k <- style$colour
  s <- data.frame(row = as.character(data[[row]]), est = as.numeric(data[[estimate]]),
                  lo = as.numeric(data[[lower]]), hi = as.numeric(data[[upper]]))
  s$y <- n + 1 - match(s$row, row_order)
  keep <- !is.na(s$y)
  s <- s[keep, , drop = FALSE]
  src <- data[keep, , drop = FALSE]
  s$colour <- .figA_lookup(s$row, colours, k$ink, style)
  s$icol <- if (is.null(interval_colours)) s$colour else .figA_lookup(s$row, interval_colours, k$ink, style)
  pt <- NULL
  if (!is.null(points)) {
    .fig_require_columns(points, c(row, value, flag, flag_group, flag_label), "points")
    pt <- data.frame(row = as.character(points[[row]]), value = as.numeric(points[[value]]))
    pt$y <- n + 1 - match(pt$row, row_order)
    pt$flag <- if (is.null(flag)) FALSE else as.logical(points[[flag]])
    pt$flag[is.na(pt$flag)] <- FALSE
    pt$group <- if (is.null(flag_group)) NA_character_ else as.character(points[[flag_group]])
    pt$label <- if (is.null(flag_label)) NA_character_ else as.character(points[[flag_label]])
    pt <- pt[!is.na(pt$y) & is.finite(pt$value), , drop = FALSE]
    pt$yy <- pt$y
    for (r in unique(pt$y)) {
      i <- which(!pt$flag & pt$y == r)
      pt$yy[i] <- r + .figA_jitter(length(i), jitter, if (is.null(seed)) NULL else seed + 7 * r)
      j <- which(pt$flag & pt$y == r)
      if (length(j)) pt$yy[j] <- r - seq(-flag_spread, flag_spread, length.out = max(2, length(j)))[seq_along(j)]
    }
  }
  xl <- .figA_limits(c(s$lo, s$hi, s$est, reference_x, pt$value), x_limits)
  yl <- .figA_limits(c(s$y, pt$yy), y_limits)
  p <- ggplot2::ggplot()
  if (!is.null(pt)) {
    inside <- .figA_inside(pt$value, pt$yy, xl, yl)
    plain <- pt[!pt$flag & inside, , drop = FALSE]
    p <- p + ggplot2::geom_point(data = plain, ggplot2::aes(.data$value, .data$yy),
                                 colour = .figA_col(point_colour, style), shape = 16,
                                 size = .figA_size_filled(point_size), stroke = 0)
    fl <- pt[pt$flag & inside, , drop = FALSE]
    if (nrow(fl)) {
      fl$colour <- .figA_lookup(fl$group, group_colours, k$muted, style)
      e <- .figA_size_edged(flag_size, flag_edge)
      p <- p + ggplot2::geom_point(data = fl, ggplot2::aes(.data$value, .data$yy), shape = 21, fill = "white",
                                   colour = fl$colour, size = e$size, stroke = e$stroke)
      if (!is.null(flag_label)) {
        p <- p + .figA_text_layer(data.frame(x = fl$value, y = fl$yy, label = fl$label, dx = -4, dy = -1,
                                             hjust = 1, vjust = flag_label_vjust, fontsize = flag_label_size,
                                             colour = fl$colour), style)
      }
    }
  }
  seg <- do.call(rbind, lapply(seq_len(nrow(s)), function(i) {
    c0 <- .figA_clip_segment(s$lo[i], s$y[i], s$hi[i], s$y[i], xl, yl)
    if (is.null(c0)) return(NULL)
    data.frame(x0 = c0[1], x1 = c0[3], y = s$y[i], colour = s$icol[i])
  }))
  if (!is.null(seg)) {
    p <- p + ggplot2::geom_segment(data = seg, ggplot2::aes(x = .data$x0, xend = .data$x1, y = .data$y, yend = .data$y),
                                   colour = seg$colour, linewidth = PtLinewidth(interval_linewidth), lineend = "butt")
  }
  e <- .figA_size_edged(estimate_size, estimate_edge)
  se <- s[.figA_inside(s$est, s$y, xl, yl), , drop = FALSE]
  if (!is.null(reference_x)) {
    p <- p + ggplot2::geom_vline(xintercept = reference_x, colour = k$reference,
                                 linewidth = PtLinewidth(reference_linewidth))
  }
  p <- p + ggplot2::geom_point(data = se, ggplot2::aes(.data$est, .data$y), shape = 21, colour = "white",
                               fill = se$colour, size = e$size, stroke = e$stroke)
  if (!is.null(label)) {
    txt <- FormatTemplate(label, src)
    p <- p + .figA_text_layer(data.frame(x = Inf, y = s$y, label = txt, dx_npc = label_x - 1, hjust = 0,
                                         vjust = 0.5, fontsize = label_size, colour = .figA_col(label_colour, style)),
                              style)
  }
  labs <- if (is.null(row_labels)) row_order else {
    rl <- unlist(row_labels)
    ifelse(row_order %in% names(rl), rl[row_order], row_order)
  }
  p + .figA_scale("x", xl, x_breaks, x_nbins, box_mm = box_mm) +
    ggplot2::scale_y_continuous(limits = yl, breaks = n:1, labels = .figA_tick_labels(labs), expand = c(0, 0),
                                oob = .figA_keep) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = .figA_axis_title(x_label), y = .figA_axis_title(y_label)) +
    .figA_theme(style, grid = if (grid == "x") "x" else "none", tick_size_x = tick_size_x, tick_size_y = tick_size_y,
                title_size = title_size)
}


#' Differences Between Groups as Segments
#'
#' One row per contrast or endpoint: a segment from zero to the estimate
#' (not an interval) ending in a point, and a P-value text at the right.
#' With `marker = "colour"` points, segments and text take
#' `significant_colour` when `q` is below `alpha` and `other_colour`
#' otherwise; with `marker = "open"` significant rows have filled points in
#' `significant_colour` and the others open points with an `open_colour`
#' edge, segments are drawn in `segment_colour` and the text is ink or
#' muted. The x axis is symmetric around zero unless `x_limits` are given.
#'
#' @param data Test table, one row per contrast.
#' @param row,estimate,q Columns of the contrast, estimate and the (adjusted
#'   or nominal) P value compared with `alpha`.
#' @param row_order Rows from top to bottom.
#' @param row_labels Named tick labels.
#' @param alpha Threshold for `q`.
#' @param significant_colour,other_colour Colours.
#' @param label Template written at the right (see [FormatTemplate()]).
#' @param label_size,label_x Label size and position (panel fraction).
#' @param label_title Optional column title written above the labels.
#' @param label_title_size Its size.
#' @param span Half-width of the axis relative to the largest absolute
#'   estimate.
#' @param linewidth,point_size Segment width (points) and point area.
#' @param marker `"colour"` or `"open"` (see Details).
#' @param segment_colour Segment colour with `marker = "open"`.
#' @param open_colour,open_size,open_stroke Open points: edge colour, area
#'   and edge width.
#' @param x_limits Optional x limits.
#' @param y_limits Optional y limits (rows are at 1 to n from the bottom).
#' @param x_breaks,x_nbins x ticks.
#' @param x_label Axis title.
#' @param grid `"none"` or `"x"` (vertical grid lines).
#' @param tick_size_y Row label size.
#' @param title_size Axis title size.
#' @param box_mm Size of the data area `c(width, height)` in millimetres, passed
#'   by [RenderFigure()]; used by `"auto"` tick intervals (see [NiceBreaks()]).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' t <- data.frame(contrast = c("A vs B", "C vs B"), diff = c(3.2, -1.1), p = c(0.01, 0.4),
#'                 q_BH = c(0.03, 0.5))
#' PlotGroupDifferences(t)
#' PlotGroupDifferences(t, q = "p", marker = "open", label = "{p|p}", label_title = "P",
#'                      x_limits = c(-4, 4), grid = "x")
#' @export
PlotGroupDifferences <- function(data, row = "contrast", estimate = "diff", q = "q_BH", row_order = NULL,
                                 row_labels = NULL, alpha = 0.05, significant_colour = "significant",
                                 other_colour = "muted", label = "{diff|sf1}; p = {p|p}; q = {q_BH|p}",
                                 label_size = 4.6, label_x = 1.04, label_title = NULL, label_title_size = 4.8,
                                 span = 1.25, linewidth = 1.2, point_size = 11,
                                 marker = c("colour", "open"), segment_colour = "#C9C9C9",
                                 open_colour = "open_edge", open_size = 13, open_stroke = 0.7,
                                 x_limits = NULL, y_limits = NULL, x_breaks = NULL, x_nbins = 6, x_label = NULL,
                                 grid = c("none", "x"), tick_size_y = 5, title_size = 5, box_mm = NULL,
                                 style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  marker <- match.arg(marker)
  grid <- match.arg(grid)
  .fig_require_columns(data, c(row, estimate, q))
  data <- as.data.frame(data, check.names = FALSE)
  if (is.null(row_order)) row_order <- unique(as.character(data[[row]]))
  n <- length(row_order)
  data <- data[as.character(data[[row]]) %in% row_order, , drop = FALSE]
  d <- data.frame(row = as.character(data[[row]]), est = as.numeric(data[[estimate]]))
  d$y <- n + 1 - match(d$row, row_order)
  sig <- !is.na(data[[q]]) & as.numeric(data[[q]]) < alpha
  d$colour <- ifelse(sig, .figA_col(significant_colour, style), .figA_col(other_colour, style))
  if (is.null(x_limits)) {
    half <- span * max(abs(d$est), na.rm = TRUE)
    if (!is.finite(half) || half == 0) half <- 1
    xl <- c(-half, half)
  } else {
    xl <- as.numeric(unlist(x_limits))
  }
  yl <- if (is.null(y_limits)) c(0.5, n + 0.5) else as.numeric(unlist(y_limits))
  labs <- if (is.null(row_labels)) row_order else {
    rl <- unlist(row_labels)
    ifelse(row_order %in% names(rl), rl[row_order], row_order)
  }
  txt <- if (is.null(label)) NULL else FormatTemplate(label, data)
  p <- ggplot2::ggplot(d)
  if (marker == "colour") {
    p <- p + ggplot2::geom_vline(xintercept = 0, colour = style$colour$reference, linewidth = PtLinewidth(0.5),
                                 linetype = "32") +
      ggplot2::geom_segment(ggplot2::aes(x = 0, xend = .data$est, y = .data$y, yend = .data$y), colour = d$colour,
                            linewidth = PtLinewidth(linewidth), lineend = "butt") +
      ggplot2::geom_point(ggplot2::aes(.data$est, .data$y), colour = d$colour, shape = 16,
                          size = .figA_size_filled(point_size, 1), stroke = 0)
    text_colour <- d$colour
  } else {
    e <- .figA_size_edged(open_size, open_stroke)
    p <- p + ggplot2::geom_segment(ggplot2::aes(x = 0, xend = .data$est, y = .data$y, yend = .data$y),
                                   colour = .figA_col(segment_colour, style), linewidth = PtLinewidth(linewidth),
                                   lineend = "butt") +
      ggplot2::geom_point(data = d[!sig, , drop = FALSE], ggplot2::aes(.data$est, .data$y), shape = 21,
                          fill = "white", colour = .figA_col(open_colour, style), size = e$size, stroke = e$stroke) +
      ggplot2::geom_point(data = d[sig, , drop = FALSE], ggplot2::aes(.data$est, .data$y), shape = 16,
                          colour = .figA_col(significant_colour, style), size = .figA_size_filled(point_size, 1),
                          stroke = 0) +
      ggplot2::geom_vline(xintercept = 0, colour = style$colour$reference, linewidth = PtLinewidth(0.6))
    text_colour <- ifelse(sig, style$colour$ink, style$colour$muted)
  }
  if (!is.null(txt)) {
    p <- p + .figA_text_layer(data.frame(x = Inf, y = d$y, label = txt, dx_npc = label_x - 1, hjust = 0, vjust = 0.5,
                                         fontsize = label_size, colour = text_colour), style)
  }
  if (!is.null(label_title)) {
    p <- p + .figA_text_layer(data.frame(x = Inf, y = n + 0.9, label = label_title, dx_npc = label_x - 1, hjust = 0,
                                         vjust = 0, fontsize = label_title_size, colour = style$colour$muted), style)
  }
  p + .figA_scale("x", xl, x_breaks, x_nbins, box_mm = box_mm) +
    ggplot2::scale_y_continuous(limits = yl, breaks = n:1, labels = .figA_tick_labels(labs),
                                expand = c(0, 0), oob = .figA_keep) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = .figA_axis_title(x_label), y = NULL) +
    .figA_theme(style, grid = grid, tick_size_y = tick_size_y, title_size_x = title_size)
}

#' Volcano Plot of Exact Group Tests
#'
#' Effect size against minus log10 of the exact P value for one family of
#' tests: open grey symbols for P at or above `alpha`, filled symbols below
#' it, labels for the `top` smallest nominal P values, a grey line at
#' P = `alpha` and a dashed line at the lower bound of the exact P value
#' (from `stats`, see [PlotDataContrastSummary()]).
#'
#' @param data Test table, one row per endpoint.
#' @param stats Optional one-row table with the bound column.
#' @param effect,p Columns of the effect size and the P value.
#' @param label Optional column with display labels of the endpoints.
#' @param alpha Nominal threshold.
#' @param top Number of labelled endpoints.
#' @param bound Column of `stats` with the lower bound of P.
#' @param bound_label Template written at the bound line.
#' @param bound_colour Colour of the bound line and text.
#' @param open_size,open_edge,open_colour Open symbols (area, edge, colour).
#' @param filled_size,filled_colour Filled symbols (area; drawn with a 1 pt
#'   edge of the same colour as in common figure code).
#' @param label_size,bound_label_size Text sizes.
#' @param x_limits,y_limits Axis limits.
#' @param x_nbins,y_nbins Tick intervals.
#' @param x_label Axis title; by default "Cliff's \eqn{\delta}{delta}" (drawn with the
#'   Greek letter). An explicit `NULL` draws no title.
#' @param y_label Axis title; `NULL` gives a typeset "-log10 exact P".
#' @param show_y_label Draw the y axis title.
#' @param box_mm Size of the data area `c(width, height)` in millimetres, passed
#'   by [RenderFigure()]; used by `"auto"` tick intervals (see [NiceBreaks()]).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' t <- data.frame(d = c(-0.9, 0.2, 0.7, -0.1), p = c(0.02, 0.6, 0.04, 0.9),
#'                 name = c("e1", "e2", "e3", "e4"))
#' p <- PlotVolcano(t, stats = data.frame(p_bound = 0.0048), effect = "d", label = "name")
#' @export
PlotVolcano <- function(data, stats = NULL, effect = "cliffs_delta", p = "p", label = NULL, alpha = 0.05, top = 3,
                        bound = "p_bound", bound_label = "Minimum attainable p = {p_bound|p}",
                        bound_colour = "minimum_p", open_size = 8, open_edge = 0.6, open_colour = "open_edge",
                        filled_size = 11, filled_colour = "ink", label_size = 4.3, bound_label_size = 4.4,
                        x_limits = c(-1.08, 1.08), y_limits = c(0, 3.2), x_nbins = 6, y_nbins = 9,
                        x_label = NULL, y_label = NULL, show_y_label = TRUE, box_mm = NULL, style = ManuscriptStyle()) {
  if (missing(x_label)) x_label <- "Cliff's \u03b4"
  style <- .fig_check_style(style)
  .fig_require_columns(data, c(effect, p, label))
  data <- as.data.frame(data, check.names = FALSE)
  d <- data.frame(x = as.numeric(data[[effect]]), p = as.numeric(data[[p]]),
                  label = if (is.null(label)) NA_character_ else as.character(data[[label]]))
  d <- d[is.finite(d$p) & is.finite(d$x), , drop = FALSE]
  d$y <- -log10(d$p)
  nominal <- d$p < alpha
  k <- style$colour
  oe <- .figA_size_edged(open_size, open_edge)
  vis <- .figA_inside(d$x, d$y, x_limits, y_limits)
  p <- ggplot2::ggplot() +
    ggplot2::geom_hline(yintercept = -log10(alpha), colour = k$reference, linewidth = PtLinewidth(0.5)) +
    ggplot2::geom_point(data = d[!nominal & vis, , drop = FALSE], ggplot2::aes(.data$x, .data$y), shape = 21,
                        fill = "white", colour = .figA_col(open_colour, style), size = oe$size, stroke = oe$stroke) +
    ggplot2::geom_point(data = d[nominal & vis, , drop = FALSE], ggplot2::aes(.data$x, .data$y), shape = 16,
                        colour = .figA_col(filled_colour, style), size = .figA_size_filled(filled_size, 1),
                        stroke = 0)
  if (!is.null(label) && top > 0 && any(nominal)) {
    t <- d[nominal, , drop = FALSE]
    t <- utils::head(t[order(t$p, method = "radix"), , drop = FALSE], top)
    right <- t$x >= 0.5
    p <- p + .figA_text_layer(data.frame(x = t$x + ifelse(right, -0.05, 0.05), y = t$y + 0.05, label = t$label,
                                         hjust = ifelse(right, 1, 0), vjust = 0, fontsize = label_size,
                                         colour = k$ink), style)
  }
  if (!is.null(stats)) {
    .fig_require_columns(stats, bound, "stats")
    pb <- as.numeric(stats[[bound]][1])
    if (is.finite(pb) && pb > 0) {
      yb <- -log10(pb)
      bc <- .figA_col(bound_colour, style)
      crowded <- any(nominal & d$x < 0 & abs(d$y - yb) < 0.5)
      p <- p + ggplot2::geom_hline(yintercept = yb, colour = bc, linewidth = PtLinewidth(0.6), linetype = "32")
      if (!is.null(bound_label)) {
        p <- p + .figA_text_layer(data.frame(x = -1.02, y = yb + if (crowded) 0.04 else -0.05,
                                             label = .figA_note(bound_label, stats), hjust = 0,
                                             vjust = if (crowded) 0 else 1, fontsize = bound_label_size,
                                             colour = bc), style)
      }
    }
  }
  ylab <- if (!show_y_label) NULL else if (!is.null(y_label)) TypesetLabel(y_label) else if (.fig_has_rich_text()) {
    "\u2212log<sub>10</sub> exact <i>P</i>"
  } else {
    "\u2212log\u2081\u2080 exact P"
  }
  p + .figA_scale("x", x_limits, NULL, x_nbins, box_mm = box_mm) + .figA_scale("y", y_limits, NULL, y_nbins, box_mm = box_mm) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = .figA_axis_title(x_label), y = ylab) +
    .figA_theme(style, grid = "y", title_size = 5.6)
}
