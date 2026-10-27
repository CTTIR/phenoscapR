#' Describe One Figure Panel
#'
#' A panel places a plot so that its data area fills `box` exactly; axis
#' labels, ticks and legends extend outside the box, as in hand-laid
#' journal figures. Boxes are measured in millimetres from the top-left
#' corner of the page.
#'
#' @param plot A 'ggplot2' plot, a 'grid' grob, or `NULL` for a text-only
#'   panel.
#' @param box Numeric `c(left, top, width, height)` in millimetres.
#' @param letter Optional panel letter.
#' @param letter_at Optional `c(left, top)` of the letter in millimetres;
#'   defaults to 4 mm left of and 3 mm above the box.
#' @param heading Optional panel heading, set bold above the box.
#' @param note Optional statistic or note line, set small and grey directly
#'   above the box (below the heading).
#' @param fill_box If `TRUE`, the whole plot (including axes) is fitted into
#'   the box instead of aligning the data area.
#' @return A list of class `phenoscapR_panel`.
#' @examples
#' FigurePanel(NULL, c(10, 10, 40, 30), letter = "a", heading = "Overview")
#' @seealso [ComposeFigure()]
#' @export
FigurePanel <- function(plot, box, letter = NULL, letter_at = NULL, heading = NULL,
                        note = NULL, fill_box = FALSE) {
  if (!is.numeric(box) || length(box) != 4L || anyNA(box) || any(box[3:4] <= 0)) {
    stop("box must be c(left, top, width, height) in millimetres.", call. = FALSE)
  }
  if (!is.null(plot) && !inherits(plot, c("ggplot", "grob", "gTree", "gtable"))) {
    stop("plot must be a ggplot, a grid grob or NULL.", call. = FALSE)
  }
  if (!is.null(letter_at) && (!is.numeric(letter_at) || length(letter_at) != 2L)) {
    stop("letter_at must be c(left, top) in millimetres.", call. = FALSE)
  }
  structure(list(plot = plot, box = as.numeric(box), letter = letter, letter_at = letter_at,
                 heading = heading, note = note, fill_box = isTRUE(fill_box)),
            class = "phenoscapR_panel")
}

#' Place Text on a Figure Page
#'
#' @param label Text, typeset with [TypesetLabel()].
#' @param at Numeric `c(left, top)` in millimetres.
#' @param size Font size in points; default is the style's note size.
#' @param colour Text colour; default is the style's muted colour.
#' @param bold Bold face.
#' @param hjust,vjust Justification relative to `at`; by default the text
#'   hangs below and to the right of the point.
#' @param angle Rotation in degrees.
#' @return A list of class `phenoscapR_text`.
#' @examples
#' FigureText("Median and IQR\nn = 12 patients", c(20, 50))
#' @export
FigureText <- function(label, at, size = NULL, colour = NULL, bold = FALSE, hjust = 0,
                       vjust = 1, angle = 0) {
  if (!is.character(label) || length(label) != 1L) stop("label must be one string.", call. = FALSE)
  if (!is.numeric(at) || length(at) != 2L) stop("at must be c(left, top) in millimetres.", call. = FALSE)
  structure(list(label = label, at = as.numeric(at), size = size, colour = colour,
                 bold = isTRUE(bold), hjust = hjust, vjust = vjust, angle = angle),
            class = "phenoscapR_text")
}

#' Compose a Multi-Panel Figure
#'
#' Lays out panels, page-level texts and legend keys on a page of fixed size
#' in millimetres, with bold panel letters and headings in the manuscript
#' style. The result can be drawn on any device or written with
#' [SaveFigure()].
#'
#' @param panels List of [FigurePanel()] objects.
#' @param height_mm Page height in millimetres.
#' @param width_mm Page width; defaults to the style's page width.
#' @param texts Optional list of [FigureText()] objects and grobs placed with
#'   [FigureGrob()].
#' @param style A [ManuscriptStyle()] object.
#' @return An object of class `phenoscapR_figure`; `print()` draws it on the
#'   current device.
#' @examples
#' library(ggplot2)
#' p <- ggplot(data.frame(x = 1:3, y = 1:3), aes(x, y)) + geom_point() +
#'   ThemeManuscript()
#' fig <- ComposeFigure(list(FigurePanel(p, c(12, 10, 50, 30), letter = "a",
#'                                       heading = "Example")), height_mm = 50)
#' @export
ComposeFigure <- function(panels, height_mm, width_mm = NULL, texts = list(),
                          style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  if (is.null(width_mm)) width_mm <- style$page$width_mm
  if (!is.list(panels) || !all(vapply(panels, inherits, logical(1), "phenoscapR_panel"))) {
    stop("panels must be a list of FigurePanel() objects.", call. = FALSE)
  }
  ok_text <- vapply(texts, function(x) inherits(x, c("phenoscapR_text", "phenoscapR_grob")),
                    logical(1))
  if (!is.list(texts) || !all(ok_text)) {
    stop("texts must contain FigureText() or FigureGrob() objects.", call. = FALSE)
  }
  if (!is.numeric(height_mm) || length(height_mm) != 1L || height_mm <= 0 ||
      !is.numeric(width_mm) || length(width_mm) != 1L || width_mm <= 0) {
    stop("Page size must be positive millimetres.", call. = FALSE)
  }
  structure(list(panels = panels, texts = texts, width_mm = width_mm,
                 height_mm = height_mm, style = style), class = "phenoscapR_figure")
}

#' Place a Grob on a Figure Page
#'
#' @param grob A 'grid' grob, for example a legend from [LegendKeys()].
#' @param at Numeric `c(left, top)` in millimetres.
#' @param hjust,vjust Justification relative to `at`.
#' @return A list of class `phenoscapR_grob`.
#' @export
FigureGrob <- function(grob, at, hjust = 0, vjust = 1) {
  if (!inherits(grob, "grob")) stop("grob must be a grid grob.", call. = FALSE)
  if (!is.numeric(at) || length(at) != 2L) stop("at must be c(left, top) in millimetres.", call. = FALSE)
  structure(list(grob = grob, at = as.numeric(at), hjust = hjust, vjust = vjust),
            class = "phenoscapR_grob")
}

#' @export
print.phenoscapR_figure <- function(x, newpage = TRUE, ...) {
  if (newpage) grid::grid.newpage()
  .fig_draw(x)
  invisible(x)
}

#' Save a Composed Figure as PDF and PNG
#'
#' Writes the page at its exact size: PDF through the Cairo device with
#' embedded TrueType fonts, PNG through 'ragg' at the style's resolution
#' (falling back to the 'png' Cairo device when 'ragg' is absent).
#'
#' @param figure A [ComposeFigure()] result.
#' @param pdf Output PDF path, or `NULL`.
#' @param png Output PNG path, or `NULL`.
#' @param dpi Raster resolution; defaults to the style's.
#' @return The output paths, invisibly.
#' @export
SaveFigure <- function(figure, pdf = NULL, png = NULL, dpi = NULL) {
  if (!inherits(figure, "phenoscapR_figure")) stop("figure must come from ComposeFigure().", call. = FALSE)
  if (is.null(pdf) && is.null(png)) stop("Give at least one output path.", call. = FALSE)
  style <- figure$style
  if (is.null(dpi)) dpi <- style$page$dpi
  w <- figure$width_mm / 25.4
  h <- figure$height_mm / 25.4
  if (!is.null(pdf)) {
    if (!capabilities("cairo")) stop("PDF output needs R built with Cairo.", call. = FALSE)
    grDevices::cairo_pdf(pdf, width = w, height = h, family = style$family, onefile = TRUE)
    tryCatch(print(figure), finally = grDevices::dev.off())
  }
  if (!is.null(png)) {
    if (requireNamespace("ragg", quietly = TRUE)) {
      ragg::agg_png(png, width = w, height = h, units = "in", res = dpi, background = "white")
    } else {
      grDevices::png(png, width = w, height = h, units = "in", res = dpi, type = "cairo",
                     bg = "white")
    }
    tryCatch(print(figure), finally = grDevices::dev.off())
  }
  invisible(c(pdf = pdf, png = png))
}

# ---- drawing ------------------------------------------------------------------

.fig_draw <- function(fig) {
  style <- fig$style
  W <- fig$width_mm
  H <- fig$height_mm
  grid::pushViewport(grid::viewport(width = grid::unit(W, "mm"), height = grid::unit(H, "mm"),
                                    name = "phenoscapR-page"))
  on.exit(grid::popViewport(), add = TRUE)
  for (p in fig$panels) .fig_draw_panel(p, H, style)
  for (t in fig$texts) {
    if (inherits(t, "phenoscapR_grob")) {
      grid::pushViewport(grid::viewport(
        x = grid::unit(t$at[1], "mm"), y = grid::unit(H - t$at[2], "mm"),
        width = grid::grobWidth(t$grob), height = grid::grobHeight(t$grob),
        just = c(t$hjust, t$vjust)
      ))
      grid::grid.draw(t$grob)
      grid::popViewport()
    } else {
      .fig_text(t$label, t$at[1], H - t$at[2],
                size = if (is.null(t$size)) style$size$note else t$size,
                colour = if (is.null(t$colour)) style$colour$muted else t$colour,
                bold = t$bold, hjust = t$hjust, vjust = t$vjust, angle = t$angle, style = style)
    }
  }
}

.fig_draw_panel <- function(p, H, style) {
  b <- p$box
  if (!is.null(p$plot)) {
    g <- if (inherits(p$plot, "ggplot")) ggplot2::ggplotGrob(p$plot) else p$plot
    if (!p$fill_box && inherits(g, "gtable") && any(grepl("^panel", g$layout$name))) {
      pad <- .fig_panel_padding(g)
      vp <- grid::viewport(
        x = grid::unit(b[1] - pad[["left"]], "mm"),
        y = grid::unit(H - b[2] - b[4] - pad[["bottom"]], "mm"),
        width = grid::unit(b[3] + pad[["left"]] + pad[["right"]], "mm"),
        height = grid::unit(b[4] + pad[["top"]] + pad[["bottom"]], "mm"),
        just = c(0, 0)
      )
    } else {
      vp <- grid::viewport(x = grid::unit(b[1], "mm"), y = grid::unit(H - b[2] - b[4], "mm"),
                           width = grid::unit(b[3], "mm"), height = grid::unit(b[4], "mm"),
                           just = c(0, 0))
    }
    grid::pushViewport(vp)
    grid::grid.draw(g)
    grid::popViewport()
  }
  top <- H - b[2]
  offset <- 0.9
  if (!is.null(p$note) && nzchar(p$note)) {
    .fig_text(p$note, b[1], top + offset, size = style$size$statistic,
              colour = style$colour$muted, hjust = 0, vjust = 0, style = style)
    offset <- offset + 0.45 + style$size$statistic * 0.3528 * .fig_lines(p$note)
  }
  if (!is.null(p$heading) && nzchar(p$heading)) {
    .fig_text(p$heading, b[1], top + offset + 0.15, size = style$size$heading, bold = TRUE,
              hjust = 0, vjust = 0, style = style)
  }
  if (!is.null(p$letter) && nzchar(p$letter)) {
    at <- if (is.null(p$letter_at)) c(b[1] - 4, b[2] - 3) else p$letter_at
    .fig_text(p$letter, at[1], H - at[2], size = style$size$letter, bold = TRUE,
              hjust = 0, vjust = 1, style = style, typeset = FALSE)
  }
}

.fig_lines <- function(x) length(strsplit(x, "\n", fixed = TRUE)[[1L]])

# Absolute sizes (mm) of everything around the panel cells of a gtable.
.fig_panel_padding <- function(g) {
  panels <- g$layout[grepl("^panel", g$layout$name), , drop = FALSE]
  l <- min(panels$l)
  r <- max(panels$r)
  t <- min(panels$t)
  b <- max(panels$b)
  size <- function(units, idx, horizontal) {
    if (!length(idx)) return(0)
    u <- units[idx]
    if (horizontal) {
      sum(grid::convertWidth(u, "mm", valueOnly = TRUE))
    } else {
      sum(grid::convertHeight(u, "mm", valueOnly = TRUE))
    }
  }
  # Null units convert to zero outside a sized viewport; panel cells are null.
  c(left = size(g$widths, seq_len(l - 1L), TRUE),
    right = size(g$widths, seq.int(r + 1L, length.out = max(0L, length(g$widths) - r)), TRUE),
    top = size(g$heights, seq_len(t - 1L), FALSE),
    bottom = size(g$heights, seq.int(b + 1L, length.out = max(0L, length(g$heights) - b)), FALSE))
}

.fig_text <- function(label, x_mm, y_mm, size, colour = NULL, bold = FALSE, hjust = 0,
                      vjust = 1, angle = 0, style, typeset = TRUE) {
  if (is.null(colour)) colour <- style$colour$ink
  if (typeset && .fig_has_rich_text()) {
    text <- TypesetLabel(label, rich = TRUE)
    if (bold) text <- gsub("<sub>reg</sub>", "<sub>**reg**</sub>", paste0("**", text, "**"), fixed = TRUE)
    grid::grid.draw(gridtext::richtext_grob(
      text, x = grid::unit(x_mm, "mm"), y = grid::unit(y_mm, "mm"),
      hjust = hjust, vjust = vjust, rot = angle,
      gp = grid::gpar(fontsize = size, col = colour, fontfamily = style$family, lineheight = 1.1),
      padding = grid::unit(0, "pt"), margin = grid::unit(0, "pt")
    ))
  } else {
    if (typeset) label <- TypesetLabel(label, rich = FALSE)
    grid::grid.text(label, x = grid::unit(x_mm, "mm"), y = grid::unit(y_mm, "mm"),
                    hjust = hjust, vjust = vjust, rot = angle,
                    gp = grid::gpar(fontsize = size, col = colour, fontfamily = style$family,
                                    fontface = if (bold) "bold" else "plain", lineheight = 1.1))
  }
}

#' Legend Keys as a Grob
#'
#' Draws a compact legend (points, lines, squares or point-and-line keys)
#' without a frame, in one row or several columns, for placement with
#' [FigureGrob()]. Text is measured when the legend is drawn.
#'
#' @param labels Character labels, typeset with [TypesetLabel()].
#' @param colours Key colours, recycled.
#' @param shape One of `"point"`, `"square"`, `"line"`, `"pointline"`,
#'   `"open"` (open circle) or `"cross"`, recycled per key.
#' @param ncol Number of columns; default is one row.
#' @param size Text size in points; default is the style's legend size.
#' @param key_mm Key width in millimetres.
#' @param style A [ManuscriptStyle()] object.
#' @return A 'grid' grob.
#' @examples
#' grid::grid.draw(LegendKeys(c("Untreated", "Responder"), c("#009E73", "#0072B2")))
#' @export
LegendKeys <- function(labels, colours, shape = "point", ncol = length(labels), size = NULL,
                       key_mm = 2.2, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  n <- length(labels)
  if (!n) stop("labels must not be empty.", call. = FALSE)
  shape <- rep_len(shape, n)
  if (!all(shape %in% c("point", "square", "line", "pointline", "open", "cross"))) {
    stop("Unknown key shape.", call. = FALSE)
  }
  grid::gTree(labels = as.character(labels), colours = rep_len(colours, n), shape = shape,
              ncol = max(1L, min(as.integer(ncol), n)),
              size = if (is.null(size)) style$size$legend else size,
              key_mm = key_mm, style = style, cl = "phenoscapR_legend")
}

.fig_legend_layout <- function(x) {
  n <- length(x$labels)
  text <- TypesetLabel(x$labels, rich = .fig_has_rich_text())
  gp <- grid::gpar(fontsize = x$size, col = x$style$colour$ink, fontfamily = x$style$family)
  grobs <- lapply(seq_len(n), function(i) {
    if (.fig_has_rich_text()) {
      gridtext::richtext_grob(text[i], x = 0, y = 0.5, hjust = 0, vjust = 0.5, gp = gp,
                              padding = grid::unit(0, "pt"), margin = grid::unit(0, "pt"))
    } else {
      grid::textGrob(text[i], x = 0, y = 0.5, hjust = 0, vjust = 0.5, gp = gp)
    }
  })
  widths <- vapply(grobs, function(g) grid::convertWidth(grid::grobWidth(g), "mm", TRUE), numeric(1))
  nrow <- ceiling(n / x$ncol)
  row_h <- x$size * 0.3528 * 1.35
  col_w <- vapply(seq_len(x$ncol), function(j) {
    max(widths[seq(j, n, by = x$ncol)]) + x$key_mm + 1.6
  }, numeric(1))
  list(grobs = grobs, widths = widths, nrow = nrow, row_h = row_h, col_w = col_w)
}

#' @export
#' @importFrom grid makeContent
makeContent.phenoscapR_legend <- function(x) {
  lay <- .fig_legend_layout(x)
  mm <- function(v) grid::unit(v, "mm")
  children <- list()
  for (i in seq_along(x$labels)) {
    j <- (i - 1L) %% x$ncol + 1L
    r <- (i - 1L) %/% x$ncol + 1L
    x0 <- sum(lay$col_w[seq_len(j - 1L)])
    y0 <- (lay$nrow - r + 0.5) * lay$row_h
    col <- x$colours[i]
    pt <- grid::unit(x$size * 0.75, "pt")
    key <- switch(x$shape[i],
      point = grid::pointsGrob(mm(x0 + x$key_mm / 2), mm(y0), pch = 16, size = pt,
                               gp = grid::gpar(col = col)),
      open = grid::pointsGrob(mm(x0 + x$key_mm / 2), mm(y0), pch = 21, size = pt,
                              gp = grid::gpar(col = col, fill = "white")),
      cross = grid::pointsGrob(mm(x0 + x$key_mm / 2), mm(y0), pch = 4, size = pt,
                               gp = grid::gpar(col = col)),
      square = grid::rectGrob(mm(x0 + x$key_mm / 2), mm(y0), width = mm(x$key_mm * 0.7),
                              height = mm(x$key_mm * 0.7), gp = grid::gpar(fill = col, col = NA)),
      line = grid::segmentsGrob(mm(x0), mm(y0), mm(x0 + x$key_mm), mm(y0),
                                gp = grid::gpar(col = col, lwd = 1)),
      pointline = grid::gTree(children = grid::gList(
        grid::segmentsGrob(mm(x0), mm(y0), mm(x0 + x$key_mm), mm(y0), gp = grid::gpar(col = col, lwd = 0.8)),
        grid::pointsGrob(mm(x0 + x$key_mm / 2), mm(y0), pch = 16, size = pt, gp = grid::gpar(col = col))
      ))
    )
    g <- lay$grobs[[i]]
    g$vp <- grid::viewport(x = mm(x0 + x$key_mm + 0.8), y = mm(y0), width = mm(lay$widths[i]),
                           height = mm(lay$row_h), just = c(0, 0.5))
    children <- c(children, list(key, g))
  }
  grid::setChildren(x, do.call(grid::gList, children))
}

#' @export
#' @importFrom grid widthDetails
widthDetails.phenoscapR_legend <- function(x) grid::unit(sum(.fig_legend_layout(x)$col_w), "mm")

#' @export
#' @importFrom grid heightDetails
heightDetails.phenoscapR_legend <- function(x) {
  lay <- .fig_legend_layout(x)
  grid::unit(lay$nrow * lay$row_h, "mm")
}
