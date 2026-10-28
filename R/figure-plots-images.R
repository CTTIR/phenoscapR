# Image-type plot builders: cell maps, territory maps, fluorescence fields
# and generic images/galleries/schematics. They return 'grid' grobs whose
# data area keeps the aspect ratio of the map inside the panel box (centred,
# as an equal-aspect axes). Dense point and polygon layers are rasterised at
# the style's resolution when drawn, so PDF files stay small. Coordinates are
# physical units with y increasing downwards (image convention).

#' Cell Map
#'
#' Draws cells as points in layers (by label or any column condition) on an
#' optional interface-zone tint, with frame, scale bar, field label, title
#' above the map and boxes. Point sizes follow the area convention of common
#' scatter plots (`size` is the marker area in square points); larger
#' markers get a thin edge. Without a field size the whole section is drawn
#' and the scale bar sits below the map.
#'
#' A layer is a list with `column` (default `"label"`) and `values`, or
#' `filter` (named list of column to values, all must match); `colour` (one
#' colour, or a named list of value to colour for the layer's `column`);
#' `size`; optional `edge_colour` (default white), `edge_width` (default 0.25
#' points for sizes above 4, else 0) and `z` (drawing order). Cells in no
#' layer are drawn with `rest` (set `rest = NULL` to omit them).
#'
#' @param data A [CellMapData()] result or a data frame of cells.
#' @param layers List of layers (see Details).
#' @param rest Layer for all remaining cells, or `NULL`.
#' @param point_extra Points added to every marker diameter: sub-pixel
#'   markers of some renderers look denser than their nominal size (about
#'   0.055 matches 'matplotlib' output at 450 dpi).
#' @param exclusive If `TRUE`, a cell is drawn by the first layer that
#'   selects it only; with `FALSE` every matching layer draws it.
#' @param title_align `"left"` (title at the left edge, subtitle after it)
#'   or `"centre"` (title centred above the map).
#' @param interface_colour Colour of the interface zone.
#' @param limits Optional `c(xmin, xmax, ymin, ymax)`; default the field or
#'   the data range.
#' @param expand Fraction of the data range added on each side when no
#'   field size is given (0.05 imitates automatic axis margins).
#' @param scale_bar `NULL` or a list: `length`, `label`, `x` (start, as a
#'   fraction of the map width from the left), `y` (distance of the bar from
#'   the lower map edge as a fraction of the width; negative values place it
#'   below the map), `label_offset` (signed distance of the label from the
#'   bar, as a fraction of the width; negative values hang it below),
#'   `linewidth` (points), `size` (points), `colour` and `relative_to`
#'   (`"limits"`, the default, or `"data"`: fractions of the data extent).
#' @param frame Draw a frame around the map.
#' @param frame_colour,frame_width Frame colour and width (points).
#' @param label Optional text in the top-left corner of the map.
#' @param label_colour,label_size Label colour and size.
#' @param title,subtitle Optional title (bold) and subtitle (muted) above the
#'   map; taken from `labels` when `label_id` is given.
#' @param title_colour Title colour.
#' @param title_size Title size (points); the subtitle is 1 point smaller.
#' @param labels Optional data frame of titles, with `label_id` selecting a
#'   row by `labels_key`.
#' @param groups Optional data frame giving the group of `label_id` (column
#'   `labels_key` and `group_column`); default `labels`.
#' @param label_id,labels_key Row selection in `labels`.
#' @param title_column,subtitle_column,group_column Columns of `labels`.
#' @param group_colours Named colours by `group_column` value for the title.
#' @param boxes Optional data frame or list of squares to outline (`x`, `y`,
#'   `size`), drawn with `box_colour` and `box_width`.
#' @param box_colour,box_width Box colour and width (points).
#' @param box_size Box width used when `boxes` has no `size` column.
#' @param style A [ManuscriptStyle()] object.
#' @return A 'grid' grob.
#' @examples
#' set.seed(1)
#' d <- data.frame(x = runif(300, 0, 100), y = runif(300, 0, 100),
#'                 label = sample(c("t", "a", "b"), 300, TRUE))
#' m <- CellMapData(d, centre = c(50, 50), size = 60,
#'                  interface = list(labels = "t", radius = 5, step = 2))
#' g <- PlotCellMap(m, layers = list(list(values = "t", colour = "#A6A6A6", size = 2.5),
#'                                   list(values = "b", colour = "#7B2FBE", size = 16)),
#'                  scale_bar = list(length = 10, label = "10 um"))
#' grid::grid.newpage(); grid::grid.draw(g)
#' @export
PlotCellMap <- function(data, layers = list(), rest = list(colour = "#E3E3E3", size = 1.2), exclusive = TRUE,
                        point_extra = 0,
                        title_align = "left",
                        interface_colour = "subsets/interface", limits = NULL, expand = 0,
                        scale_bar = NULL, frame = TRUE, frame_colour = "frame", frame_width = NULL,
                        label = NULL, label_colour = "white", label_size = 5.5, title = NULL,
                        subtitle = NULL, title_colour = "ink", title_size = 5.6, labels = NULL,
                        groups = NULL, label_id = NULL, labels_key = "patient", title_column = "patient",
                        subtitle_column = "text", group_column = "group", group_colours = NULL,
                        boxes = NULL, box_colour = "ink", box_width = 0.5, box_size = NULL,
                        style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  if (is.data.frame(data)) data <- CellMapData(data)
  if (!inherits(data, "phenoscapR_cellmap")) stop("data must come from CellMapData().", call. = FALSE)
  cells <- data$cells
  lim <- if (!is.null(limits)) unlist(limits) else data$extent
  if (is.null(data$size) && is.null(limits) && expand > 0) {
    lim <- lim + c(-1, 1, -1, 1) * expand * rep(c(diff(lim[1:2]), diff(lim[3:4])), each = 2)
  }
  pts <- .fig_c_layer_points(cells, layers, rest, style, exclusive)
  if (nrow(pts)) pts$size <- (sqrt(pts$size) + point_extra)^2
  layers_out <- list()
  if (!is.null(data$interface) && nrow(data$interface)) {
    layers_out$zone <- .fig_c_zone_grob(data$interface, attr(data$interface, "step"),
                                      .fig_colour(interface_colour, style), lim)
  }
  if (nrow(pts)) {
    layers_out$points <- .fig_c_raster_grob(function() .fig_c_draw_points(pts), lim, style$page$dpi)
  }
  field <- !is.null(data$size)
  children <- if (field) list() else layers_out
  children <- c(children, .fig_c_overlays(lim, style, frame = frame, frame_colour = frame_colour,
                                          frame_width = frame_width, scale_bar = scale_bar,
                                          label = label, label_colour = label_colour,
                                          label_size = label_size, boxes = boxes,
                                          box_colour = box_colour, box_width = box_width, box_size = box_size,
                                          data_lim = data$extent))
  tt <- .fig_c_titles(title, subtitle, title_colour, labels, label_id, labels_key, title_column,
                      subtitle_column, group_column, group_colours, style, groups)
  children <- c(children, .fig_c_title_grobs(tt$title, tt$subtitle, tt$colour, title_size, style, title_align))
  .fig_c_map_tree(children, lim, "phenoscapR_cellmap_grob", clipped = if (field) layers_out else list())
}

#' Cell Territory Map
#'
#' Draws Voronoi territories from [TerritoryTiles()] filled by class, with
#' thin white borders, a frame and a scale bar; boxes mark sub-fields.
#'
#' @param data A [TerritoryTiles()] result.
#' @param colours Named colours by class.
#' @param border_colour,border_width Tile border colour and width (points).
#' @param scale_bar,frame,frame_colour,frame_width,boxes,box_colour,box_width,box_size
#'   As in [PlotCellMap()]; `boxes` may carry a `colour` column.
#' @param title Optional title centred above the map.
#' @param title_size Title size (points).
#' @param style A [ManuscriptStyle()] object.
#' @return A 'grid' grob.
#' @examples
#' if (requireNamespace("deldir", quietly = TRUE)) {
#'   set.seed(2)
#'   d <- data.frame(x = runif(300, 0, 100), y = runif(300, 0, 100),
#'                   label = sample(c("t", "a"), 300, TRUE))
#'   tt <- TerritoryTiles(d, c(50, 50), 40, cap = 5, classes = list(tumour = "t"))
#'   g <- PlotTerritories(tt, colours = list(tumour = "#F4B6C2", other = "#DDDDDD"))
#'   grid::grid.newpage(); grid::grid.draw(g)
#' }
#' @export
PlotTerritories <- function(data, colours, border_colour = "white", border_width = 0.12,
                            scale_bar = list(length = 100, label = "100 um", y = 0.07,
                                             linewidth = 1.4, size = 4.8),
                            frame = TRUE, frame_colour = "frame", frame_width = NULL, boxes = NULL,
                            box_colour = "ink", box_width = 0.9, box_size = NULL, title = NULL, title_size = 5.6,
                            style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  if (!inherits(data, "phenoscapR_territories")) stop("data must come from TerritoryTiles().", call. = FALSE)
  colours <- .fig_colour(colours, style)
  tiles <- data$tiles
  fill <- unname(colours[tiles$class[!duplicated(tiles$tile)]])
  if (anyNA(fill)) stop("No colour for class(es): ", paste(unique(tiles$class[is.na(colours[tiles$class])]), collapse = ", "), call. = FALSE)
  lim <- data$extent
  border <- .fig_colour(border_colour, style)
  draw <- function() {
    grid::grid.polygon(tiles$x, -tiles$y, id = tiles$tile, default.units = "native",
                       gp = grid::gpar(fill = fill, col = border, lwd = border_width / 0.75,
                                       linejoin = "round"))
  }
  children <- .fig_c_overlays(lim, style, frame = frame, frame_colour = frame_colour,
                                          frame_width = frame_width, scale_bar = scale_bar,
                                          boxes = boxes, box_colour = box_colour, box_width = box_width, box_size = box_size)
  if (!is.null(title)) {
    children$title <- .fig_c_text_grob(title, grid::unit(0.5, "npc"),
                                       grid::unit(1, "npc") + grid::unit(2 + title_size * 0.15, "bigpts"),
                                       size = title_size, colour = style$colour$ink, hjust = 0.5, vjust = 0,
                                       style = style)
  }
  .fig_c_map_tree(children, lim, "phenoscapR_territories_grob",
                  clipped = list(tiles = .fig_c_raster_grob(draw, lim, style$page$dpi)))
}

#' Multichannel Fluorescence Field
#'
#' Composes an additive multichannel image from channel windows (a field as
#' returned by `segmantR::sg_read_field()`), display levels and channel
#' colours and weights (see [CompositeFields()] for the layer and level
#' rules), and draws it at its physical extent with optional scale bar,
#' corner text, arrows pointing at cells, crosses on partner cells and
#' boxes.
#'
#' @param field A field (`channels`, `centre`, `size`) or a list of fields
#'   with `index` selecting one.
#' @param layers List of channel layers (see [CompositeFields()]).
#' @param slide,levels Optional range tables (`channel`, `lo`, `hi`).
#' @param marks Optional data frame of cells to annotate (`x`, `y`, and for
#'   crosses `partner_x`, `partner_y`); `marks_index` selects rows.
#' @param index,marks_index Optional selections.
#' @param gamma,min_span Display gamma and minimum level span.
#' @param interpolate Smooth the raster when scaling (bilinear).
#' @param arrow `NULL` or a list: `tip`, `tail` (offsets from the cell along
#'   both axes, physical units), `colour`, `linewidth` (points), `head`
#'   (arrow-head scale in points) and `shrink` (points left free at both
#'   ends).
#' @param cross `NULL` or a list: `colour`, `size` (marker area in square
#'   points), `linewidth`; drawn at the partner positions.
#' @param corner_text `NULL`, a fixed text, or a list with `column` and
#'   `format` (sprintf) taking the value from the first mark.
#' @param corner_size,corner_colour Corner text size and colour.
#' @param corner_at Corner text position (fractions of the field, top-left
#'   anchored).
#' @param label Optional field label in the top-left corner (as
#'   `corner_text`, larger).
#' @param label_size Label size.
#' @param scale_bar,boxes,box_colour,box_width,box_size,frame As in
#'   [PlotCellMap()].
#' @param style A [ManuscriptStyle()] object.
#' @return A 'grid' grob.
#' @examples
#' set.seed(3)
#' field <- list(channels = list(cd3 = matrix(runif(400, 0, 100), 20),
#'                               foxp3 = matrix(runif(400, 0, 100), 20)),
#'               centre = c(10, 10), size = 10)
#' g <- PlotFluorescenceField(field,
#'   layers = list(list(channel = "cd3", colour = "#00C8FF", lo = "q0.01", hi = "q0.99"),
#'                 list(channel = "foxp3", colour = "#FF00C8", lo = "q0.5", hi = "q1",
#'                      overlay = TRUE)),
#'   scale_bar = list(length = 5, label = "5 um"))
#' grid::grid.newpage(); grid::grid.draw(g)
#' @export
PlotFluorescenceField <- function(field, layers, slide = NULL, levels = NULL, marks = NULL, index = NULL,
                                  marks_index = NULL, gamma = 0.8, min_span = 1, interpolate = TRUE,
                                  arrow = NULL, cross = NULL, corner_text = NULL, corner_size = 5,
                                  corner_colour = "white", corner_at = c(0.04, 0.96), label = NULL, label_size = 5.5,
                                  scale_bar = list(length = 50, label = "50 um", colour = "white"),
                                  boxes = NULL, box_colour = "white", box_width = 0.6, box_size = NULL, frame = FALSE,
                                  style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  if (!is.null(index)) field <- field[[index]]
  if (is.null(field$channels)) stop("field must hold channel matrices.", call. = FALSE)
  row <- if (is.null(field$row)) data.frame(x = NA) else field$row
  rgb <- .fig_c_composite(field, layers, list(slide = slide, levels = levels), row, "source", gamma,
                          min_span, style)
  half <- field$size / 2
  lim <- c(field$centre[1] - half, field$centre[1] + half, field$centre[2] - half, field$centre[2] + half)
  children <- list(image = grid::rasterGrob(rgb, x = grid::unit(lim[1], "native"),
                                            y = grid::unit(-lim[4], "native"),
                                            width = grid::unit(field$size, "native"),
                                            height = grid::unit(field$size, "native"),
                                            just = c(0, 0), interpolate = interpolate))
  if (!is.null(marks)) {
    m <- if (!is.null(marks_index)) marks[unlist(marks_index), , drop = FALSE] else marks
    if (!is.null(arrow)) children$arrows <- .fig_c_arrow_grobs(m, arrow, style)
    if (!is.null(cross)) {
      children$crosses <- .fig_c_cross_grob(m$partner_x, m$partner_y, cross, style)
    }
  }
  corner <- .fig_c_mark_text(corner_text, marks, marks_index)
  label <- .fig_c_mark_text(label, marks, marks_index)
  children <- c(children, .fig_c_overlays(lim, style, frame = frame, frame_colour = "frame",
                                          frame_width = NULL, scale_bar = scale_bar,
                                          label = label, label_colour = corner_colour,
                                          label_size = label_size, boxes = boxes,
                                          box_colour = box_colour, box_width = box_width, box_size = box_size))
  if (!is.null(corner)) {
    children$corner <- .fig_c_text_grob(corner, grid::unit(corner_at[1], "npc"), grid::unit(corner_at[2], "npc"),
                                        size = corner_size, colour = .fig_colour(corner_colour, style),
                                        hjust = 0, vjust = 1, style = style)
  }
  .fig_c_map_tree(children, lim, "phenoscapR_field_grob", clip = TRUE)
}

#' Image, Image Gallery or Schematic
#'
#' Draws one raster image, a gallery of images, or a schematic of shapes.
#'
#' * A single image (RGB array or grey matrix with values in 0-1) fills the
#'   panel box with optional centre cross, scale bar and corner label.
#' * A [CompositeFields()] result is laid out as a gallery: one gallery row
#'   per value of `row` (or per field), each field's views side by side, in
#'   absolute millimetres from the top-left of the panel box: tiles of
#'   `tile_mm`, `view_gap_mm` between the views of a field, `field_gap_mm`
#'   between fields and `row_pitch_mm` from row to row. Column headers,
#'   row labels (several lines, from columns of the fields' rows or a label
#'   map), centre crosses, corner labels and a scale bar are optional.
#' * A [SchematicShapes()] result is drawn in its own coordinates with equal
#'   aspect.
#'
#' @param data An array/matrix, a [CompositeFields()] result or a
#'   [SchematicShapes()] result.
#' @param row Column of the gallery info defining gallery rows; `NULL`
#'   gives one row per field.
#' @param row_levels Optional order of the row values.
#' @param tile_mm,view_gap_mm,field_gap_mm,row_pitch_mm Gallery geometry.
#' @param column_labels Optional header texts per view (repeated for every
#'   field of the widest row) with `header_size` and `header_colour`.
#' @param header_size,header_colour,header_gap_mm Header text settings.
#' @param row_labels Optional list of row-label lines, each a list with
#'   `column` (info column) or `map` (named list from the row value), `dy`
#'   (fraction of the tile height from the bottom), `size`, `colour`,
#'   `bold`, `replace` (named list of text substitutions) and `x_mm`
#'   (position relative to the panel's left edge; negative is left of it);
#'   `hjust` aligns the text.
#' @param cross Draw a centre cross on every tile (list with `colour`,
#'   `size` points, `linewidth` points) or `NULL`.
#' @param corner Optional list with `column`, `view`, `size`, `colour`: text
#'   in the top-left corner of tiles of that view.
#' @param scale_bar Optional list: `length` (physical units), `pixel_size`,
#'   `view`, `linewidth`, `colour`, `which` (`"first"` tile only or `"row"`:
#'   first tile of every row).
#' @param title Optional gallery title placed above the column headers;
#'   `{n}` is replaced by the number of fields shown and `{total}` by the
#'   number of rows of `total`.
#' @param total Optional data frame counted for `{total}`.
#' @param title_size,title_gap_mm Title size (points) and distance above the
#'   tiles (mm).
#' @param interpolate Smooth raster scaling.
#' @param style A [ManuscriptStyle()] object.
#' @return A 'grid' grob.
#' @examples
#' shapes <- SchematicShapes(shapes = list(
#'   list(type = "roundrect", x = 0.5, y = 0.5, w = 0.8, h = 0.5, fill = "#EEEEEE",
#'        colour = "#999999", r = 1),
#'   list(type = "text", x = 0.5, y = 0.5, label = "Box"),
#'   list(type = "arrow", x = 0.1, y = 0.1, xend = 0.9, yend = 0.1, colour = "#000000")))
#' grid::grid.newpage(); grid::grid.draw(PlotImage(shapes))
#' set.seed(4)
#' grid::grid.newpage(); grid::grid.draw(PlotImage(array(runif(300), c(10, 10, 3))))
#' @export
PlotImage <- function(data, row = NULL, row_levels = NULL, tile_mm = 10, view_gap_mm = 0.36,
                      field_gap_mm = 1.8, row_pitch_mm = 11, column_labels = NULL, header_size = 4.6,
                      header_colour = "muted", header_gap_mm = 0.5, row_labels = NULL,
                      cross = list(colour = "#FFD54F", size = 3.5, linewidth = 0.5), corner = NULL,
                      scale_bar = NULL, title = NULL, total = NULL, title_size = 5.6, title_gap_mm = 4.5,
                      interpolate = TRUE, style = ManuscriptStyle()) {
  style <- .fig_check_style(style)
  if (inherits(data, "phenoscapR_shapes")) return(.fig_c_shapes_grob(data, style))
  if (inherits(data, "phenoscapR_images")) {
    return(.fig_c_gallery_grob(data, row, row_levels, tile_mm, view_gap_mm, field_gap_mm, row_pitch_mm,
                               column_labels, header_size, header_colour, header_gap_mm, row_labels,
                               cross, corner, scale_bar, interpolate, style, title, total, title_size,
                               title_gap_mm))
  }
  if (!is.array(data) && !is.matrix(data)) stop("data must be an image array, images or shapes.", call. = FALSE)
  img <- pmin(pmax(data, 0), 1)
  grid::gTree(children = do.call(grid::gList, c(
    list(grid::rasterGrob(img, width = grid::unit(1, "npc"), height = grid::unit(1, "npc"),
                          interpolate = interpolate)),
    .fig_c_tile_marks(cross, style))), cl = "phenoscapR_image_grob")
}

# ---- drawing internals ---------------------------------------------------------

# A gTree whose data viewport keeps the map aspect, centred in the panel box.
# y is drawn negated so that y grows downwards.
.fig_c_map_tree <- function(children, lim, cl, clip = FALSE, clipped = list()) {
  dx <- diff(lim[1:2])
  dy <- diff(lim[3:4])
  lay <- grid::viewport(layout = grid::grid.layout(1, 1, widths = grid::unit(dx, "null"),
                                                   heights = grid::unit(dy, "null"), respect = TRUE),
                        name = "phenoscapR-map-layout")
  data_vp <- grid::viewport(layout.pos.row = 1, layout.pos.col = 1, xscale = lim[1:2],
                            yscale = -rev(lim[3:4]), clip = if (clip) "on" else "off",
                            name = "phenoscapR-map-data")
  children <- children[!vapply(children, is.null, logical(1))]
  clipped <- clipped[!vapply(clipped, is.null, logical(1))]
  if (length(clipped)) {
    inner <- grid::gTree(children = do.call(grid::gList, unname(clipped)),
                         vp = grid::viewport(xscale = lim[1:2], yscale = -rev(lim[3:4]), clip = "on"))
    children <- c(list(inner), children)
  }
  grid::gTree(children = do.call(grid::gList, unname(children)), vp = grid::vpStack(lay, data_vp), cl = cl)
}

# Points of all layers, in drawing order.
.fig_c_layer_points <- function(cells, layers, rest, style, exclusive = TRUE) {
  used <- rep(FALSE, nrow(cells))
  parts <- list()
  for (k in seq_along(layers)) {
    ly <- layers[[k]]
    col <- if (is.null(ly$column)) "label" else ly$column
    sel <- if (!is.null(ly$filter)) {
      .fig_c_filter(cells, ly$filter)
    } else if (!is.null(ly$values)) {
      as.character(cells[[col]]) %in% as.character(unlist(ly$values))
    } else {
      rep(TRUE, nrow(cells))
    }
    if (exclusive) sel <- sel & !used
    used <- used | sel
    if (!any(sel)) next
    colour <- if (is.list(ly$colour) || length(ly$colour) > 1L) {
      map <- .fig_colour(ly$colour, style)
      unname(map[as.character(cells[[col]][sel])])
    } else {
      rep(.fig_colour(ly$colour, style), sum(sel))
    }
    if (anyNA(colour)) stop("Layer ", k, " lacks colours for some values.", call. = FALSE)
    size <- if (is.null(ly$size)) 1 else ly$size
    ew <- if (!is.null(ly$edge_width)) ly$edge_width else if (size > 4) 0.25 else 0
    parts[[length(parts) + 1L]] <- data.frame(
      x = cells$x[sel], y = cells$y[sel], colour = colour, size = size,
      edge = if (ew > 0) .fig_colour(if (is.null(ly$edge_colour)) "white" else ly$edge_colour, style) else NA_character_,
      edge_width = ew, z = if (is.null(ly$z)) k else ly$z, layer = k, stringsAsFactors = FALSE)
  }
  if (!is.null(rest) && any(!used)) {
    parts[[length(parts) + 1L]] <- data.frame(
      x = cells$x[!used], y = cells$y[!used], colour = .fig_colour(rest$colour, style),
      size = if (is.null(rest$size)) 1.2 else rest$size, edge = NA_character_, edge_width = 0,
      z = if (is.null(rest$z)) 1 else rest$z, layer = 0L, stringsAsFactors = FALSE)
  }
  if (!length(parts)) return(data.frame(x = numeric(0)))
  out <- do.call(rbind, parts)
  # Stable by z, then layer order (matplotlib draws equal z in call order).
  out[order(out$z, out$layer == 0L, seq_len(nrow(out)), method = "radix"), , drop = FALSE]
}

.fig_c_draw_points <- function(pts) {
  runs <- rle(paste(pts$z, pts$layer))
  ends <- cumsum(runs$lengths)
  starts <- ends - runs$lengths + 1L
  for (r in seq_along(starts)) {
    p <- pts[starts[r]:ends[r], , drop = FALSE]
    d <- sqrt(p$size[1])
    if (is.na(p$edge[1])) {
      grid::grid.points(p$x, -p$y, pch = 16, default.units = "native",
                        size = grid::unit(d / 0.75, "bigpts"), gp = grid::gpar(col = p$colour))
    } else {
      grid::grid.points(p$x, -p$y, pch = 21, default.units = "native",
                        size = grid::unit(d / 0.75, "bigpts"),
                        gp = grid::gpar(col = p$edge, fill = p$colour, lwd = p$edge_width[1] / 0.75))
    }
  }
}

# Interface tint: grid points as square cells of side `step`.
.fig_c_zone_grob <- function(zone, step, colour, lim) {
  if (is.null(step)) step <- 2
  xs <- sort(unique(zone$x))
  ys <- sort(unique(zone$y))
  gx <- seq(min(xs), max(xs) + step / 2, by = step)
  gy <- seq(min(ys), max(ys) + step / 2, by = step)
  m <- matrix(NA_character_, length(gy), length(gx))
  m[cbind(match(round((zone$y - gy[1]) / step), round((gy - gy[1]) / step)),
          match(round((zone$x - gx[1]) / step), round((gx - gx[1]) / step)))] <- colour
  grid::rasterGrob(grDevices::as.raster(m), x = grid::unit(gx[1] - step / 2, "native"),
                   y = grid::unit(-(max(gy) + step / 2), "native"),
                   width = grid::unit(length(gx) * step, "native"),
                   height = grid::unit(length(gy) * step, "native"), just = c(0, 0), interpolate = FALSE)
}

# A layer drawn off-screen at `dpi` when the grob is drawn and placed as a raster.
.fig_c_raster_grob <- function(draw, lim, dpi) {
  grid::gTree(draw = draw, lim = lim, dpi = dpi, cl = "phenoscapR_rasterlayer")
}

#' @export
#' @importFrom grid makeContent
makeContent.phenoscapR_rasterlayer <- function(x) {
  w <- grid::convertWidth(grid::unit(1, "npc"), "inches", valueOnly = TRUE)
  h <- grid::convertHeight(grid::unit(1, "npc"), "inches", valueOnly = TRUE)
  wpx <- max(1L, as.integer(ceiling(w * x$dpi)))
  hpx <- max(1L, as.integer(ceiling(h * x$dpi)))
  img <- .fig_c_offscreen(wpx, hpx, x$dpi, function() {
    grid::pushViewport(grid::viewport(xscale = x$lim[1:2], yscale = -rev(x$lim[3:4])))
    x$draw()
    grid::popViewport()
  })
  grid::setChildren(x, grid::gList(grid::rasterGrob(img, width = grid::unit(1, "npc"),
                                                    height = grid::unit(1, "npc"), interpolate = FALSE)))
}

.fig_c_offscreen <- function(wpx, hpx, dpi, draw) {
  cur <- grDevices::dev.cur()
  if (requireNamespace("ragg", quietly = TRUE)) {
    cap <- ragg::agg_capture(width = wpx, height = hpx, units = "px", res = dpi, background = "transparent")
    dev <- grDevices::dev.cur()
    on.exit({
      grDevices::dev.off(dev)
      if (cur > 1L) grDevices::dev.set(cur)
    }, add = TRUE)
    draw()
    return(cap(native = TRUE))
  }
  if (!capabilities("cairo")) stop("Rasterising needs 'ragg' or R built with Cairo.", call. = FALSE)
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f), add = TRUE)
  grDevices::png(f, width = wpx, height = hpx, res = dpi, bg = "transparent", type = "cairo")
  dev <- grDevices::dev.cur()
  tryCatch(draw(), finally = {
    grDevices::dev.off(dev)
    if (cur > 1L) grDevices::dev.set(cur)
  })
  png::readPNG(f, native = TRUE)
}

.fig_c_overlays <- function(lim, style, frame = FALSE, frame_colour = "frame", frame_width = NULL,
                            scale_bar = NULL, label = NULL, label_colour = "white", label_size = 5.5,
                            boxes = NULL, box_colour = "ink", box_width = 0.5, box_size = NULL,
                            data_lim = lim) {
  out <- list()
  if (!is.null(boxes)) out$boxes <- .fig_c_box_grobs(boxes, box_colour, box_width, style, box_size)
  if (isTRUE(frame)) {
    out$frame <- grid::rectGrob(gp = grid::gpar(fill = NA, col = .fig_colour(frame_colour, style),
                                                lwd = (if (is.null(frame_width)) style$line$frame else frame_width) / 0.75))
  }
  if (!is.null(scale_bar)) out$bar <- .fig_c_scale_bar(scale_bar, lim, style, data_lim)
  if (!is.null(label) && nzchar(label)) {
    out$label <- .fig_c_text_grob(label, grid::unit(0.02, "npc"), grid::unit(0.98, "npc"), size = label_size,
                                  colour = .fig_colour(label_colour, style), hjust = 0, vjust = 1, style = style)
  }
  out
}

.fig_c_scale_bar <- function(sb, lim, style, data_lim = lim) {
  g <- function(name, default) if (is.null(sb[[name]])) default else sb[[name]]
  if (identical(sb$relative_to, "data")) lim <- data_lim
  span <- diff(lim[1:2])
  len <- g("length", 50)
  x0 <- lim[1] + g("x", 0.05) * span
  yb <- lim[4] - g("y", 0.06) * span
  lo <- g("label_offset", if (g("y", 0.06) < 0) -0.015 else 0.025)
  col <- .fig_colour(g("colour", "ink"), style)
  bar <- grid::segmentsGrob(x0, -yb, x0 + len, -yb, default.units = "native",
                            gp = grid::gpar(col = col, lwd = g("linewidth", 1.6) / 0.75, lineend = "butt"))
  lab <- g("label", paste(len, "um"))
  txt <- .fig_c_text_grob(lab, grid::unit(x0 + len / 2, "native"), grid::unit(-(yb - lo * span), "native"),
                          size = g("size", 5), colour = col, hjust = 0.5, vjust = if (lo >= 0) 0 else 1,
                          style = style)
  grid::gTree(children = grid::gList(bar, txt))
}

.fig_c_box_grobs <- function(boxes, colour, width, style, size = NULL) {
  b <- if (is.data.frame(boxes)) boxes else as.data.frame(do.call(rbind, lapply(boxes, as.data.frame)))
  if (is.null(b$size)) b$size <- size
  if (is.null(b$size)) stop("boxes need a size.", call. = FALSE)
  cols <- if (!is.null(b$colour)) .fig_colour(as.character(b$colour), style) else rep(.fig_colour(colour, style), nrow(b))
  lw <- if (!is.null(b$width)) b$width else rep(width, nrow(b))
  grid::rectGrob(b$x, -b$y, width = b$size, height = b$size, default.units = "native",
                 gp = grid::gpar(fill = NA, col = unname(cols), lwd = lw / 0.75, linejoin = "mitre"))
}

.fig_c_titles <- function(title, subtitle, title_colour, labels, label_id, key, title_column,
                          subtitle_column, group_column, group_colours, style, groups = NULL) {
  colour <- .fig_colour(title_colour, style)
  if (!is.null(labels) && !is.null(label_id)) {
    r <- labels[as.character(labels[[key]]) == as.character(label_id), , drop = FALSE]
    if (nrow(r) != 1L) stop("labels must have one row for ", label_id, ".", call. = FALSE)
    if (is.null(title) && !is.null(r[[title_column]])) title <- as.character(r[[title_column]])
    if (is.null(subtitle) && !is.null(r[[subtitle_column]])) subtitle <- as.character(r[[subtitle_column]])
    g <- if (is.null(groups)) r else groups[as.character(groups[[key]]) == as.character(label_id), , drop = FALSE]
    if (!is.null(group_colours) && !is.null(g[[group_column]]) && nrow(g) >= 1L) {
      colour <- unname(.fig_colour(group_colours, style)[as.character(g[[group_column]][1])])
    }
  }
  list(title = title, subtitle = subtitle, colour = colour)
}

# Title at axes fraction (0, 1.025) in bold; subtitle after it (offset as
# len(title) * size * 0.7 + 4 points, the spacing of common figure code).
.fig_c_title_grobs <- function(title, subtitle, colour, size, style, align = "left") {
  out <- list()
  if (identical(align, "centre")) {
    if (!is.null(title) && nzchar(title)) {
      out$title <- .fig_c_text_grob(title, grid::unit(0.5, "npc"), grid::unit(1, "npc") + grid::unit(2, "bigpts"),
                                    size = size, colour = colour, hjust = 0.5, vjust = 0, style = style)
    }
    return(out)
  }
  y <- grid::unit(1.025, "npc")
  if (!is.null(title) && nzchar(title)) {
    out$title <- .fig_c_text_grob(title, grid::unit(0, "npc"), y, size = size, colour = colour,
                                  hjust = 0, vjust = 0, bold = TRUE, style = style)
  }
  if (!is.null(subtitle) && nzchar(subtitle)) {
    dx <- if (is.null(title)) 0 else nchar(title) * size * 0.7 + 4
    out$subtitle <- .fig_c_text_grob(subtitle, grid::unit(dx, "bigpts"), y, size = size - 1,
                                     colour = style$colour$muted, hjust = 0, vjust = 0, style = style)
  }
  out
}

.fig_c_text_grob <- function(label, x, y, size, colour, hjust = 0, vjust = 1, bold = FALSE, rot = 0,
                             style, lineheight = 1.1) {
  # Built when drawn, so that rich text is measured on the output device.
  grid::gTree(label = label, x = x, y = y, size = size, colour = colour, hjust = hjust, vjust = vjust,
              bold = bold, rot = rot, style = style, lineheight = lineheight, cl = "phenoscapR_lazytext")
}

#' @export
makeContent.phenoscapR_lazytext <- function(x) {
  grid::setChildren(x, grid::gList(.fig_c_text_now(x$label, x$x, x$y, x$size, x$colour, x$hjust, x$vjust,
                                                   x$bold, x$rot, x$style, x$lineheight)))
}

.fig_c_text_now <- function(label, x, y, size, colour, hjust, vjust, bold, rot, style, lineheight) {
  if (.fig_has_rich_text()) {
    text <- TypesetLabel(label, rich = TRUE)
    if (bold) text <- gsub("<sub>reg</sub>", "<sub>**reg**</sub>", paste0("**", text, "**"), fixed = TRUE)
    gridtext::richtext_grob(text, x = x, y = y, hjust = hjust, vjust = vjust, rot = rot,
                            gp = grid::gpar(fontsize = size, col = colour, fontfamily = style$family,
                                            lineheight = lineheight),
                            padding = grid::unit(0, "pt"), margin = grid::unit(0, "pt"))
  } else {
    grid::textGrob(TypesetLabel(label, rich = FALSE), x = x, y = y, hjust = hjust, vjust = vjust, rot = rot,
                   gp = grid::gpar(fontsize = size, col = colour, fontfamily = style$family,
                                   fontface = if (bold) "bold" else "plain", lineheight = lineheight))
  }
}

.fig_c_mark_text <- function(spec, marks, index) {
  if (is.null(spec)) return(NULL)
  if (is.character(spec)) return(spec)
  m <- if (!is.null(index)) marks[unlist(index), , drop = FALSE] else marks
  sprintf(spec$format, m[[spec$column]][1])
}

# Arrow from cell + tail offset to cell + tip offset, shortened by `shrink`
# points at both ends, closed head of length 0.4 and half-width 0.2 head units.
.fig_c_arrow_grobs <- function(m, a, style) {
  g <- function(name, default) if (is.null(a[[name]])) default else a[[name]]
  tip <- g("tip", -3.5)
  tail <- g("tail", -15)
  head <- g("head", 6)
  shrink <- g("shrink", 2)
  col <- .fig_colour(g("colour", "white"), style)
  lw <- g("linewidth", 0.9)
  kids <- lapply(seq_len(nrow(m)), function(i) {
    grid::gTree(x0 = m$x[i] + tail, y0 = m$y[i] + tail, x1 = m$x[i] + tip, y1 = m$y[i] + tip,
                head = head, shrink = shrink, col = col, lw = lw, cl = "phenoscapR_arrow")
  })
  grid::gTree(children = do.call(grid::gList, kids))
}

#' @export
makeContent.phenoscapR_arrow <- function(x) {
  p0 <- c(grid::convertX(grid::unit(x$x0, "native"), "bigpts", TRUE),
          grid::convertY(grid::unit(-x$y0, "native"), "bigpts", TRUE))
  p1 <- c(grid::convertX(grid::unit(x$x1, "native"), "bigpts", TRUE),
          grid::convertY(grid::unit(-x$y1, "native"), "bigpts", TRUE))
  v <- p1 - p0
  len <- sqrt(sum(v^2))
  if (len <= 2 * x$shrink) return(grid::setChildren(x, grid::gList()))
  u <- v / len
  a <- p0 + u * x$shrink
  b <- p1 - u * x$shrink
  hl <- 0.4 * x$head
  hw <- 0.2 * x$head
  base <- b - u * hl
  nrm <- c(-u[2], u[1])
  shaft <- grid::segmentsGrob(a[1], a[2], base[1], base[2], default.units = "bigpts",
                              gp = grid::gpar(col = x$col, lwd = x$lw / 0.75, lineend = "butt"))
  tri <- grid::polygonGrob(c(b[1], base[1] + nrm[1] * hw, base[1] - nrm[1] * hw),
                           c(b[2], base[2] + nrm[2] * hw, base[2] - nrm[2] * hw), default.units = "bigpts",
                           gp = grid::gpar(col = x$col, fill = x$col, lwd = x$lw / 0.75, linejoin = "mitre"))
  grid::setChildren(x, grid::gList(shaft, tri))
}

.fig_c_cross_grob <- function(x, y, cross, style) {
  g <- function(name, default) if (is.null(cross[[name]])) default else cross[[name]]
  h <- sqrt(g("size", 14)) / 2
  col <- .fig_colour(g("colour", "#FFD54F"), style)
  lw <- g("linewidth", 0.7) / 0.75
  kids <- lapply(seq_along(x), function(i) {
    cx <- grid::unit(x[i], "native")
    cy <- grid::unit(-y[i], "native")
    d <- grid::unit(h, "bigpts")
    grid::segmentsGrob(grid::unit.c(cx - d, cx - d), grid::unit.c(cy - d, cy + d),
                       grid::unit.c(cx + d, cx + d), grid::unit.c(cy + d, cy - d),
                       gp = grid::gpar(col = col, lwd = lw, lineend = "butt"))
  })
  grid::gTree(children = do.call(grid::gList, kids))
}

.fig_c_tile_marks <- function(cross, style) {
  if (is.null(cross)) return(list())
  d <- grid::unit((if (is.null(cross$size)) 3.5 else cross$size) / 2, "bigpts")
  col <- .fig_colour(if (is.null(cross$colour)) "#FFD54F" else cross$colour, style)
  lw <- (if (is.null(cross$linewidth)) 0.5 else cross$linewidth) / 0.75
  c0 <- grid::unit(0.5, "npc")
  list(grid::segmentsGrob(grid::unit.c(c0 - d, c0), grid::unit.c(c0, c0 - d), grid::unit.c(c0 + d, c0),
                          grid::unit.c(c0, c0 + d), gp = grid::gpar(col = col, lwd = lw, lineend = "butt")))
}

.fig_c_gallery_grob <- function(data, row, row_levels, tile_mm, view_gap_mm, field_gap_mm, row_pitch_mm,
                                column_labels, header_size, header_colour, header_gap_mm, row_labels,
                                cross, corner, scale_bar, interpolate, style, title = NULL, total = NULL,
                                title_size = 5.6, title_gap_mm = 4.5) {
  info <- data$info
  views <- unique(info$view)
  nv <- length(views)
  fields <- unique(info$field)
  frow <- info[!duplicated(info$field), , drop = FALSE]
  key <- if (is.null(row)) as.character(frow$field) else as.character(frow[[row]])
  lv <- if (!is.null(row_levels)) as.character(unlist(row_levels)) else unique(key)
  r_of <- match(key, lv)
  if (!is.null(row_levels) && anyNA(r_of)) {
    keep_f <- frow$field[!is.na(r_of)]
    info <- info[info$field %in% keep_f, , drop = FALSE]
    frow <- frow[!is.na(r_of), , drop = FALSE]
    key <- key[!is.na(r_of)]
    r_of <- r_of[!is.na(r_of)]
  }
  c_of <- stats::ave(seq_along(key), r_of, FUN = seq_along)
  field_w <- nv * tile_mm + (nv - 1) * view_gap_mm
  mm <- function(v) grid::unit(v, "mm")
  kids <- list()
  for (k in seq_len(nrow(info))) {
    f <- match(info$field[k], frow$field)
    v <- match(info$view[k], views)
    left <- (c_of[f] - 1) * (field_w + field_gap_mm) + (v - 1) * (tile_mm + view_gap_mm)
    top <- (r_of[f] - 1) * row_pitch_mm
    img <- data$images[[info$image[k]]]
    tile <- list(grid::rasterGrob(img, width = grid::unit(1, "npc"), height = grid::unit(1, "npc"),
                                  interpolate = interpolate))
    tile <- c(tile, .fig_c_tile_marks(cross, style))
    if (!is.null(corner) && identical(info$view[k], corner$view)) {
      tile <- c(tile, list(.fig_c_text_grob(as.character(info[[corner$column]][k]), grid::unit(0.04, "npc"),
                                            grid::unit(0.96, "npc"),
                                            size = if (is.null(corner$size)) 3.6 else corner$size,
                                            colour = .fig_colour(if (is.null(corner$colour)) "white" else corner$colour, style),
                                            hjust = 0, vjust = 1, style = style)))
    }
    if (!is.null(scale_bar) && identical(info$view[k], scale_bar$view) && c_of[f] == 1L &&
        (identical(scale_bar$which, "row") || r_of[f] == 1L)) {
      n <- ncol(img)
      px <- scale_bar$length / scale_bar$pixel_size
      tile <- c(tile, list(grid::segmentsGrob(0.08, 0.1, 0.08 + px / n, 0.1,
                                              gp = grid::gpar(col = .fig_colour(if (is.null(scale_bar$colour)) "white" else scale_bar$colour, style),
                                                              lwd = (if (is.null(scale_bar$linewidth)) 1.2 else scale_bar$linewidth) / 0.75,
                                                              lineend = "butt"))))
    }
    kids[[length(kids) + 1L]] <- grid::gTree(
      children = do.call(grid::gList, tile),
      vp = grid::viewport(x = mm(left), y = grid::unit(1, "npc") - mm(top), width = mm(tile_mm),
                          height = mm(tile_mm), just = c(0, 1)))
  }
  if (!is.null(column_labels)) {
    labs <- unlist(column_labels)
    ncols <- max(c_of)
    for (cc in seq_len(ncols)) for (v in seq_len(nv)) {
      left <- (cc - 1) * (field_w + field_gap_mm) + (v - 1) * (tile_mm + view_gap_mm) + tile_mm / 2
      kids[[length(kids) + 1L]] <- .fig_c_text_grob(labs[v], mm(left), grid::unit(1, "npc") + mm(header_gap_mm),
                                                    size = header_size, colour = .fig_colour(header_colour, style),
                                                    hjust = 0.5, vjust = 0, style = style)
    }
  }
  for (spec in row_labels) {
    for (r in seq_along(lv)) {
      f <- which(r_of == r)[1]
      if (is.na(f)) next
      val <- if (!is.null(spec$map)) {
        unlist(spec$map)[[lv[r]]]
      } else {
        as.character(frow[[spec$column]][f])
      }
      if (!is.null(spec$replace)) for (p in names(spec$replace)) val <- gsub(p, spec$replace[[p]], val, fixed = TRUE)
      top <- (r - 1) * row_pitch_mm + tile_mm * (1 - (if (is.null(spec$dy)) 0.5 else spec$dy))
      kids[[length(kids) + 1L]] <- .fig_c_text_grob(
        val, mm(if (is.null(spec$x_mm)) -1 else spec$x_mm), grid::unit(1, "npc") - mm(top),
        size = if (is.null(spec$size)) 5 else spec$size,
        colour = .fig_colour(if (is.null(spec$colour)) "ink" else spec$colour, style),
        hjust = if (is.null(spec$hjust)) 0 else spec$hjust, vjust = 0.5, bold = isTRUE(spec$bold), style = style)
    }
  }
  if (!is.null(title)) {
    title <- gsub("{n}", nrow(frow), title, fixed = TRUE)
    if (!is.null(total)) title <- gsub("{total}", nrow(total), title, fixed = TRUE)
    kids[[length(kids) + 1L]] <- .fig_c_text_grob(title, mm(0), grid::unit(1, "npc") + mm(title_gap_mm),
                                                  size = title_size, colour = style$colour$ink, hjust = 0,
                                                  vjust = 0, bold = TRUE, style = style)
  }
  grid::gTree(children = do.call(grid::gList, kids), cl = "phenoscapR_gallery_grob")
}

.fig_c_shapes_grob <- function(data, style) {
  s <- data$shapes
  col <- function(v) ifelse(is.na(v), NA, vapply(v, function(z) if (is.na(z)) NA_character_ else .fig_colour(z, style), character(1)))
  kids <- list()
  for (i in seq_len(nrow(s))) {
    r <- s[i, ]
    gp <- grid::gpar(fill = col(r$fill), col = col(r$colour), lwd = r$linewidth / 0.75)
    nat <- function(v) grid::unit(v, "native")
    g <- switch(r$type,
      rect = grid::rectGrob(nat(r$x), nat(r$y), nat(r$w), nat(r$h), gp = gp),
      roundrect = grid::roundrectGrob(nat(r$x), nat(r$y), nat(r$w), nat(r$h),
                                      r = grid::unit(r$r, "mm"), just = "centre", gp = gp),
      circle = grid::circleGrob(nat(r$x), nat(r$y), nat(r$r), gp = gp),
      ellipse = {
        t <- seq(0, 2 * pi, length.out = 181)
        a <- r$angle * pi / 180
        ex <- r$w / 2 * cos(t)
        ey <- r$h / 2 * sin(t)
        grid::polygonGrob(nat(r$x + ex * cos(a) - ey * sin(a)), nat(r$y + ex * sin(a) + ey * cos(a)), gp = gp)
      },
      segment = grid::segmentsGrob(nat(r$x), nat(r$y), nat(r$xend), nat(r$yend), gp = gp),
      arrow = grid::gTree(x0 = r$x, y0 = -r$y, x1 = r$xend, y1 = -r$yend, head = r$head, shrink = 2,
                          col = col(r$colour), lw = r$linewidth, cl = "phenoscapR_arrow"),
      text = .fig_c_text_grob(r$label, nat(r$x), nat(r$y), size = r$size,
                              colour = if (is.na(r$colour)) style$colour$ink else col(r$colour),
                              hjust = r$hjust, vjust = r$vjust, style = style, lineheight = r$lineheight),
      stop("Unknown shape type '", r$type, "'.", call. = FALSE))
    kids[[length(kids) + 1L]] <- g
  }
  xl <- data$xlim
  yl <- data$ylim
  if (isFALSE(data$equal)) {
    vp <- grid::viewport(xscale = xl, yscale = yl, clip = "off")
    return(grid::gTree(children = do.call(grid::gList, kids), vp = vp, cl = "phenoscapR_shapes_grob"))
  }
  lay <- grid::viewport(layout = grid::grid.layout(1, 1, widths = grid::unit(diff(xl), "null"),
                                                   heights = grid::unit(diff(yl), "null"), respect = TRUE))
  vp <- grid::viewport(layout.pos.row = 1, layout.pos.col = 1, xscale = xl, yscale = yl, clip = "off")
  grid::gTree(children = do.call(grid::gList, kids), vp = grid::vpStack(lay, vp), cl = "phenoscapR_shapes_grob")
}
