# Matrix grammars: annotated heatmaps, dot matrices and alteration
# matrices. Rows run from top to bottom, columns from left to right; row
# and column labels are drawn as figure tick labels (rotated labels end at
# their tick) so that the data area fills the panel box exactly.

# Row and column positions of long matrix data.
.figb_matrix <- function(data, row, column, rows, columns, row_order_by = NULL, column_order_by = NULL) {
  .fig_require_columns(data, c(row, column, row_order_by, column_order_by))
  if (is.null(rows) && !is.null(row_order_by)) {
    o <- unique(data[order(data[[row_order_by]]), c(row, row_order_by)])
    rows <- as.character(o[[row]])
  }
  if (is.null(columns) && !is.null(column_order_by)) {
    o <- unique(data[order(data[[column_order_by]]), c(column, column_order_by)])
    columns <- as.character(o[[column]])
  }
  rows <- .figb_levels(rows, data[[row]])
  columns <- .figb_levels(columns, data[[column]])
  i <- match(as.character(data[[row]]), rows)
  j <- match(as.character(data[[column]]), columns)
  keep <- !is.na(i) & !is.na(j)
  list(data = data[keep, , drop = FALSE], i = i[keep], j = j[keep], rows = rows, columns = columns)
}

# Row annotation boxes left of the matrix: box c(left, width, height) in
# column units, left measured from the centre of the first column.
.figb_row_boxes <- function(colours, rows, box, nr, style) {
  if (is.null(colours)) return(NULL)
  colours <- .figb_colours(colours, rows, NA_character_, style)
  col <- colours
  ok <- !is.na(col)
  if (!any(ok)) return(NULL)
  box <- unlist(box)
  y <- nr - seq_along(rows) + 1
  d <- data.frame(xmin = 1 + box[1], xmax = 1 + box[1] + box[2], ymin = y - box[3] / 2,
                  ymax = y + box[3] / 2, fill = col)[ok, , drop = FALSE]
  ggplot2::geom_rect(data = d, ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax, ymin = .data$ymin,
                                            ymax = .data$ymax), fill = d$fill, colour = NA,
                     inherit.aes = FALSE)
}

# Bottom (column) and left (row) labels plus an optional axis title below.
.figb_matrix_labels <- function(style, columns, rows, xlim, ylim, column_labels = NULL, row_labels = NULL,
                                show_columns = TRUE, show_rows = TRUE, column_angle = 0, column_size = 5.1,
                                column_pad = 3.5, column_colours = NULL, column_fills = NULL,
                                column_fill_alpha = 0.55, column_box_pad = 0.12, row_size = 5.3,
                                row_pad = 3.5, row_italic = FALSE, row_colours_text = NULL,
                                x_label = NULL, x_label_size = 5, x_label_pad = 2) {
  layers <- list()
  nc <- length(columns)
  nr <- length(rows)
  if (show_columns && nc) {
    at <- (seq_len(nc) - xlim[1]) / diff(xlim)
    g <- .figb_tick_labels(.figb_display(column_labels, columns), at, style, size = column_size,
                           angle = column_angle, pad = column_pad,
                           colours = .figb_colours(column_colours, columns, style$colour$ink, style),
                           fills = if (is.null(column_fills)) NULL else .figb_colours(column_fills, columns, NA_character_, style),
                           fill_alpha = column_fill_alpha, box_pad = column_box_pad * column_size,
                           side = "bottom")
    layers <- c(layers, list(.figb_annotation(g)))
  }
  if (show_rows && nr) {
    at <- (nr - seq_len(nr) + 1 - ylim[1]) / diff(ylim)
    g <- .figb_tick_labels(.figb_display(row_labels, rows), at, style, size = row_size, pad = row_pad,
                           colours = .figb_colours(row_colours_text, rows, style$colour$ink, style),
                           side = "left", italic = row_italic)
    layers <- c(layers, list(.figb_annotation(g)))
  }
  if (!is.null(x_label) && nzchar(x_label)) {
    layers <- c(layers, list(.figb_annotation(.figb_axis_title(
      x_label, style, size = x_label_size, pad = x_label_pad,
      below = if (show_columns && nc) .figb_tick_labels(.figb_display(column_labels, columns),
                                                        (seq_len(nc) - xlim[1]) / diff(xlim), style,
                                                        size = column_size, angle = column_angle,
                                                        pad = column_pad, side = "bottom") else NULL
    ))))
  }
  layers
}

# Axis title centred below the tick labels in `below` (a tick label grob).
.figb_axis_title <- function(label, style, size = 5, pad = 2, below = NULL) {
  grid::gTree(label = label, style = style, size = size, pad = pad, below = below,
              cl = "phenoscapR_axistitle")
}

#' @exportS3Method grid::makeContent
makeContent.phenoscapR_axistitle <- function(x) {
  depth <- 0
  if (!is.null(x$below)) {
    b <- .figb_label_boxes(x$below)
    depth <- x$below$pad + max(c(0, b$bh))
  }
  g <- .figb_text_grob(x$label, grid::unit(0.5, "npc"), grid::unit(-depth - x$pad, "pt"), x$size,
                       x$style$colour$ink, x$style, hjust = 0.5, vjust = 1)
  grid::setChildren(x, grid::gList(g))
}

#' Annotated Heatmap
#'
#' Draws a matrix of coloured cells, optionally with the values printed in
#' the cells, coloured annotation boxes left of the rows, coloured or boxed
#' column labels and a colour bar. Colours follow a 256-step ramp between
#' the anchors of a named scale (`"blues"`, `"rdbu_r"`, `"rdbu"`, `"greys"`) or
#' of given colours, as image heatmaps of common figure code; values can be
#' coloured on a `log10(x + 1)` scale while the printed numbers stay raw.
#'
#' @param data Long data: one row per matrix cell.
#' @param row,column,value Column names.
#' @param rows,columns Row order (top to bottom) and column order (left to
#'   right): character vectors or data frames (ordered by a `rank` column if
#'   present); default first appearance.
#' @param row_order_by,column_order_by Optional numeric columns of `data`
#'   giving the row or column order.
#' @param row_labels,column_labels Display labels: named mapping or vector.
#' @param scale Colour scale name or vector of anchor colours.
#' @param limits Colour limits (on the transformed scale); default the range.
#' @param transform `"identity"` or `"log10p1"` (colour by `log10(x + 1)`).
#' @param fill_column Optional column with explicit cell colours (overrides `scale`).
#' @param missing_colour Colour of missing cells.
#' @param drop_columns_below Drop columns whose largest value is below this.
#' @param cell_text Optional list printing values in cells: `min` (smallest
#'   value printed), `format` (`"fixed"` with `digits`, or `"count"`: thousands
#'   separator and `"12k"` from `abbreviate` upwards), `white_above` (raw
#'   values above it are printed in `light_colour`), `size` (points).
#' @param row_colours Named colours of row annotation boxes.
#' @param row_box Box geometry `c(left, width, height)` in column units, left
#'   measured from the centre of the first column.
#' @param column_colours Named text colours of column labels.
#' @param column_fills Named colours of rounded boxes behind column labels.
#' @param column_fill_alpha Opacity of these boxes.
#' @param column_angle,column_size,column_pad Column label rotation (degrees),
#'   size and distance from the matrix (points).
#' @param row_size,row_pad,row_italic Row label size, distance and italics.
#' @param show_rows,show_columns Draw row or column labels.
#' @param x_label,x_label_size,x_label_pad Title below the column labels.
#' @param colourbar Optional list: `box` (`c(left, bottom, width, height)` in
#'   panel fractions), `title`, `breaks`, `labels`, `tick_size`, `title_size`.
#' @param texts Optional texts at panel fractions (list of `label`, `xy`,
#'   `size`, `colour`, `bold`, `hjust`, `vjust`, `angle`); labels may use
#'   [FormatTemplate()] placeholders filled from `values`.
#' @param values Optional data frame for text templates.
#' @param style A [ManuscriptStyle()] object.
#' @return A 'ggplot2' object.
#' @examples
#' d <- expand.grid(row = c("a", "b"), column = c("x", "y", "z"), stringsAsFactors = FALSE)
#' d$value <- c(85, 3, 9, 15, 2, 67)
#' PlotAnnotatedHeatmap(d, limits = c(0, 80), cell_text = list(min = 1, white_above = 45),
#'                      row_colours = c(a = "#e34948", b = "#eda100"))
#' @export
PlotAnnotatedHeatmap <- function(data, row = "row", column = "column", value = "value",
                                 rows = NULL, columns = NULL, row_order_by = NULL, column_order_by = NULL,
                                 row_labels = NULL, column_labels = NULL, scale = "blues", limits = NULL,
                                 transform = c("identity", "log10p1"), fill_column = NULL,
                                 missing_colour = "#EEEEEE", drop_columns_below = NULL, cell_text = NULL,
                                 row_colours = NULL, row_box = c(-1.05, 0.4, 0.7), column_colours = NULL,
                                 column_fills = NULL, column_fill_alpha = 0.55, column_angle = 0,
                                 column_size = 5.1, column_pad = 3.5, row_size = 5.3, row_pad = 3.5,
                                 row_italic = FALSE, show_rows = TRUE, show_columns = TRUE, x_label = NULL,
                                 x_label_size = 5, x_label_pad = 2, colourbar = NULL, texts = NULL,
                                 values = NULL, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  transform <- match.arg(transform)
  .fig_require_columns(data, c(row, column, value, fill_column))
  data <- as.data.frame(data)
  if (!is.null(drop_columns_below)) {
    mx <- tapply(as.numeric(data[[value]]), as.character(data[[column]]), max, na.rm = TRUE)
    data <- data[as.character(data[[column]]) %in% names(mx)[mx >= drop_columns_below], , drop = FALSE]
  }
  m <- .figb_matrix(data, row, column, rows, columns, row_order_by, column_order_by)
  nr <- length(m$rows)
  nc <- length(m$columns)
  v <- as.numeric(m$data[[value]])
  tv <- if (transform == "log10p1") log10(v + 1) else v
  if (is.null(limits)) limits <- range(tv, finite = TRUE)
  limits <- as.numeric(unlist(limits))
  lut <- .figb_ramp(scale)
  cols <- if (!is.null(fill_column)) as.character(m$data[[fill_column]]) else .figb_map_colours(tv, limits, lut, missing_colour)
  cells <- data.frame(x = m$j, y = nr - m$i + 1, fill = cols, value = v)
  xlim <- c(0.5, nc + 0.5)
  ylim <- c(0.5, nr + 0.5)
  p <- .figb_canvas(xlim, ylim, style) +
    ggplot2::geom_rect(data = cells, ggplot2::aes(xmin = .data$x - 0.5, xmax = .data$x + 0.5,
                                                  ymin = .data$y - 0.5, ymax = .data$y + 0.5),
                       fill = cells$fill, colour = NA, inherit.aes = FALSE)
  if (!is.null(cell_text)) {
    ct <- cell_text
    keep <- is.finite(cells$value) & cells$value >= (if (is.null(ct$min)) -Inf else ct$min)
    lab <- cells[keep, , drop = FALSE]
    fmt <- if (is.null(ct$format)) "fixed" else ct$format
    lab$text <- if (fmt == "count") {
      ab <- if (is.null(ct$abbreviate)) 10000 else ct$abbreviate
      ifelse(lab$value < ab, formatC(lab$value, format = "d", big.mark = ","),
             paste0(sprintf("%.0f", lab$value / 1000), "k"))
    } else {
      sprintf(paste0("%.", if (is.null(ct$digits)) 0 else ct$digits, "f"), lab$value)
    }
    light <- if (is.null(ct$light_colour)) "white" else .fig_colour(ct$light_colour, style)
    dark <- if (is.null(ct$colour)) style$colour$ink else .fig_colour(ct$colour, style)
    lab$colour <- ifelse(lab$value > (if (is.null(ct$white_above)) Inf else ct$white_above), light, dark)
    p <- p + ggplot2::geom_text(data = lab, ggplot2::aes(x = .data$x, y = .data$y, label = .data$text),
                                colour = lab$colour, size = .fig_text_size(if (is.null(ct$size)) 4.4 else ct$size),
                                family = style$family, inherit.aes = FALSE)
  }
  p <- p + .figb_row_boxes(row_colours, m$rows, row_box, nr, style)
  for (l in .figb_matrix_labels(style, m$columns, m$rows, xlim, ylim, column_labels, row_labels,
                                show_columns, show_rows, column_angle, column_size, column_pad,
                                column_colours, column_fills, column_fill_alpha, 0.12, row_size, row_pad,
                                row_italic, NULL, x_label, x_label_size, x_label_pad)) p <- p + l
  if (!is.null(colourbar)) p <- p + .figb_colourbar_layer(colourbar, lut, limits, style)
  if (!is.null(texts)) p <- p + .figb_texts_layer(texts, .figb_template_values(values, data, NULL), style)
  p
}

#' Dot Matrix
#'
#' One dot per row and column, its area growing with one measure (for
#' example the percentage of positive cells, as a figure scatter area
#' `area[1] + area[2] * size` in points squared) and its colour showing a
#' second (for example a z-scored signal on a diverging scale). Rows without
#' any value are dropped. Thin grid lines run through the dots and a light
#' frame surrounds the matrix; row annotation boxes, a colour bar and a size
#' key can be added outside it.
#'
#' @inheritParams PlotAnnotatedHeatmap
#' @param size,signal Columns with the size and colour measures.
#' @param area Scatter area `c(intercept, slope)` in squared points.
#' @param limits Colour limits; values are clipped to them.
#' @param edge_colour,edge_width Dot outline colour and width (points).
#' @param grid_colour,grid_width Grid lines.
#' @param frame_colour,frame_width Frame around the matrix.
#' @param pad Extra space beyond the outer dots, in row and column units.
#' @param size_key Optional list: `values` (sizes shown), `at` (panel
#'   fractions of the first key dot), `step` (panel fraction between dots),
#'   `fill`, `label_dx` (panel fraction from dot to label), `title`,
#'   `title_at`, `size` (text points), `suffix` (default `"%"`).
#' @return A 'ggplot2' object.
#' @examples
#' d <- expand.grid(row = c("a", "b", "c"), column = c("m1", "m2"), stringsAsFactors = FALSE)
#' d$size <- c(90, 10, 40, 5, 70, 20)
#' d$signal <- c(2, -1, 0.5, -2, 1.5, 0)
#' PlotDotMatrix(d)
#' @export
PlotDotMatrix <- function(data, row = "row", column = "column", size = "size", signal = "signal",
                          rows = NULL, columns = NULL, row_labels = NULL, column_labels = NULL,
                          area = c(2, 0.55), scale = "rdbu_r", limits = c(-3, 3),
                          edge_colour = "#777777", edge_width = 0.25, grid_colour = "#F0F0F0",
                          grid_width = 0.5, frame_colour = "#BBBBBB", frame_width = 0.4, pad = 0.1,
                          row_colours = NULL, row_box = c(-1.05, 0.35, 0.76), column_angle = 55,
                          column_size = 5.1, column_pad = 3.5, row_size = 5.3, row_pad = 9,
                          colourbar = NULL, size_key = NULL, texts = NULL, values = NULL,
                          style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  .fig_require_columns(data, c(row, column, size, signal))
  data <- as.data.frame(data)
  ok <- is.finite(as.numeric(data[[size]]))
  present <- unique(as.character(data[[row]][ok]))
  rows <- .figb_levels(rows, data[[row]])
  rows <- rows[rows %in% present]
  m <- .figb_matrix(data[ok, , drop = FALSE], row, column, rows, columns)
  nr <- length(m$rows)
  nc <- length(m$columns)
  limits <- as.numeric(unlist(limits))
  lut <- .figb_ramp(scale)
  z <- pmin(pmax(as.numeric(m$data[[signal]]), limits[1]), limits[2])
  dots <- data.frame(x = m$j, y = nr - m$i + 1, fill = .figb_map_colours(z, limits, lut),
                     diameter = sqrt(area[1] + area[2] * as.numeric(m$data[[size]])))
  xlim <- c(0.5 - pad, nc + 0.5 + pad)
  ylim <- c(0.5 - pad, nr + 0.5 + pad)
  lines <- rbind(data.frame(x = seq_len(nc), xend = seq_len(nc), y = ylim[1], yend = ylim[2]),
                 data.frame(x = xlim[1], xend = xlim[2], y = seq_len(nr), yend = seq_len(nr)))
  p <- .figb_canvas(xlim, ylim, style) +
    ggplot2::geom_segment(data = lines, ggplot2::aes(x = .data$x, xend = .data$xend, y = .data$y,
                                                     yend = .data$yend),
                          colour = .fig_colour(grid_colour, style), linewidth = PtLinewidth(grid_width),
                          inherit.aes = FALSE) +
    .figb_annotation(.figb_points_grob(dots$x, dots$y, dots$fill, dots$diameter, xlim, ylim,
                                       edge = .fig_colour(edge_colour, style), edge_width = edge_width,
                                       raster = FALSE)) +
    ggplot2::annotate("rect", xmin = xlim[1], xmax = xlim[2], ymin = ylim[1], ymax = ylim[2], fill = NA,
                      colour = .fig_colour(frame_colour, style), linewidth = PtLinewidth(frame_width))
  p <- p + .figb_row_boxes(row_colours, m$rows, row_box, nr, style)
  for (l in .figb_matrix_labels(style, m$columns, m$rows, xlim, ylim, column_labels, row_labels,
                                column_angle = column_angle, column_size = column_size,
                                column_pad = column_pad, row_size = row_size, row_pad = row_pad)) p <- p + l
  if (!is.null(colourbar)) p <- p + .figb_colourbar_layer(colourbar, lut, limits, style)
  if (!is.null(size_key)) p <- p + .figb_size_key(size_key, area, style)
  if (!is.null(texts)) p <- p + .figb_texts_layer(texts, .figb_template_values(values, data, NULL), style)
  p
}

# Size key: dots of the given sizes stacked downwards with labels.
.figb_size_key <- function(key, area, style) {
  vals <- as.numeric(unlist(key$values))
  at <- as.numeric(unlist(key$at))
  step <- if (is.null(key$step)) 0.08 else key$step
  size <- if (is.null(key$size)) style$size$legend else key$size
  dx <- if (is.null(key$label_dx)) 0.025 else key$label_dx
  suffix <- if (is.null(key$suffix)) "%" else key$suffix
  y <- at[2] - (seq_along(vals) - 1) * step
  make <- function() {
  kids <- list(.figb_points_grob(rep(at[1], length(vals)), y,
                                 if (is.null(key$fill)) "#BBBBBB" else .fig_colour(key$fill, style),
                                 sqrt(area[1] + area[2] * vals), c(0, 1), c(0, 1),
                                 edge = if (is.null(key$edge)) "#777777" else .fig_colour(key$edge, style),
                                 edge_width = if (is.null(key$edge_width)) 0.25 else key$edge_width,
                                 raster = FALSE))
  for (k in seq_along(vals)) {
    kids <- c(kids, list(.figb_text_grob(paste0(format(vals[k], trim = TRUE), suffix),
                                         grid::unit(at[1] + dx, "npc"), grid::unit(y[k], "npc"), size,
                                         style$colour$ink, style, hjust = 0, vjust = 0.5)))
  }
  if (!is.null(key$title)) {
    ta <- as.numeric(unlist(key$title_at))
    kids <- c(kids, list(.figb_text_grob(key$title, grid::unit(ta[1], "npc"), grid::unit(ta[2], "npc"),
                                         size, style$colour$ink, style, hjust = 0, vjust = 0)))
  }
  kids
  }
  .figb_annotation(.figb_deferred(make))
}

# Rounded rectangle outlines (corner radius in data units on both axes).
.figb_round_rects <- function(x, y, w, h, r) {
  if (r <= 0) {
    out <- data.frame(id = rep(seq_along(x), each = 4L),
                      x = as.vector(rbind(x - w / 2, x + w / 2, x + w / 2, x - w / 2)),
                      y = as.vector(rbind(y - h / 2, y - h / 2, y + h / 2, y + h / 2)))
    return(out)
  }
  r <- min(r, w / 2, h / 2)
  t <- seq(0, pi / 2, length.out = 7)
  corner <- function(cx, cy, from) data.frame(dx = cx + r * cos(t + from), dy = cy + r * sin(t + from))
  hw <- w / 2 - r
  hh <- h / 2 - r
  shape <- rbind(corner(hw, hh, 0), corner(-hw, hh, pi / 2), corner(-hw, -hh, pi), corner(hw, -hh, 3 * pi / 2))
  k <- nrow(shape)
  data.frame(id = rep(seq_along(x), each = k), x = rep(x, each = k) + shape$dx,
             y = rep(y, each = k) + shape$dy)
}

#' Alteration Matrix
#'
#' Tiles in a row-by-column grid, coloured by a category (for example the
#' alteration class of a gene in a tumour, or a clinical annotation of a
#' patient); missing combinations are drawn in a light grey. Tiles can have
#' rounded corners; a value per row (for example the share of altered
#' tumours) can be printed right of the matrix, and row labels can be set in
#' italics (gene symbols).
#'
#' @inheritParams PlotAnnotatedHeatmap
#' @param value Column with the category of each tile.
#' @param fill_column Optional column with explicit tile colours (overrides
#'   `colours`).
#' @param colours Named colours per category.
#' @param tile_width,tile_height Tile size in column and row units.
#' @param radius Corner radius in data units (0 for square tiles).
#' @param right_text Optional column with one numeric value per row, printed
#'   right of the matrix with `right_format`.
#' @param right_format,right_size,right_colour,right_offset Format, size,
#'   colour and position (column units beyond the last column centre).
#' @param legends Optional list of legends, each as the `legend` of
#'   [PlotEmbedding()] (shape `"rect"` gives patches); colours default to
#'   `colours`.
#' @return A 'ggplot2' object.
#' @examples
#' d <- data.frame(row = rep(c("g1", "g2"), each = 3), column = rep(c("s1", "s2", "s3"), 2),
#'                 value = c("Missense", NA, "Deletion", NA, "Truncating", NA),
#'                 share = rep(c(67, 33), each = 3))
#' PlotAlterationMatrix(d, colours = c(Missense = "#008300", Truncating = "#222222",
#'                                     Deletion = "#2a78d6"), right_text = "share",
#'                      row_italic = TRUE)
#' @export
PlotAlterationMatrix <- function(data, row = "row", column = "column", value = "value", fill_column = NULL,
                                 rows = NULL, columns = NULL, row_order_by = NULL, column_order_by = NULL,
                                 row_labels = NULL, column_labels = NULL, colours = NULL,
                                 missing_colour = "#F0F0F0", tile_width = 0.8, tile_height = 0.72,
                                 radius = 0.12, row_size = 5.3, row_pad = 3.5, row_italic = FALSE,
                                 show_rows = TRUE, show_columns = FALSE, column_angle = 55, column_size = 5,
                                 column_pad = 3.5, column_colours = NULL, right_text = NULL,
                                 right_format = "%.0f%%", right_size = 4.6, right_colour = "muted",
                                 right_offset = 0.2, legends = NULL, texts = NULL, values = NULL,
                                 style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  .fig_require_columns(data, c(row, column, value, fill_column, right_text))
  data <- as.data.frame(data)
  m <- .figb_matrix(data, row, column, rows, columns, row_order_by, column_order_by)
  nr <- length(m$rows)
  nc <- length(m$columns)
  grid_all <- expand.grid(j = seq_len(nc), i = seq_len(nr))
  key <- paste(m$i, m$j)
  pos <- match(paste(grid_all$i, grid_all$j), key)
  cls <- if (is.null(fill_column)) as.character(m$data[[value]])[pos] else NA
  col <- if (!is.null(fill_column)) as.character(m$data[[fill_column]])[pos] else .figb_colours(colours, cls, NA_character_, style)
  col[is.na(col)] <- .fig_colour(missing_colour, style)
  tiles <- .figb_round_rects(grid_all$j, nr - grid_all$i + 1, tile_width, tile_height, radius)
  tiles$fill <- col[tiles$id]
  xlim <- c(0.5, nc + 0.5)
  ylim <- c(0.5, nr + 0.5)
  p <- .figb_canvas(xlim, ylim, style) +
    ggplot2::geom_polygon(data = tiles, ggplot2::aes(x = .data$x, y = .data$y, group = .data$id,
                                                     fill = .data$fill),
                          colour = NA, inherit.aes = FALSE) +
    ggplot2::scale_fill_identity()
  if (!is.null(right_text)) {
    r <- tapply(as.numeric(m$data[[right_text]]), m$i, function(v) v[1])
    rt <- data.frame(x = nc + right_offset, y = nr - as.integer(names(r)) + 1,
                     text = sprintf(right_format, as.numeric(r)))
    p <- p + ggplot2::geom_text(data = rt, ggplot2::aes(x = .data$x, y = .data$y, label = .data$text),
                                colour = .fig_colour(right_colour, style), size = .fig_text_size(right_size),
                                family = style$family, hjust = 0, inherit.aes = FALSE)
  }
  for (l in .figb_matrix_labels(style, m$columns, m$rows, xlim, ylim, column_labels, row_labels,
                                show_columns, show_rows, column_angle, column_size, column_pad,
                                column_colours, NULL, 1, 0, row_size, row_pad, row_italic)) p <- p + l
  if (!is.null(legends)) {
    if (!is.null(legends$keys)) legends <- list(legends)
    for (lg in legends) p <- p + .figb_annotation(.figb_marker_key(lg, colours, NULL, style))
  }
  if (!is.null(texts)) p <- p + .figb_texts_layer(texts, .figb_template_values(values, data, NULL), style)
  p
}
