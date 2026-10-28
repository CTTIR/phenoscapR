# Text panels: lines written from templates and small text tables. Text is
# laid out when the panel is drawn, so that it is measured on the output
# device.

#' Text Block or Text Table
#'
#' A panel of text placed in its figure box: lines written from templates
#' and data (statistic lines, headings that contain numbers, notes) or, with
#' `layout = "table"`, a small table of text cells as produced by
#' [PlotDataTableCells()].
#'
#' Lines: `text` gives fixed lines; `template` is filled from `data` with
#' [FormatTemplate()] (one template per data row, or one template for every
#' row). `size`, `colour` and `bold` may be given per line. The block is
#' anchored at `x`, `y` (fractions of the box) with `hjust`, `vjust`.
#'
#' Table: cells with `row`, `column`, `label`, `header`, `highlight` and
#' `key` columns; the first column is left aligned, the others centred;
#' header cells are bold on `header_fill` and coloured by `key` through
#' `key_colours`; highlighted cells use `highlight_fill`.
#'
#' @param data Optional data frame.
#' @param template Optional templates.
#' @param text Optional fixed lines (placed before the template lines).
#' @param size Font size(s) in points; default the style's statistic size.
#' @param colour Colour(s); style names allowed.
#' @param bold Bold face per line.
#' @param hjust,vjust Justification of the block.
#' @param x,y Anchor in fractions of the box (default `hjust`, `vjust`).
#' @param lineheight Line height multiplier.
#' @param angle Rotation in degrees.
#' @param layout `"lines"` or `"table"`.
#' @param widths Relative column widths of a table (default: first column
#'   0.23, others equal).
#' @param header_fill,highlight_fill,border_colour Table colours.
#' @param border_linewidth Cell border width in points.
#' @param key_colours Named colours for header text by `key`.
#' @param table_size Table font size.
#' @param first_pad Left padding of first-column text (fraction of width).
#' @param borders `"cells"` (a frame around every cell, with fills) or `"rules"`
#'   (only horizontal rules between rows, no fills).
#' @param align Alignment of the columns after the first: `"centre"` or
#'   `"left"` (at `first_pad` from the column edge).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'grid' grob.
#' @examples
#' g <- PlotTextBlock(data.frame(k = 11, n = 12, p = 0.0015),
#'                    template = "{k|d}/{n|d} patients; p = {p|p}")
#' grid::grid.newpage(); grid::grid.draw(g)
#' @export
PlotTextBlock <- function(data = NULL, template = NULL, text = NULL, size = NULL, colour = "muted", bold = FALSE,
                          hjust = 0, vjust = 0, x = NULL, y = NULL, lineheight = 1.1, angle = 0,
                          layout = c("lines", "table"), widths = NULL, header_fill = "#F3F3F3",
                          highlight_fill = "#FFF2D6", border_colour = "#D9D9D9", border_linewidth = 0.4,
                          key_colours = NULL, table_size = 5.5, first_pad = 0.02, borders = c("cells", "rules"),
                          align = c("centre", "left"), style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  layout <- match.arg(layout)
  borders <- match.arg(borders)
  align <- match.arg(align)
  if (layout == "table") {
    .fig_require_columns(data, c("row", "column", "label"), "data")
    cells <- as.data.frame(data, check.names = FALSE)
    if (is.null(cells$header)) cells$header <- cells$row == min(cells$row)
    if (is.null(cells$highlight)) cells$highlight <- FALSE
    if (is.null(cells$key)) cells$key <- NA
    nc <- max(cells$column)
    if (is.null(widths)) widths <- c(0.23, rep(0.77 / (nc - 1), nc - 1))
    widths <- as.numeric(unlist(widths))
    if (length(widths) != nc) stop("widths must have one value per column.", call. = FALSE)
    return(grid::gTree(cells = cells, widths = widths, header_fill = header_fill, highlight_fill = highlight_fill,
                       border_colour = border_colour, border_linewidth = border_linewidth,
                       key_colours = .figA_col(key_colours, style), size = table_size, first_pad = first_pad,
                       borders = borders, align = align,
                       style = style, cl = "phenoscapR_text_table"))
  }
  lines <- c(if (!is.null(text)) unlist(strsplit(as.character(unlist(text)), "\n", fixed = TRUE)),
             if (!is.null(template)) FormatTemplate(as.character(unlist(template)), data))
  if (!length(lines)) stop("Give text or a template.", call. = FALSE)
  if (is.null(size)) size <- style$size$statistic
  n <- length(lines)
  grid::gTree(lines = lines, size = rep_len(as.numeric(unlist(size)), n),
              colour = rep_len(.figA_col(unlist(colour), style), n), bold = rep_len(as.logical(unlist(bold)), n),
              hjust = hjust, vjust = vjust, x = if (is.null(x)) hjust else x, y = if (is.null(y)) vjust else y,
              lineheight = lineheight, angle = angle, style = style, cl = "phenoscapR_text_block")
}

#' @export
#' @importFrom grid makeContent
makeContent.phenoscapR_text_block <- function(x) {
  n <- length(x$lines)
  uniform <- length(unique(x$size)) == 1L && length(unique(x$colour)) == 1L && length(unique(x$bold)) == 1L
  if (uniform || !.fig_has_rich_text()) {
    g <- .figA_text_grob(paste(x$lines, collapse = "\n"), x = grid::unit(x$x, "npc"), y = grid::unit(x$y, "npc"),
                         hjust = x$hjust, vjust = x$vjust, size = x$size[1], colour = x$colour[1], bold = x$bold[1],
                         angle = x$angle, style = x$style, lineheight = x$lineheight)
  } else {
    parts <- vapply(seq_len(n), function(i) {
      t <- TypesetLabel(x$lines[i], rich = TRUE)
      if (x$bold[i]) t <- paste0("<b>", t, "</b>")
      paste0("<span style='font-size:", x$size[i], "pt; color:", x$colour[i], "'>", t, "</span>")
    }, character(1))
    g <- gridtext::richtext_grob(paste(parts, collapse = "<br>"), x = grid::unit(x$x, "npc"),
                                 y = grid::unit(x$y, "npc"), hjust = x$hjust, vjust = x$vjust, rot = x$angle,
                                 gp = grid::gpar(fontsize = max(x$size), col = x$colour[1],
                                                 fontfamily = x$style$family, lineheight = x$lineheight),
                                 padding = grid::unit(0, "pt"), margin = grid::unit(0, "pt"))
  }
  grid::setChildren(x, grid::gList(g))
}

#' @export
makeContent.phenoscapR_text_table <- function(x) {
  cells <- x$cells
  nr <- max(cells$row)
  edges <- c(0, cumsum(x$widths / sum(x$widths)))
  k <- x$style$colour
  children <- list()
  for (i in seq_len(nrow(cells))) {
    r <- cells$row[i]
    cc <- cells$column[i]
    x0 <- edges[cc]
    x1 <- edges[cc + 1]
    y1 <- 1 - (r - 1) / nr
    y0 <- 1 - r / nr
    if (!identical(x$borders, "rules")) {
      fill <- if (isTRUE(cells$header[i])) x$header_fill else if (isTRUE(cells$highlight[i])) x$highlight_fill else "white"
      children[[length(children) + 1L]] <- grid::rectGrob(
        x = grid::unit(x0, "npc"), y = grid::unit(y0, "npc"), width = grid::unit(x1 - x0, "npc"),
        height = grid::unit(y1 - y0, "npc"), just = c(0, 0),
        gp = grid::gpar(fill = fill, col = x$border_colour, lwd = x$border_linewidth / 0.75))
    }
    col <- k$ink
    kc <- x$key_colours
    if (isTRUE(cells$header[i]) && !is.na(cells$key[i]) && !is.null(kc) && cells$key[i] %in% names(kc)) {
      col <- kc[[cells$key[i]]]
    }
    first <- cc == 1L || identical(x$align, "left")
    children[[length(children) + 1L]] <- .figA_text_grob(
      as.character(cells$label[i]), x = grid::unit(if (first) x0 + x$first_pad else (x0 + x1) / 2, "npc"),
      y = grid::unit((y0 + y1) / 2, "npc"), hjust = if (first) 0 else 0.5, vjust = 0.5, size = x$size,
      colour = col, bold = isTRUE(cells$header[i]), style = x$style)
  }
  if (identical(x$borders, "rules") && nr > 1L) {
    yr <- 1 - seq_len(nr - 1L) / nr
    children[[length(children) + 1L]] <- grid::segmentsGrob(0, yr, 1, yr, default.units = "npc",
      gp = grid::gpar(col = x$border_colour, lwd = x$border_linewidth / 0.75))
  }
  grid::setChildren(x, do.call(grid::gList, children))
}
