# Curve builders: summary curves with bands over a continuous axis, and
# per-unit profiles or summaries over ordered categories (distance bands).

#' Summary Curves with Quantile Bands
#'
#' Draws one curve per series over a continuous axis (for example the
#' median across patients of a cumulative distance distribution) with an
#' optional band between lower and upper quantiles, an optional dashed
#' reference line, direct series labels and a corner note written from the
#' data. With `facet`, draws a grid of small multiples with identical axes
#' and a coloured title above each panel.
#'
#' @param data Tidy data: one row per series (and facet) and x value.
#' @param x,y Columns of the x value and the curve value.
#' @param lower,upper Optional band columns.
#' @param series Series column.
#' @param series_order Drawing order of the series (later on top).
#' @param colours Named colours per series.
#' @param linewidth Curve width in points.
#' @param band_alpha Band opacity.
#' @param labels Optional named direct labels per series.
#' @param label_at x value at which direct labels are placed; the label sits
#'   `label_dx` x units to the right of the curve value there.
#' @param label_dx,label_size Label offset (x units) and size (points).
#' @param reference_x Optional x of a dashed vertical reference line.
#' @param reference_linewidth Its width in points.
#' @param x_limits,y_limits Axis limits (automatic with 5% margins when
#'   `NULL`).
#' @param x_breaks,y_breaks Optional tick positions; by default chosen as
#'   by the automatic locator of common figure code with at most `x_nbins`
#'   and `y_nbins` intervals.
#' @param x_nbins,y_nbins Maximum numbers of tick intervals.
#' @param x_label,y_label Axis titles.
#' @param tick_size Tick label size in points.
#' @param note Optional template (see [FormatTemplate()]) filled from the
#'   first row of `data`, drawn at `note_xy` (panel fractions).
#' @param note_xy,note_hjust,note_vjust,note_size,note_colour Note placement
#'   and style.
#' @param facet Optional column defining small multiples.
#' @param facet_order Order of the facets (row by row).
#' @param facet_ncol Number of columns.
#' @param facet_gap_mm Gaps between neighbouring panels in millimetres
#'   (horizontal, vertical), measured between the data areas.
#' @param facet_data Optional data frame with one row per facet (column
#'   `facet`) used for titles.
#' @param facet_title,facet_note Templates written above each panel: a bold
#'   title coloured by `facet_group` and a smaller muted note to its right.
#' @param facet_group Column of `facet_data` whose value selects the title
#'   colour from `group_colours`.
#' @param group_colours Named colours per group.
#' @param facet_title_size,facet_note_size Sizes in points.
#' @param box_mm Size of the data area `c(width, height)` in millimetres, passed
#'   by [RenderFigure()]; used by `"auto"` tick intervals (see [NiceBreaks()]).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' d <- data.frame(series = rep(c("a", "b"), each = 4), x = rep(c(0, 10, 20, 30), 2),
#'                 median = c(0, 40, 70, 90, 0, 20, 45, 70), lower = c(0, 30, 60, 85, 0, 10, 35, 60),
#'                 upper = c(0, 50, 80, 95, 0, 30, 55, 80), n = 5)
#' PlotQuantileCurves(d, colours = c(a = "#7B2FBE", b = "#3B7DD8"), reference_x = 20,
#'                    labels = c(a = "Series a", b = "Series b"), label_at = 10,
#'                    note = "Median and IQR\nn = {n|d} units")
#' @export
PlotQuantileCurves <- function(data, x = "x", y = "median", lower = NULL, upper = NULL, series = "series",
                               series_order = NULL, colours = NULL, linewidth = 1.4, band_alpha = 0.15,
                               labels = NULL, label_at = NULL, label_dx = 3, label_size = 5.3,
                               reference_x = NULL, reference_linewidth = 0.5,
                               x_limits = NULL, y_limits = NULL, x_breaks = NULL, y_breaks = NULL,
                               x_nbins = 6, y_nbins = 9, x_label = NULL, y_label = NULL, tick_size = NULL,
                               note = NULL, note_xy = c(0.97, 0.04), note_hjust = 1, note_vjust = 0,
                               note_size = 5, note_colour = "muted",
                               facet = NULL, facet_order = NULL, facet_ncol = 4, facet_gap_mm = c(5, 5),
                               facet_data = NULL, facet_title = NULL, facet_note = NULL, facet_group = NULL,
                               group_colours = NULL, facet_title_size = 5.6, facet_note_size = 4.6,
                               box_mm = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  .fig_require_columns(data, c(x, y, lower, upper, series, facet))
  if (xor(is.null(lower), is.null(upper))) stop("Give both lower and upper or neither.", call. = FALSE)
  data <- as.data.frame(data, check.names = FALSE)
  if (is.null(series_order)) series_order <- unique(as.character(data[[series]]))
  d <- data.frame(x = as.numeric(data[[x]]), y = as.numeric(data[[y]]),
                  series = factor(as.character(data[[series]]), levels = series_order))
  if (!is.null(lower)) {
    d$lower <- as.numeric(data[[lower]])
    d$upper <- as.numeric(data[[upper]])
  }
  if (!is.null(facet)) {
    if (is.null(facet_order)) facet_order <- unique(as.character(data[[facet]]))
    d$facet <- factor(as.character(data[[facet]]), levels = facet_order)
    d <- d[!is.na(d$facet), , drop = FALSE]
  }
  d <- d[!is.na(d$series), , drop = FALSE]
  d <- d[order(d$series, d$x), , drop = FALSE]
  cols <- .figA_lookup(series_order, colours, style$colour$ink, style)
  names(cols) <- series_order
  xl <- .figA_limits(c(d$x, reference_x), x_limits)
  yl <- .figA_limits(c(d$y, d$lower, d$upper), y_limits)
  d$key <- if (is.null(facet)) as.character(d$series) else paste(d$facet, d$series, sep = "\r")
  p <- ggplot2::ggplot()
  if (!is.null(lower)) {
    rib <- do.call(rbind, lapply(unique(d$key), function(kk) {
      z <- d[d$key == kk, , drop = FALSE]
      r <- .figA_clip_ribbon(z$x, z$lower, z$upper, xl, yl)
      if (!nrow(r)) return(NULL)
      r$series <- z$series[1]
      r$key <- kk
      if (!is.null(facet)) r$facet <- z$facet[1]
      r
    }))
    p <- p + ggplot2::geom_ribbon(data = rib, ggplot2::aes(.data$x, ymin = .data$lower, ymax = .data$upper,
                                                           fill = .data$series, group = .data$key),
                                  alpha = band_alpha, colour = NA) +
      ggplot2::scale_fill_manual(values = cols, guide = "none")
  }
  lines <- .figA_clip_path(d, xl, yl, group = "key")
  p <- p + ggplot2::geom_path(data = lines, ggplot2::aes(.data$x, .data$y, colour = .data$series, group = .data$piece),
                              linewidth = PtLinewidth(linewidth), lineend = "round", linejoin = "round") +
    ggplot2::scale_colour_manual(values = cols, guide = "none")
  if (!is.null(reference_x)) {
    p <- p + ggplot2::geom_vline(xintercept = reference_x, colour = style$colour$reference,
                                 linewidth = PtLinewidth(reference_linewidth), linetype = "32")
  }
  if (!is.null(labels) && !is.null(label_at)) {
    labels <- unlist(labels)
    lab <- do.call(rbind, lapply(names(labels), function(s) {
      z <- d[as.character(d$series) == s, , drop = FALSE]
      if (!nrow(z)) return(NULL)
      i <- which.min(abs(z$x - label_at))
      data.frame(x = z$x[i] + label_dx, y = z$y[i], label = labels[[s]], hjust = 0, vjust = 0.5,
                 fontsize = label_size, colour = style$colour$ink, stringsAsFactors = FALSE)
    }))
    p <- p + .figA_text_layer(lab, style)
  }
  if (!is.null(note)) {
    p <- p + .figA_text_layer(.figA_npc_text(.figA_note(note, data), note_xy[1], note_xy[2], note_hjust,
                                             note_vjust, note_size, .figA_col(note_colour, style)), style)
  }
  p <- p + .figA_scale("x", xl, x_breaks, x_nbins, box_mm = box_mm) + .figA_scale("y", yl, y_breaks, y_nbins, box_mm = box_mm) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = .figA_axis_title(x_label), y = .figA_axis_title(y_label)) +
    .figA_theme(style, grid = "y", tick_size = tick_size)
  if (!is.null(facet)) {
    p <- .figA_facets(p, d, facet_order, facet_ncol, facet_gap_mm, facet_data, facet, facet_title, facet_note,
                      facet_group, group_colours, facet_title_size, facet_note_size, style)
  }
  p
}

# Small multiples with axes on every panel, tick labels on the outer panels,
# titles drawn above each panel and data areas separated by fixed gaps.
.figA_facets <- function(p, d, facet_order, ncol, gap_mm, facet_data, facet, title, note, group, group_colours,
                         title_size, note_size, style) {
  gap_mm <- rep_len(as.numeric(unlist(gap_mm)), 2L)
  tick <- grid::unit(style$line$tick_length, "pt")
  fw <- if (utils::packageVersion("ggplot2") >= "3.5.0") {
    ggplot2::facet_wrap(ggplot2::vars(.data$facet), ncol = ncol, axes = "all", axis.labels = "margins")
  } else {
    ggplot2::facet_wrap(ggplot2::vars(.data$facet), ncol = ncol)
  }
  p <- p + fw + ggplot2::theme(strip.text = ggplot2::element_blank(), strip.background = ggplot2::element_blank(),
                               panel.spacing.x = grid::unit(gap_mm[1], "mm") - tick,
                               panel.spacing.y = grid::unit(gap_mm[2], "mm") - tick)
  if (!is.null(facet_data) && (!is.null(title) || !is.null(note))) {
    fd <- as.data.frame(facet_data, check.names = FALSE)
    .fig_require_columns(fd, c(facet, group), "facet_data")
    fd <- fd[as.character(fd[[facet]]) %in% facet_order, , drop = FALSE]
    rows <- list()
    if (!is.null(title)) {
      ttl <- FormatTemplate(title, fd)
      col <- if (is.null(group)) rep(style$colour$ink, nrow(fd)) else
        .figA_lookup(fd[[group]], group_colours, style$colour$ink, style)
      rows$title <- data.frame(facet = fd[[facet]], label = ttl, dx = 0, colour = col, fontsize = title_size,
                               bold = TRUE, stringsAsFactors = FALSE)
    }
    if (!is.null(note)) {
      ttl <- if (is.null(title)) rep("", nrow(fd)) else FormatTemplate(title, fd)
      rows$note <- data.frame(facet = fd[[facet]], label = FormatTemplate(note, fd),
                              dx = nchar(ttl) * title_size * 0.7 + 4, colour = style$colour$muted,
                              fontsize = note_size, bold = FALSE, stringsAsFactors = FALSE)
    }
    tl <- do.call(rbind, rows)
    tl$facet <- factor(as.character(tl$facet), levels = facet_order)
    tl$x <- -Inf
    tl$y <- Inf
    tl$dy_npc <- 0.025
    tl$hjust <- 0
    tl$vjust <- 0
    p <- p + .figA_text_layer(tl, style)
  }
  p
}

#' Profiles over Ordered Categories
#'
#' Two forms for values over ordered categories such as distance bands.
#' Without `lower` and `upper`: one thin line per unit (patient) coloured by
#' its group, a thick summary line of the medians, and values of `-Inf`
#' (for example the log ratio of an empty band) drawn as open triangles at
#' `floor`. With `lower` and `upper`: one summary line per series with
#' vertical interval segments, series side by side within each category.
#'
#' @param data Tidy data: one row per unit (or series) and category.
#' @param x Category column.
#' @param y Value column.
#' @param series Unit (or series) column.
#' @param group Group column of the units (profile form).
#' @param x_order Category order; `x_labels` their tick labels.
#' @param x_labels Tick labels.
#' @param group_colours Named colours per group.
#' @param floor Value at which `-Inf` is drawn; `floor_label` is written to
#'   the right of the last category at that height.
#' @param floor_label,floor_size Text and size of the floor note.
#' @param linewidth,line_alpha,marker_size Unit lines (points; marker
#'   diameter as for line markers with a 1 pt edge).
#' @param summary Draw the median line (profile form).
#' @param summary_colour,summary_linewidth,summary_marker Median line style.
#' @param lower,upper Interval columns (summary form).
#' @param series_order,colours Series order and named colours (summary
#'   form).
#' @param dodge Offset between series within a category.
#' @param interval_linewidth,interval_alpha Interval segment style.
#' @param reference_y Optional horizontal reference line.
#' @param y_limits,y_breaks,y_nbins y axis (see [PlotQuantileCurves()]).
#' @param x_label,y_label Axis titles.
#' @param tick_size Tick label size.
#' @param box_mm Size of the data area `c(width, height)` in millimetres, passed
#'   by [RenderFigure()]; used by `"auto"` tick intervals (see [NiceBreaks()]).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' d <- data.frame(patient = rep(c("p1", "p2", "p3"), each = 3), group = rep(c("A", "B", "A"), each = 3),
#'                 band = rep(c("near", "mid", "far"), 3), value = c(1, 0, -1, 2, -Inf, -2, 0.5, 0.2, -0.5))
#' PlotBandProfiles(d, x_order = c("near", "mid", "far"), floor = -3,
#'                  group_colours = c(A = "#009E73", B = "#0072B2"), floor_label = "none")
#' @export
PlotBandProfiles <- function(data, x = "band", y = "value", series = "patient", group = "group",
                             x_order = NULL, x_labels = NULL, group_colours = NULL, floor = NULL,
                             floor_label = NULL, floor_size = 4.6, linewidth = 0.6, line_alpha = 0.7,
                             marker_size = 1.8, summary = TRUE, summary_colour = "ink", summary_linewidth = 1.6,
                             summary_marker = 3, lower = NULL, upper = NULL, series_order = NULL, colours = NULL,
                             dodge = 0.12, interval_linewidth = 1, interval_alpha = 0.6, reference_y = NULL,
                             y_limits = NULL, y_breaks = NULL, y_nbins = 9, x_label = NULL, y_label = NULL,
                             tick_size = NULL, box_mm = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  interval <- !is.null(lower) || !is.null(upper)
  if (interval && (is.null(lower) || is.null(upper))) stop("Give both lower and upper.", call. = FALSE)
  .fig_require_columns(data, c(x, y, series, if (!interval) group, lower, upper))
  data <- as.data.frame(data, check.names = FALSE)
  if (is.null(x_order)) x_order <- unique(as.character(data[[x]]))
  if (is.null(x_labels)) x_labels <- x_order
  k <- style$colour
  d <- data.frame(xi = match(as.character(data[[x]]), x_order), y = as.numeric(data[[y]]),
                  series = as.character(data[[series]]))
  keep <- !is.na(d$xi)
  d <- d[keep, , drop = FALSE]
  p <- ggplot2::ggplot()
  if (!interval) {
    d$group <- as.character(data[[group]])[keep]
    d$colour <- .figA_lookup(d$group, group_colours, k$ink, style)
    empty <- is.infinite(d$y) & d$y < 0
    if (any(empty) && is.null(floor)) stop("Values of -Inf need a floor.", call. = FALSE)
    d$shown <- ifelse(empty, floor, d$y)
    d$empty <- empty
    units <- unique(d$series)
    d <- d[order(match(d$series, units), d$xi), , drop = FALSE]
    med <- stats::aggregate(y ~ xi, d, stats::median, na.action = stats::na.pass)
    xl <- range(d$xi) + c(-1, 1) * 0.05 * diff(range(d$xi))
    yl <- .figA_limits(c(d$shown, med$y, reference_y), y_limits)
    sc <- .figA_col(summary_colour, style)
    lines <- .figA_clip_path(d[!is.na(d$shown), , drop = FALSE], xl, yl, x = "xi", y = "shown", group = "series")
    pts <- d[!d$empty & .figA_inside(d$xi, d$shown, xl, yl), , drop = FALSE]
    e <- d[d$empty, , drop = FALSE]
    tri <- .figA_size_triangle(14, 0.7)
    for (u in units) {
      z <- lines[lines$series == u, , drop = FALSE]
      zp <- pts[pts$series == u, , drop = FALSE]
      if (nrow(z)) {
        p <- p + ggplot2::geom_path(data = z, ggplot2::aes(.data$xi, .data$shown, group = .data$piece),
                                    colour = z$colour[1], linewidth = PtLinewidth(linewidth), alpha = line_alpha)
      }
      if (nrow(zp)) {
        p <- p + ggplot2::geom_point(data = zp, ggplot2::aes(.data$xi, .data$shown), colour = zp$colour[1],
                                     alpha = line_alpha, shape = 16, size = .figA_size_marker(marker_size), stroke = 0)
      }
    }
    if (nrow(e)) {
      p <- p + ggplot2::geom_point(data = e, ggplot2::aes(.data$xi, .data$shown), shape = 25, fill = "white",
                                   colour = e$colour, size = tri$size, stroke = tri$stroke)
    }
    if (summary) {
      ml <- .figA_clip_path(med, xl, yl, x = "xi", y = "y")
      p <- p + ggplot2::geom_path(data = ml, ggplot2::aes(.data$xi, .data$y, group = .data$piece), colour = sc,
                                  linewidth = PtLinewidth(summary_linewidth)) +
        ggplot2::geom_point(data = med[.figA_inside(med$xi, med$y, xl, yl), , drop = FALSE],
                            ggplot2::aes(.data$xi, .data$y), colour = sc, shape = 16,
                            size = .figA_size_marker(summary_marker), stroke = 0)
    }
    if (!is.null(floor_label) && !is.null(floor)) {
      p <- p + .figA_text_layer(data.frame(x = length(x_order) + 0.1, y = floor, label = floor_label,
                                           hjust = 0, vjust = 0.5, fontsize = floor_size, colour = k$muted), style)
    }
  } else {
    d$lower <- as.numeric(data[[lower]])[keep]
    d$upper <- as.numeric(data[[upper]])[keep]
    if (is.null(series_order)) series_order <- unique(d$series)
    cols <- .figA_lookup(series_order, colours, k$ink, style)
    names(cols) <- series_order
    off <- (seq_along(series_order) - (length(series_order) + 1) / 2) * dodge
    d$xd <- d$xi + off[match(d$series, series_order)]
    d$series <- factor(d$series, levels = series_order)
    d <- d[!is.na(d$series), , drop = FALSE]
    d <- d[order(d$series, d$xi), , drop = FALSE]
    xl <- range(d$xd) + c(-1, 1) * 0.05 * diff(range(d$xd))
    yl <- .figA_limits(c(d$lower, d$upper, d$y, reference_y), y_limits)
    seg <- d
    seg$lower <- pmin(pmax(seg$lower, yl[1]), yl[2])
    seg$upper <- pmin(pmax(seg$upper, yl[1]), yl[2])
    lines <- .figA_clip_path(d, xl, yl, x = "xd", y = "y", group = "series")
    p <- p + ggplot2::geom_segment(data = seg, ggplot2::aes(x = .data$xd, xend = .data$xd, y = .data$lower,
                                                            yend = .data$upper, colour = .data$series),
                                   linewidth = PtLinewidth(interval_linewidth), alpha = interval_alpha,
                                   na.rm = TRUE) +
      ggplot2::geom_path(data = lines, ggplot2::aes(.data$xd, .data$y, colour = .data$series, group = .data$piece),
                         linewidth = PtLinewidth(summary_linewidth)) +
      ggplot2::geom_point(data = d[.figA_inside(d$xd, d$y, xl, yl), , drop = FALSE],
                          ggplot2::aes(.data$xd, .data$y, colour = .data$series), shape = 16,
                          size = .figA_size_marker(summary_marker), stroke = 0) +
      ggplot2::scale_colour_manual(values = cols, guide = "none")
  }
  if (!is.null(reference_y)) {
    p <- p + ggplot2::geom_hline(yintercept = reference_y, colour = k$reference,
                                 linewidth = PtLinewidth(style$line$grid))
  }
  p + ggplot2::scale_x_continuous(limits = xl, breaks = seq_along(x_order), labels = .figA_tick_labels(x_labels),
                                  expand = c(0, 0), oob = .figA_keep) +
    .figA_scale("y", yl, y_breaks, y_nbins, box_mm = box_mm) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(x = .figA_axis_title(x_label), y = .figA_axis_title(y_label)) +
    .figA_theme(style, grid = "y", tick_size = tick_size)
}
