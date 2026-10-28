# Internal helpers of the matrix, bar and embedding grammars: colour ramps
# as in common figure code, ordering, label templates, tick labels drawn in
# the manner of rotated figure labels, colour bars, rasterised point layers
# and haloed text. Positions outside the data area are given as fractions of
# the panel (npc) and drawn without clipping.

# ---- colour ramps -------------------------------------------------------------

# Anchor colours of common sequential and diverging ramps (ColorBrewer, as
# used by matplotlib's "Blues" and "RdBu").
.figb_anchor_colours <- function(name) {
  blues <- c("#f7fbff", "#deebf7", "#c6dbef", "#9ecae1", "#6baed6", "#4292c6",
             "#2171b5", "#08519c", "#08306b")
  rdbu <- c("#67001f", "#b2182b", "#d6604d", "#f4a582", "#fddbc7", "#f7f7f7",
            "#d1e5f0", "#92c5de", "#4393c3", "#2166ac", "#053061")
  greys <- c("#ffffff", "#f0f0f0", "#d9d9d9", "#bdbdbd", "#969696", "#737373",
             "#525252", "#252525", "#000000")
  switch(name,
    blues = blues,
    rdbu = rdbu,
    rdbu_r = rev(rdbu),
    greys = greys,
    stop("Unknown colour scale '", name, "'.", call. = FALSE)
  )
}

# A 256-entry lookup table, linear in sRGB between equally spaced anchors.
.figb_ramp <- function(scale, n = 256L) {
  anchors <- if (length(scale) == 1L && !grepl("^#", scale)) .figb_anchor_colours(scale) else scale
  f <- grDevices::colorRamp(anchors, space = "rgb", interpolate = "linear")
  m <- f(seq(0, 1, length.out = n))
  grDevices::rgb(m[, 1], m[, 2], m[, 3], maxColorValue = 255)
}

# Map values to the lookup table: the fraction of the limits selects entry
# floor(fraction * n), clipped to the table (values at the upper limit take
# the last entry).
.figb_map_colours <- function(values, limits, lut, missing = "#EEEEEE") {
  n <- length(lut)
  f <- (values - limits[1]) / (limits[2] - limits[1])
  i <- floor(f * n) + 1L
  i <- pmin(pmax(i, 1L), n)
  out <- lut[i]
  out[!is.finite(values)] <- missing
  out
}

# ---- levels and labels ----------------------------------------------------------

# Order of levels: NULL (first appearance in `x`), a character vector, or a
# data frame (sorted by a `rank` column when present, else in row order; the
# first column holds the levels).
.figb_levels <- function(order, x) {
  if (is.null(order)) return(unique(as.character(x[!is.na(x)])))
  if (is.data.frame(order)) {
    if ("rank" %in% names(order)) order <- order[order(order$rank), , drop = FALSE]
    return(as.character(order[[1L]]))
  }
  as.character(unlist(order))
}

# Display labels for levels: NULL keeps the levels; a named vector or list
# maps levels (missing entries keep the level); an unnamed vector of the same
# length is used as is.
.figb_display <- function(labels, levels) {
  if (is.null(labels)) return(levels)
  if (is.list(labels)) labels <- unlist(labels)
  if (is.null(names(labels))) {
    if (length(labels) != length(levels)) stop("Unnamed labels must match the levels.", call. = FALSE)
    return(as.character(labels))
  }
  out <- unname(labels[levels])
  out[is.na(out)] <- levels[is.na(out)]
  as.character(out)
}

# Named colours for levels (missing levels take `missing`).
.figb_named <- function(colours, levels, missing = NA_character_) {
  if (is.null(colours)) return(rep(missing, length(levels)))
  if (is.data.frame(colours)) {
    vcol <- if ("colour" %in% names(colours)) "colour" else names(colours)[2L]
    colours <- stats::setNames(as.character(colours[[vcol]]), as.character(colours[[1L]]))
  }
  if (is.list(colours)) colours <- unlist(colours)
  if (is.null(names(colours))) return(rep_len(as.character(colours), length(levels)))
  out <- unname(colours[levels])
  out[is.na(out)] <- missing
  as.character(out)
}

# Named colours resolved through the style (palette entries, style names).
.figb_colours <- function(colours, levels, missing, style) {
  out <- .figb_named(colours, levels, missing)
  ok <- !is.na(out)
  out[ok] <- .fig_colour(out[ok], style)
  unname(out)
}

# Keep rows whose columns take given values (named list).
.figb_subset <- function(data, subset) {
  if (is.null(subset) || !length(subset)) return(data)
  .fig_require_columns(data, names(subset))
  keep <- rep(TRUE, nrow(data))
  for (col in names(subset)) {
    v <- unlist(subset[[col]])
    keep <- keep & if (is.logical(v)) as.logical(data[[col]]) %in% v else as.character(data[[col]]) %in% as.character(v)
  }
  data[keep, , drop = FALSE]
}

# ---- text templates ---------------------------------------------------------------

# Values for templates: a data frame (filtered by `subset` on the columns it
# has) or, if `values` is NULL, the plot data itself.
.figb_template_values <- function(values, data, subset) {
  if (is.null(values)) return(data)
  if (is.data.frame(values) && !is.null(subset)) {
    s <- subset[names(subset) %in% names(values)]
    values <- .figb_subset(values, s)
  }
  values
}

# ---- text grobs -------------------------------------------------------------------------

.figb_rich <- function() .fig_has_rich_text()

# One text grob, typeset, at grid units x, y.
.figb_text_grob <- function(label, x, y, size, colour, style, bold = FALSE, italic = FALSE,
                            hjust = 0.5, vjust = 0.5, rot = 0, lineheight = 1.15, typeset = TRUE,
                            box_fill = NA, box_pad = 0, box_r = 0, halign = hjust) {
  if (.figb_rich()) {
    text <- if (typeset) TypesetLabel(label, rich = TRUE) else label
    if (italic) text <- paste0("<i>", text, "</i>")
    if (bold) text <- paste0("<b>", text, "</b>")
    gridtext::richtext_grob(
      text, x = x, y = y, hjust = hjust, vjust = vjust, halign = halign, rot = rot,
      gp = grid::gpar(fontsize = size, col = colour, fontfamily = style$family, lineheight = lineheight),
      box_gp = grid::gpar(col = NA, fill = box_fill),
      padding = grid::unit(rep(box_pad, 4), "pt"), margin = grid::unit(0, "pt"),
      r = grid::unit(box_r, "pt")
    )
  } else {
    text <- if (typeset) TypesetLabel(label, rich = FALSE) else label
    face <- if (bold && italic) "bold.italic" else if (bold) "bold" else if (italic) "italic" else "plain"
    grid::textGrob(text, x = x, y = y, hjust = hjust, vjust = vjust, rot = rot,
                   gp = grid::gpar(fontsize = size, col = colour, fontfamily = style$family,
                                   fontface = face, lineheight = lineheight))
  }
}

# Free texts placed at panel fractions (outside the data area allowed).
# Each item: label, xy, size, colour, bold, italic, hjust, vjust, angle.
.figb_texts_layer <- function(texts, values, style) {
  if (is.null(texts) || !length(texts)) return(NULL)
  if (!is.null(texts$label)) texts <- list(texts)
  make <- function() lapply(texts, function(t) {
    v <- values
    if (!is.null(v) && !is.null(t$filter) && is.data.frame(v)) v <- .figb_subset(v, t$filter)
    row <- if (is.null(v)) NULL else .fig_template_unique(t$label, v)
    label <- if (is.null(row)) t$label else FormatTemplate(t$label, row)
    xy <- unlist(t$xy)
    .figb_text_grob(label, grid::unit(xy[1], "npc"), grid::unit(xy[2], "npc"),
                    size = if (is.null(t$size)) style$size$note else t$size,
                    colour = if (is.null(t$colour)) style$colour$ink else .fig_colour(t$colour, style),
                    style = style, bold = isTRUE(t$bold), italic = isTRUE(t$italic),
                    hjust = if (is.null(t$hjust)) 0 else t$hjust, vjust = if (is.null(t$vjust)) 1 else t$vjust,
                    rot = if (is.null(t$angle)) 0 else t$angle)
  })
  .figb_annotation(.figb_deferred(make))
}

# A grob whose children are built when it is drawn, so that rich text is
# laid out with the metrics of the output device.
.figb_deferred <- function(make) grid::gTree(make = make, cl = "phenoscapR_deferred")

#' @exportS3Method grid::makeContent
makeContent.phenoscapR_deferred <- function(x) {
  kids <- x$make()
  if (inherits(kids, "grob")) kids <- list(kids)
  grid::setChildren(x, do.call(grid::gList, kids))
}

# A grob layer spanning the whole panel (npc 0-1 = data area).
.figb_annotation <- function(grob) {
  ggplot2::annotation_custom(grob, xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf)
}

# ---- tick labels as rotated figure labels -------------------------------------------------

# Labels along the bottom (or top) edge of the panel at npc positions `at`.
# A rotated label is aligned like rotated figure tick labels: the right edge
# of its rotated bounding box at the tick, its top edge `pad` points below the
# axis. Optional per-label text colours and rounded background boxes.
.figb_tick_labels <- function(labels, at, style, size = 5.1, angle = 0, pad = 3.5,
                              colours = NULL, fills = NULL, fill_alpha = 1, box_pad = 0,
                              side = c("bottom", "top", "left", "right"), italic = FALSE,
                              hjust = NULL) {
  side <- match.arg(side)
  n <- length(labels)
  if (!n) return(NULL)
  grid::gTree(labels = as.character(labels), at = at, size = size, angle = angle, pad = pad,
              colours = if (is.null(colours)) rep(style$colour$ink, n) else rep_len(colours, n),
              fills = if (is.null(fills)) rep(NA_character_, n) else rep_len(fills, n),
              fill_alpha = fill_alpha, box_pad = box_pad, side = side, italic = italic,
              hjust = hjust, style = style, cl = "phenoscapR_ticklabels")
}

# Sizes (points) of the rotated bounding boxes of tick labels.
.figb_label_boxes <- function(x) {
  a <- x$angle * pi / 180
  n <- length(x$labels)
  wh <- vapply(seq_len(n), function(i) {
    probe <- .figb_text_grob(x$labels[i], grid::unit(0.5, "npc"), grid::unit(0.5, "npc"), x$size,
                             x$colours[i], x$style, italic = x$italic, box_fill = NA,
                             box_pad = x$box_pad, box_r = x$box_pad)
    c(grid::convertWidth(grid::grobWidth(probe), "pt", valueOnly = TRUE),
      grid::convertHeight(grid::grobHeight(probe), "pt", valueOnly = TRUE))
  }, numeric(2))
  wh <- matrix(wh, nrow = 2L)
  list(bw = abs(wh[1, ] * cos(a)) + abs(wh[2, ] * sin(a)), bh = abs(wh[1, ] * sin(a)) + abs(wh[2, ] * cos(a)))
}

#' @exportS3Method grid::makeContent
makeContent.phenoscapR_ticklabels <- function(x) {
  n <- length(x$labels)
  boxes <- .figb_label_boxes(x)
  kids <- vector("list", n)
  for (i in seq_len(n)) {
    fill <- x$fills[i]
    if (!is.na(fill)) fill <- grDevices::adjustcolor(fill, alpha.f = x$fill_alpha)
    bw <- boxes$bw[i]
    bh <- boxes$bh[i]
    if (x$side %in% c("bottom", "top")) {
      # horizontal labels are centred on the tick, rotated ones end at it
      dx <- if (!is.null(x$hjust)) (0.5 - x$hjust) * bw else if (x$angle == 0) 0 else -bw / 2
      cx <- grid::unit(x$at[i], "npc") + grid::unit(dx, "pt")
      cy <- if (x$side == "bottom") grid::unit(0, "npc") - grid::unit(x$pad + bh / 2, "pt") else
        grid::unit(1, "npc") + grid::unit(x$pad + bh / 2, "pt")
    } else {
      cy <- grid::unit(x$at[i], "npc")
      cx <- if (x$side == "left") grid::unit(0, "npc") - grid::unit(x$pad + bw / 2, "pt") else
        grid::unit(1, "npc") + grid::unit(x$pad + bw / 2, "pt")
    }
    kids[[i]] <- .figb_text_grob(x$labels[i], cx, cy, x$size, x$colours[i], x$style,
                                 italic = x$italic, rot = x$angle, box_fill = fill,
                                 box_pad = x$box_pad, box_r = x$box_pad,
                                 halign = if (x$side == "left") 1 else if (x$side == "right") 0 else 0.5)
  }
  grid::setChildren(x, do.call(grid::gList, kids))
}

# ---- colour bar -------------------------------------------------------------------

# A vertical colour bar filling its viewport, ticks and labels on the right
# and a rotated title beyond them, as figure colour bars.
.figb_colourbar_grob <- function(lut, limits, breaks, labels, title, style, tick_size = 4.6,
                                 title_size = 4.8, tick_length = 1.5, outline = "#000000") {
  grid::gTree(lut = lut, limits = limits, breaks = breaks, labels = labels, title = title,
              style = style, tick_size = tick_size, title_size = title_size,
              tick_length = tick_length, outline = outline, cl = "phenoscapR_colourbar")
}

#' @exportS3Method grid::makeContent
makeContent.phenoscapR_colourbar <- function(x) {
  pt <- function(v) grid::unit(v, "pt")
  y <- (x$breaks - x$limits[1]) / diff(x$limits)
  lwd_pt <- .figb_lwd
  img <- grid::rasterGrob(matrix(rev(x$lut), ncol = 1), x = 0, y = 0, width = 1, height = 1,
                          just = c(0, 0), interpolate = FALSE)
  frame <- grid::rectGrob(gp = grid::gpar(fill = NA, col = x$outline, lwd = lwd_pt(0.4)))
  ticks <- grid::segmentsGrob(grid::unit(1, "npc"), grid::unit(y, "npc"),
                              grid::unit(1, "npc") + pt(x$tick_length), grid::unit(y, "npc"),
                              gp = grid::gpar(col = x$outline, lwd = lwd_pt(0.8)))
  labs <- lapply(seq_along(y), function(i) {
    .figb_text_grob(x$labels[i], grid::unit(1, "npc") + pt(x$tick_length + 3.5), grid::unit(y[i], "npc"),
                    x$tick_size, x$style$colour$ink, x$style, hjust = 0, vjust = 0.5)
  })
  widths <- vapply(labs, function(g) grid::convertWidth(grid::grobWidth(g), "pt", valueOnly = TRUE), numeric(1))
  kids <- c(list(img, frame, ticks), labs)
  if (!is.null(x$title) && nzchar(x$title)) {
    kids <- c(kids, list(.figb_text_grob(
      x$title, grid::unit(1, "npc") + pt(x$tick_length + 3.5 + max(c(0, widths)) + 4),
      grid::unit(0.5, "npc"), x$title_size, x$style$colour$ink, x$style, hjust = 0.5, vjust = 1, rot = 90,
      lineheight = 1.1
    )))
  }
  grid::setChildren(x, do.call(grid::gList, kids))
}

# Colour bar layer at a box given in panel fractions c(left, bottom, width,
# height); `spec` holds box, title, breaks, labels and sizes.
.figb_colourbar_layer <- function(spec, lut, limits, style) {
  if (is.null(spec)) return(NULL)
  box <- unlist(spec$box)
  if (length(box) != 4L) stop("colourbar$box must be c(left, bottom, width, height) in panel fractions.", call. = FALSE)
  breaks <- if (is.null(spec$breaks)) pretty(limits) else unlist(spec$breaks)
  breaks <- breaks[breaks >= limits[1] - 1e-12 & breaks <= limits[2] + 1e-12]
  labels <- if (is.null(spec$labels)) {
    gsub("-", "\u2212", format(breaks, trim = TRUE, drop0trailing = TRUE))
  } else as.character(unlist(spec$labels))
  bar <- .figb_colourbar_grob(lut, limits, breaks, labels, spec$title, style,
                              tick_size = if (is.null(spec$tick_size)) 4.6 else spec$tick_size,
                              title_size = if (is.null(spec$title_size)) 4.8 else spec$title_size)
  bar$vp <- grid::viewport(x = box[1], y = box[2], width = box[3], height = box[4], just = c(0, 0))
  .figb_annotation(grid::gTree(children = grid::gList(bar)))
}

# ---- rasterised point layers ----------------------------------------------------------------

# Points with diameters in points, drawn into an off-screen raster at the
# style resolution when the panel is drawn, so that dense layers stay small
# in vector output. Shapes: "o" (circle) or "D" (diamond, as the matplotlib
# marker of the same size). Edges are optional.
.figb_points_grob <- function(x, y, colour, diameter, xlim, ylim, shape = "o", edge = NA,
                              edge_width = 0, dpi = 450, raster = TRUE) {
  n <- length(x)
  grid::gTree(px = as.numeric(x), py = as.numeric(y), colour = rep_len(colour, n),
              diameter = rep_len(diameter, n), shape = rep_len(shape, n), edge = rep_len(edge, n),
              edge_width = rep_len(edge_width, n), xlim = xlim, ylim = ylim, dpi = dpi,
              raster = raster, cl = "phenoscapR_points")
}

# Vector grobs of the points in a viewport with native scales xlim, ylim.
.figb_point_shapes <- function(x) {
  lwd_pt <- .figb_lwd
  kids <- list()
  circ <- x$shape != "D"
  # consecutive runs keep the drawing order between shapes
  runs <- rle(circ)
  ends <- cumsum(runs$lengths)
  starts <- ends - runs$lengths + 1L
  for (k in seq_along(starts)) {
    i <- starts[k]:ends[k]
    if (runs$values[k]) {
      kids[[length(kids) + 1L]] <- grid::circleGrob(
        grid::unit(x$px[i], "native"), grid::unit(x$py[i], "native"),
        r = grid::unit(x$diameter[i] / 2, "pt"),
        gp = grid::gpar(fill = x$colour[i], col = ifelse(x$edge_width[i] > 0, x$edge[i], NA),
                        lwd = lwd_pt(x$edge_width[i]))
      )
    } else {
      # diamond: a unit square turned by 45 degrees, side = marker size
      h <- x$diameter[i] * sqrt(2) / 2
      xs <- rep(x$px[i], each = 4L)
      ys <- rep(x$py[i], each = 4L)
      dx <- as.vector(t(outer(h, c(0, 1, 0, -1))))
      dy <- as.vector(t(outer(h, c(1, 0, -1, 0))))
      kids[[length(kids) + 1L]] <- grid::polygonGrob(
        grid::unit(xs, "native") + grid::unit(dx, "pt"), grid::unit(ys, "native") + grid::unit(dy, "pt"),
        id = rep(seq_along(i), each = 4L),
        gp = grid::gpar(fill = x$colour[i], col = ifelse(x$edge_width[i] > 0, x$edge[i], NA),
                        lwd = lwd_pt(x$edge_width[i]))
      )
    }
  }
  kids
}

#' @exportS3Method grid::makeContent
makeContent.phenoscapR_points <- function(x) {
  vp <- grid::viewport(xscale = x$xlim, yscale = x$ylim)
  vector_points <- function() {
    g <- grid::gTree(children = do.call(grid::gList, .figb_point_shapes(x)), vp = vp)
    grid::setChildren(x, grid::gList(g))
  }
  if (!length(x$px)) return(grid::setChildren(x, grid::gList()))
  if (!isTRUE(x$raster) || !requireNamespace("ragg", quietly = TRUE)) return(vector_points())
  w <- grid::convertWidth(grid::unit(1, "npc"), "in", valueOnly = TRUE)
  h <- grid::convertHeight(grid::unit(1, "npc"), "in", valueOnly = TRUE)
  if (!(is.finite(w) && is.finite(h) && w > 0 && h > 0)) return(vector_points())
  px_w <- max(1L, ceiling(w * x$dpi))
  px_h <- max(1L, ceiling(h * x$dpi))
  old <- grDevices::dev.cur()
  cap <- ragg::agg_capture(width = px_w, height = px_h, units = "px", res = x$dpi,
                           background = "transparent")
  img <- tryCatch({
    grid::grid.newpage()
    grid::pushViewport(grid::viewport(x = 0, y = 0, width = grid::unit(w, "in"),
                                      height = grid::unit(h, "in"), just = c(0, 0),
                                      xscale = x$xlim, yscale = x$ylim))
    for (g in .figb_point_shapes(x)) grid::grid.draw(g)
    cap(native = TRUE)
  }, finally = {
    grDevices::dev.off()
    if (old > 1L) grDevices::dev.set(old)
  })
  # the drawing occupies the lower left w x h inches of the capture
  r <- grid::rasterGrob(img, x = 0, y = 0, width = grid::unit(px_w / x$dpi, "in"),
                        height = grid::unit(px_h / x$dpi, "in"), just = c(0, 0), interpolate = FALSE)
  grid::setChildren(x, grid::gList(r))
}

# ---- haloed text ---------------------------------------------------------------------

# Text with a halo (a stroke of `halo` points around the glyphs), drawn as
# the text repeated around a small circle under the text itself.
.figb_halo_text <- function(labels, x, y, size, colour, halo_colour = "white", halo = 0.6,
                            fontface = "bold", family = "DejaVu Sans") {
  ang <- seq(0, 2 * pi, length.out = 17)[-17]
  under <- lapply(ang, function(a) {
    grid::textGrob(labels, x = x + grid::unit(halo * cos(a), "pt"), y = y + grid::unit(halo * sin(a), "pt"),
                   gp = grid::gpar(fontsize = size, col = halo_colour, fontface = fontface, fontfamily = family))
  })
  top <- grid::textGrob(labels, x = x, y = y,
                        gp = grid::gpar(fontsize = size, col = colour, fontface = fontface, fontfamily = family))
  grid::gTree(children = do.call(grid::gList, c(under, list(top))))
}

# Line width in points to grid lwd.
.figb_lwd <- function(pt) pt * 96 / 72

# A blank ggplot whose data area spans xlim x ylim exactly, without axes.
.figb_canvas <- function(xlim, ylim, style, reverse_y = FALSE) {
  p <- ggplot2::ggplot() +
    ggplot2::scale_x_continuous(limits = xlim, expand = c(0, 0), oob = .figb_keep_oob) +
    (if (reverse_y) ggplot2::scale_y_reverse(limits = rev(ylim), expand = c(0, 0), oob = .figb_keep_oob) else
      ggplot2::scale_y_continuous(limits = ylim, expand = c(0, 0), oob = .figb_keep_oob)) +
    ggplot2::coord_cartesian(clip = "off") +
    ThemeManuscript(style, grid = "none", axes = "none") +
    ggplot2::theme(axis.text = ggplot2::element_blank(), axis.text.x = ggplot2::element_blank(),
                   axis.text.y = ggplot2::element_blank(), axis.ticks = ggplot2::element_blank(),
                   axis.ticks.length = ggplot2::unit(0, "pt"), axis.title = ggplot2::element_blank(),
                   axis.title.x = ggplot2::element_blank(), axis.title.y = ggplot2::element_blank(),
                   legend.position = "none") +
    ggplot2::labs(x = NULL, y = NULL)
  p
}

# Text theme element of the same class as those of ThemeManuscript() (rich
# text when available), so that theme elements can be merged.
.figb_el <- function(...) {
  if (.figb_rich()) ggtext::element_markdown(...) else ggplot2::element_text(...)
}

# ---- marker legend ---------------------------------------------------------------------

# A frameless legend of markers and labels filled column by column, with
# the spacing rules of common figure legends (sizes in units of the font
# size): padding 0.5 between anchor and box, border padding 0.4, handle
# length, handle-text padding, label and column spacing. `at` is the anchor
# (upper left corner) in panel fractions. Markers: "o" circle, "D" diamond, "s" square, "rect" (a patch
# of handle length by 0.7 font sizes); `marker_size` is the marker diameter
# (or side) in points, drawn with an outline of `marker_edge` points in the
# marker colour as legend markers are.
.figb_marker_key <- function(spec, colours, shapes, style) {
  keys <- as.character(unlist(spec$keys))
  n <- length(keys)
  if (!n) return(NULL)
  labels <- if (is.null(spec$labels)) keys else .figb_display(spec$labels, keys)
  shp <- if (is.null(spec$shapes)) .figb_per_key(shapes, keys, "o") else .figb_per_key(spec$shapes, keys, "o")
  ms <- if (is.null(spec$marker_size)) 3 else spec$marker_size
  ms <- .figb_per_key(ms, keys, 3)
  cols <- .figb_per_key(if (is.null(spec$colours)) colours else spec$colours, keys, "#BBBBBB", "colour")
  grid::gTree(labels = labels, colours = .fig_colour(as.character(cols), style), shapes = shp,
              marker_size = as.numeric(ms), at = as.numeric(unlist(spec$at)),
              marker_edge = if (is.null(spec$marker_edge)) 1 else spec$marker_edge,
              anchor_pad = if (is.null(spec$anchor_pad)) 0.5 else spec$anchor_pad,
              ncol = if (is.null(spec$ncol)) 1L else as.integer(spec$ncol),
              size = if (is.null(spec$size)) style$size$legend else spec$size,
              label_spacing = if (is.null(spec$label_spacing)) 0.5 else spec$label_spacing,
              column_spacing = if (is.null(spec$column_spacing)) 2 else spec$column_spacing,
              handle_text_pad = if (is.null(spec$handle_text_pad)) 0.8 else spec$handle_text_pad,
              handle_length = if (is.null(spec$handle_length)) 2 else spec$handle_length,
              title = spec$title, title_size = if (!is.null(spec$title_size)) spec$title_size else if (!is.null(spec$size)) spec$size else style$size$legend,
              title_align = if (is.null(spec$title_align)) "centre" else spec$title_align,
              style = style, cl = "phenoscapR_markerkey")
}

#' @exportS3Method grid::makeContent
makeContent.phenoscapR_markerkey <- function(x) {
  fs <- if (is.null(x$size)) 5 else x$size
  n <- length(x$labels)
  nrow <- ceiling(n / x$ncol)
  # column-major filling as in figure legends: earlier columns take the extra rows
  per_col <- rep(nrow, x$ncol)
  short <- x$ncol * nrow - n
  if (short > 0) per_col[seq(x$ncol - short + 1L, x$ncol)] <- nrow - 1L
  col_of <- rep(seq_len(x$ncol), per_col)[seq_len(n)]
  row_of <- unlist(lapply(per_col, seq_len))[seq_len(n)]
  probes <- lapply(x$labels, function(l) .figb_text_grob(l, grid::unit(0, "pt"), grid::unit(0, "pt"), fs,
                                                          x$style$colour$ink, x$style, hjust = 0, vjust = 0.5))
  w <- vapply(probes, function(g) grid::convertWidth(grid::grobWidth(g), "pt", valueOnly = TRUE), numeric(1))
  hl <- x$handle_length * fs
  pad <- x$handle_text_pad * fs
  col_w <- vapply(seq_len(x$ncol), function(j) max(c(0, hl + pad + w[col_of == j])), numeric(1))
  pitch <- (1 + x$label_spacing) * fs
  x0 <- grid::unit(x$at[1], "npc") + grid::unit((x$anchor_pad + 0.4) * fs, "pt")
  top <- grid::unit(x$at[2], "npc") - grid::unit((x$anchor_pad + 0.4) * fs, "pt")
  kids <- list()
  if (!is.null(x$title) && nzchar(x$title)) {
    tw <- sum(col_w) + x$column_spacing * fs * (x$ncol - 1)
    tx <- if (x$title_align == "left") x0 else x0 + grid::unit(tw / 2, "pt")
    kids[[1]] <- .figb_text_grob(x$title, tx, top, x$title_size, x$style$colour$ink, x$style,
                                 hjust = if (x$title_align == "left") 0 else 0.5, vjust = 1)
    # the title box is followed by one label spacing
    top <- top - grid::unit(x$title_size * 1.0 + x$label_spacing * fs, "pt")
  }
  for (i in seq_len(n)) {
    j <- col_of[i]
    cx <- sum(col_w[seq_len(j - 1L)]) + x$column_spacing * fs * (j - 1L)
    cy <- top - grid::unit((row_of[i] - 1) * pitch + fs / 2, "pt")
    mx <- x0 + grid::unit(cx + hl / 2, "pt")
    d <- x$marker_size[i] + x$marker_edge
    col <- x$colours[i]
    kids[[length(kids) + 1L]] <- switch(x$shapes[i],
      D = grid::polygonGrob(mx + grid::unit(c(0, 1, 0, -1) * d * sqrt(2) / 2, "pt"),
                            cy + grid::unit(c(1, 0, -1, 0) * d * sqrt(2) / 2, "pt"),
                            gp = grid::gpar(fill = col, col = NA)),
      s = grid::rectGrob(mx, cy, width = grid::unit(d, "pt"), height = grid::unit(d, "pt"),
                         gp = grid::gpar(fill = col, col = NA)),
      rect = grid::rectGrob(mx, cy, width = grid::unit(hl, "pt"), height = grid::unit(0.7 * fs, "pt"),
                            gp = grid::gpar(fill = col, col = NA)),
      grid::circleGrob(mx, cy, r = grid::unit(d / 2, "pt"), gp = grid::gpar(fill = col, col = NA))
    )
    kids[[length(kids) + 1L]] <- .figb_text_grob(x$labels[i], x0 + grid::unit(cx + hl + pad, "pt"), cy, fs,
                                                 x$style$colour$ink, x$style, hjust = 0, vjust = 0.5)
  }
  grid::setChildren(x, do.call(grid::gList, kids))
}

# Keep values outside the scale limits (drawn without clipping).
.figb_keep_oob <- function(x, range = NULL, ...) x
