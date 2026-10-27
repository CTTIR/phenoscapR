# Patient-level plot builders. Inputs are tidy plot data with one row per
# patient and condition; every builder returns a 'ggplot2' object styled by
# ManuscriptStyle() and leaves headings, letters and notes to ComposeFigure().

# Marker diameter in points to 'ggplot2' size (filled circle, shape 16).
.fig_point <- function(diameter_pt) diameter_pt / ggplot2::.pt / 0.75

# matplotlib scatter area (pt^2) to 'ggplot2' size.
.fig_area <- function(s) .fig_point(sqrt(s))

.fig_require_columns <- function(data, columns, what = "data") {
  if (!is.data.frame(data)) stop(what, " must be a data frame.", call. = FALSE)
  missing <- setdiff(columns[!is.na(columns)], names(data))
  if (length(missing)) stop(what, " lacks column(s): ", paste(missing, collapse = ", "), call. = FALSE)
  invisible(data)
}

.fig_group_scale <- function(colours, aesthetic = "colour") {
  if (is.null(colours)) return(NULL)
  ggplot2::scale_discrete_manual(aesthetics = aesthetic, values = colours, guide = "none")
}

.fig_labels <- function(x) TypesetLabel(as.character(x))

#' Paired Patient Lines
#'
#' One line per patient across ordered conditions, coloured by clinical
#' group, with a short bold bar at the median of each condition. Patients
#' flagged in `excluded` are drawn dashed with open symbols and are left out
#' of the medians, as patients not included in a test.
#'
#' @param data Tidy data: one row per patient and condition.
#' @param patient,group,condition,value Column names.
#' @param conditions Condition order; defaults to first appearance.
#' @param labels Tick labels for the conditions; default `conditions`.
#' @param excluded Optional logical column marking patients outside the test.
#' @param group_colours Named colours per group level.
#' @param log_y Logarithmic y axis.
#' @param y_label,x_label Axis titles.
#' @param y_limits Optional y limits.
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' d <- data.frame(patient = rep(c("p1", "p2", "p3"), each = 2),
#'                 group = rep(c("A", "B", "A"), each = 2),
#'                 condition = rep(c("x", "y"), 3), value = c(3, 5, 2, 6, 4, 4.5))
#' PlotPairedPatients(d, group_colours = c(A = "#009E73", B = "#0072B2"))
#' @export
PlotPairedPatients <- function(data, patient = "patient", group = "group",
                               condition = "condition", value = "value",
                               conditions = NULL, labels = NULL, excluded = NULL,
                               group_colours = NULL, log_y = FALSE, y_label = NULL,
                               x_label = NULL, y_limits = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  .fig_require_columns(data, c(patient, group, condition, value, excluded))
  if (is.null(conditions)) conditions <- unique(as.character(data[[condition]]))
  if (is.null(labels)) labels <- conditions
  d <- data.frame(patient = as.character(data[[patient]]), group = as.character(data[[group]]),
                  x = match(as.character(data[[condition]]), conditions),
                  value = as.numeric(data[[value]]),
                  excluded = if (is.null(excluded)) FALSE else as.logical(data[[excluded]]))
  d <- d[!is.na(d$x), , drop = FALSE]
  d <- d[order(d$patient, d$x), , drop = FALSE]
  if (log_y) d$value[!(d$value > 0)] <- NA_real_
  tested <- d[!d$excluded, , drop = FALSE]
  med <- stats::aggregate(value ~ x, tested, stats::median, na.action = stats::na.omit)
  k <- style$colour
  ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$value, group = .data$patient, colour = .data$group)) +
    ggplot2::geom_line(data = d[d$excluded, , drop = FALSE], linewidth = PtLinewidth(0.5),
                       linetype = "22", alpha = 0.85, na.rm = TRUE) +
    ggplot2::geom_point(data = d[d$excluded, , drop = FALSE], shape = 21, fill = "white",
                        size = .fig_area(7), stroke = PtLinewidth(0.6), na.rm = TRUE) +
    ggplot2::geom_line(data = tested, linewidth = PtLinewidth(0.6), alpha = 0.85, na.rm = TRUE) +
    ggplot2::geom_point(data = tested, shape = 16, size = .fig_area(7), na.rm = TRUE) +
    ggplot2::geom_segment(data = med, ggplot2::aes(x = .data$x - 0.2, xend = .data$x + 0.2,
                                                   y = .data$value, yend = .data$value),
                          inherit.aes = FALSE, colour = k$ink, linewidth = PtLinewidth(1.3)) +
    ggplot2::scale_x_continuous(breaks = seq_along(conditions), labels = .fig_labels(labels),
                                limits = c(0.6, length(conditions) + 0.4), expand = c(0, 0)) +
    (if (log_y) ggplot2::scale_y_log10(limits = y_limits) else ggplot2::scale_y_continuous(limits = y_limits)) +
    .fig_group_scale(group_colours) +
    ggplot2::labs(x = if (is.null(x_label)) NULL else TypesetLabel(x_label),
                  y = if (is.null(y_label)) NULL else TypesetLabel(y_label)) +
    ThemeManuscript(style, grid = "y")
}
