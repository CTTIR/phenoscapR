# Plot-data builders for cell maps, territory maps and image fields. They
# turn per-cell arrays and tables into the inputs of PlotCellMap(),
# PlotTerritories(), PlotFluorescenceField() and PlotImage(). Coordinates are
# in physical units (for example micrometres) with y increasing downwards,
# as in image coordinates.

#' Distance to the Nearest Cell of Given Labels
#'
#' Adds the Euclidean distance from every cell to the nearest cell whose
#' label is in `labels` (exact nearest-neighbour search). Cells carrying one
#' of these labels get `self` (0 by default) instead of the distance to
#' another such cell.
#'
#' @param cells Data frame of cells.
#' @param labels Labels of the target cells.
#' @param column Name of the new column.
#' @param x,y,label Column names.
#' @param self Value for target cells; `NULL` keeps the distance to the
#'   nearest other target cell.
#' @return `cells` with the new column.
#' @examples
#' d <- data.frame(x = c(0, 3, 10), y = 0, label = c("t", "a", "a"))
#' NearestLabelDistance(d, "t", column = "dist")
#' @export
NearestLabelDistance <- function(cells, labels, column = "distance", x = "x", y = "y",
                                 label = "label", self = 0) {
  .fig_require_columns(cells, c(x, y, label), "cells")
  xy <- cbind(as.numeric(cells[[x]]), as.numeric(cells[[y]]))
  target <- as.character(cells[[label]]) %in% unlist(labels)
  d <- rep(NA_real_, nrow(cells))
  if (any(target)) {
    if (is.null(self)) {
      nn <- dbscan::kNN(xy[target, , drop = FALSE], k = 1L, query = xy[!target, , drop = FALSE])
      d[!target] <- nn$dist[, 1L]
      if (sum(target) > 1L) d[target] <- dbscan::kNN(xy[target, , drop = FALSE], k = 1L)$dist[, 1L]
    } else {
      if (any(!target)) {
        d[!target] <- dbscan::kNN(xy[target, , drop = FALSE], k = 1L,
                                  query = xy[!target, , drop = FALSE])$dist[, 1L]
      }
      d[target] <- self
    }
  }
  cells[[column]] <- d
  cells
}

#' Cells of a Map Field or Whole Section
#'
#' Prepares the input of [PlotCellMap()]: the cells inside a square field
#' (or all cells for a whole-section map), the field geometry and, when
#' requested, the interface zone, i.e. the points of a regular grid that lie
#' within `radius` of a reference cell type (for example the tumour-stroma
#' interface within 20 micrometres of a tumour cell).
#'
#' The field centre is given directly, taken from a cell (`centre_cell`, the
#' value of column `id`), taken from the first row of a data frame with
#' columns `x` and `y`, snapped to a regular grid anchored at the minimum
#' cell coordinates (`grid`), and finally shifted by `offset`.
#'
#' @param cells Data frame of cells (positions, label and further columns).
#' @param centre Optional `c(x, y)` or a data frame with columns `x`, `y`.
#' @param size Optional field width; `NULL` for a whole-section map.
#' @param centre_cell Optional cell identifier giving the centre.
#' @param id Column holding cell identifiers for `centre_cell`.
#' @param grid Optional list with `step` and `offset`: the centre is moved
#'   to the nearest `min(coordinate) + offset + k * step`.
#' @param offset Optional shift `c(dx, dy)` added to the centre.
#' @param interface Optional list with `labels` (reference cell labels),
#'   `radius` and `step` (grid spacing).
#' @param classes Optional list with `column`, `map` (named list of value to
#'   class) and `to` (new column name; default `"class"`); unmapped values
#'   become `default` (default `NA`).
#' @param margin Extra width kept around the field (cells drawn partly
#'   inside).
#' @param x,y,label Column names.
#' @return A list of class `phenoscapR_cellmap` with `cells`, `interface`
#'   (data frame of grid points in the zone, or `NULL`), `centre`, `size`,
#'   `step` and `extent` (`c(xmin, xmax, ymin, ymax)`).
#' @examples
#' set.seed(1)
#' d <- data.frame(x = runif(200, 0, 100), y = runif(200, 0, 100),
#'                 label = sample(c("t", "a"), 200, TRUE))
#' m <- CellMapData(d, centre = c(50, 50), size = 40,
#'                  interface = list(labels = "t", radius = 5, step = 2))
#' nrow(m$cells)
#' @export
CellMapData <- function(cells, centre = NULL, size = NULL, centre_cell = NULL, id = "row",
                        grid = NULL, offset = NULL, interface = NULL, classes = NULL, margin = 0,
                        x = "x", y = "y", label = "label") {
  .fig_require_columns(cells, c(x, y, label), "cells")
  cells <- as.data.frame(cells, check.names = FALSE)
  cells$x <- as.numeric(cells[[x]])
  cells$y <- as.numeric(cells[[y]])
  cells$label <- as.character(cells[[label]])
  if (!is.null(classes)) {
    col <- if (is.null(classes$column)) "label" else classes$column
    map <- unlist(classes$map)
    to <- if (is.null(classes$to)) "class" else classes$to
    v <- unname(map[as.character(cells[[col]])])
    if (!is.null(classes$default)) v[is.na(v)] <- classes$default
    cells[[to]] <- v
  }
  centre <- .fig_c_centre(cells, centre, centre_cell, id, grid, offset)
  if (is.null(size)) {
    extent <- c(range(cells$x), range(cells$y))
    keep <- rep(TRUE, nrow(cells))
  } else {
    half <- size / 2
    extent <- c(centre[1] - half, centre[1] + half, centre[2] - half, centre[2] + half)
    keep <- abs(cells$x - centre[1]) < half + margin & abs(cells$y - centre[2]) < half + margin
  }
  zone <- NULL
  if (!is.null(interface)) {
    if (is.null(size)) stop("An interface zone needs a field size.", call. = FALSE)
    step <- if (is.null(interface$step)) 2 else interface$step
    radius <- if (is.null(interface$radius)) 20 else interface$radius
    g <- seq(-size / 2, size / 2 + step / 2, by = step)
    pts <- expand.grid(gx = centre[1] + g, gy = centre[2] + g)
    ref <- cells$label %in% unlist(interface$labels)
    if (any(ref)) {
      d <- dbscan::kNN(cbind(cells$x[ref], cells$y[ref]), k = 1L, query = cbind(pts$gx, pts$gy))$dist[, 1L]
      zone <- data.frame(x = pts$gx[d <= radius], y = pts$gy[d <= radius])
    } else {
      zone <- data.frame(x = numeric(0), y = numeric(0))
    }
    attr(zone, "step") <- step
  }
  structure(list(cells = cells[keep, , drop = FALSE], interface = zone, centre = centre,
                 size = size, extent = extent),
            class = "phenoscapR_cellmap")
}

#' Centre of the Densest Grid Window
#'
#' Bins cells into square windows of a regular grid with origin 0 and
#' returns the centre of the window holding the most cells (ties: the window
#' with the smallest x index, then y index).
#'
#' @param cells Data frame of cells.
#' @param size Window width.
#' @param filter Optional named list: column to values; only matching cells
#'   are counted. Use `NA` among the values to count missing values.
#' @param x,y Column names.
#' @return A one-row data frame with `x`, `y` (window centre), `x0`, `y0`
#'   (window corner) and `n`.
#' @examples
#' d <- data.frame(x = c(1, 2, 15, 16, 17), y = c(1, 2, 5, 6, 7))
#' DensestGridWindow(d, 10)
#' @export
DensestGridWindow <- function(cells, size, filter = list(), x = "x", y = "y") {
  .fig_require_columns(cells, c(x, y, names(filter)), "cells")
  keep <- .fig_c_filter(cells, filter)
  kx <- floor(as.numeric(cells[[x]][keep]) / size)
  ky <- floor(as.numeric(cells[[y]][keep]) / size)
  tab <- stats::aggregate(list(n = rep(1L, length(kx))), list(kx = kx, ky = ky), length)
  tab <- tab[order(-tab$n, tab$kx, tab$ky), , drop = FALSE]
  data.frame(x = (tab$kx[1] + 0.5) * size, y = (tab$ky[1] + 0.5) * size, x0 = tab$kx[1] * size,
             y0 = tab$ky[1] * size, n = tab$n[1])
}

#' Cells Paired with Their Nearest Partner Cell
#'
#' For selected cells (by identifier) finds the nearest cell with a partner
#' label and returns both positions, their distance and the midpoint, the
#' input of close-up fields that show a cell next to its nearest neighbour
#' of another type.
#'
#' @param cells Data frame of cells.
#' @param ids Identifiers (values of `id`) of the focus cells, in output
#'   order.
#' @param partner Labels of the partner cells.
#' @param id,x,y,label Column names.
#' @return A data frame with `id`, `x`, `y`, `partner_id`, `partner_x`,
#'   `partner_y`, `distance`, `mid_x` and `mid_y`.
#' @examples
#' d <- data.frame(row = 0:3, x = c(0, 4, 10, 30), y = 0, label = c("f", "p", "f", "p"))
#' NearestPartnerPairs(d, c(0, 2), "p")
#' @export
NearestPartnerPairs <- function(cells, ids, partner, id = "row", x = "x", y = "y", label = "label") {
  .fig_require_columns(cells, c(id, x, y, label), "cells")
  i <- match(as.character(unlist(ids)), as.character(cells[[id]]))
  if (anyNA(i)) stop("Unknown cell identifier(s): ", paste(unlist(ids)[is.na(i)], collapse = ", "), call. = FALSE)
  p <- which(as.character(cells[[label]]) %in% unlist(partner))
  if (!length(p)) stop("No partner cells.", call. = FALSE)
  xy <- cbind(as.numeric(cells[[x]]), as.numeric(cells[[y]]))
  nn <- dbscan::kNN(xy[p, , drop = FALSE], k = 1L, query = xy[i, , drop = FALSE])
  j <- p[nn$id[, 1L]]
  data.frame(id = cells[[id]][i], x = xy[i, 1], y = xy[i, 2], partner_id = cells[[id]][j],
             partner_x = xy[j, 1], partner_y = xy[j, 2], distance = nn$dist[, 1L],
             mid_x = (xy[i, 1] + xy[j, 1]) / 2, mid_y = (xy[i, 2] + xy[j, 2]) / 2)
}

#' Cells of One Type inside a Field, Ranked
#'
#' Selects cells with given labels inside a square of half-width `half`
#' around a centre, ordered by a column (for example the distance to the
#' nearest tumour cell), and keeps the first `n`; used to place arrows on a
#' fluorescence field.
#'
#' @param cells Data frame of cells.
#' @param centre `c(x, y)` or a data frame with `x`, `y`.
#' @param half Half-width of the square.
#' @param labels Labels of the cells to select.
#' @param order_by Optional column to sort by (ascending).
#' @param n Maximum number of cells.
#' @param x,y,label Column names.
#' @return The selected rows of `cells`.
#' @export
FieldCellsRanked <- function(cells, centre, half, labels, order_by = NULL, n = Inf,
                             x = "x", y = "y", label = "label") {
  .fig_require_columns(cells, c(x, y, label, order_by), "cells")
  centre <- .fig_c_centre(cells, centre, NULL, NULL, NULL, NULL)
  inside <- abs(cells[[x]] - centre[1]) < half & abs(cells[[y]] - centre[2]) < half &
    as.character(cells[[label]]) %in% unlist(labels)
  out <- cells[inside, , drop = FALSE]
  if (!is.null(order_by)) out <- out[order(out[[order_by]], method = "radix"), , drop = FALSE]
  out <- utils::head(out, n)
  rownames(out) <- NULL
  out
}

#' Voronoi Territory Tiles of the Cells in a Field
#'
#' Computes the Voronoi tessellation of the cells around a square field and
#' caps every territory at `cap` from its cell by moving the polygon
#' vertices that lie further away onto that radius; cells on the outer hull
#' (unbounded territories) get a regular 12-gon of radius `0.7 * cap`. Each
#' tile carries a class from `classes` (first matching entry), and tiles are
#' ordered for drawing by `order` (classes listed first are drawn first,
#' all others afterwards; ties keep cell order). Requires 'deldir'.
#'
#' @param cells Data frame of cells.
#' @param centre `c(x, y)`, a data frame with `x`, `y`, or `NULL` with
#'   `centre_cell`.
#' @param size Field width.
#' @param cap Maximum territory radius.
#' @param margin Neighbourhood kept around the field for the tessellation.
#' @param classes Named list: class name to labels; unmatched cells get
#'   `default`.
#' @param default Class of unmatched cells.
#' @param order Classes drawn first, in this order.
#' @param centre_cell,id,offset As in [CellMapData()].
#' @param x,y,label Column names.
#' @return A list of class `phenoscapR_territories` with `tiles` (data frame
#'   with `tile`, `x`, `y`, `class`), `centre`, `size` and `extent`.
#' @examples
#' if (requireNamespace("deldir", quietly = TRUE)) {
#'   set.seed(2)
#'   d <- data.frame(x = runif(300, 0, 100), y = runif(300, 0, 100),
#'                   label = sample(c("t", "a"), 300, TRUE))
#'   tt <- TerritoryTiles(d, c(50, 50), 40, cap = 5, classes = list(tumour = "t"))
#'   head(tt$tiles)
#' }
#' @export
TerritoryTiles <- function(cells, centre = NULL, size, cap = 11, margin = 30, classes = list(),
                           default = "other", order = c("other", "tumour"), centre_cell = NULL,
                           id = "row", offset = NULL, x = "x", y = "y", label = "label") {
  if (!requireNamespace("deldir", quietly = TRUE)) stop("TerritoryTiles() needs 'deldir'.", call. = FALSE)
  .fig_require_columns(cells, c(x, y, label), "cells")
  cells <- as.data.frame(cells, check.names = FALSE)
  cells$x <- as.numeric(cells[[x]])
  cells$y <- as.numeric(cells[[y]])
  centre <- .fig_c_centre(cells, centre, centre_cell, id, NULL, offset)
  half <- size / 2
  near <- which(abs(cells$x - centre[1]) < half + margin & abs(cells$y - centre[2]) < half + margin)
  px <- cells$x[near]
  py <- cells$y[near]
  lab <- as.character(cells[[label]][near])
  kind <- rep(default, length(near))
  for (cl in rev(names(classes))) kind[lab %in% unlist(classes[[cl]])] <- cl
  span <- max(diff(range(px)), diff(range(py)), 1)
  rw <- c(min(px) - 10 * span, max(px) + 10 * span, min(py) - 10 * span, max(py) + 10 * span)
  tess <- deldir::deldir(px, py, rw = rw, round = FALSE)
  tl <- deldir::tile.list(tess)
  theta <- seq(0, 2 * pi, length.out = 13)[-13]
  inside <- abs(px - centre[1]) <= half + cap & abs(py - centre[2]) <= half + cap
  polys <- vector("list", length(tl))
  for (k in seq_along(tl)) {
    t <- tl[[k]]
    i <- t$ptNum
    if (!inside[i]) next
    if (any(t$bp)) {
      vx <- px[i] + cap * 0.7 * cos(theta)
      vy <- py[i] + cap * 0.7 * sin(theta)
    } else {
      dx <- t$x - px[i]
      dy <- t$y - py[i]
      f <- pmin(1, cap / pmax(sqrt(dx * dx + dy * dy), 1e-9))
      vx <- px[i] + dx * f
      vy <- py[i] + dy * f
    }
    polys[[k]] <- data.frame(point = i, x = vx, y = vy)
  }
  polys <- polys[!vapply(polys, is.null, logical(1))]
  pts <- vapply(polys, function(p) p$point[1], integer(1))
  rank <- match(kind[pts], order)
  rank[is.na(rank)] <- length(order) + 1L
  o <- order(rank, pts, method = "radix")
  tiles <- do.call(rbind, lapply(seq_along(o), function(j) {
    p <- polys[[o[j]]]
    data.frame(tile = j, x = p$x, y = p$y, class = kind[p$point[1]], stringsAsFactors = FALSE)
  }))
  structure(list(tiles = tiles, centre = centre, size = size,
                 extent = c(centre[1] - half, centre[1] + half, centre[2] - half, centre[2] + half)),
            class = "phenoscapR_territories")
}

#' Sub-Window with the Most Cells of a Kind
#'
#' Scans square sub-windows of width `sub` on a grid of spacing `step`
#' inside a field and returns the one holding the most cells that match
#' `filter` (first maximum in row-major grid order, x varying fastest).
#'
#' @param cells Data frame of cells.
#' @param centre Field centre, `c(x, y)` or a data frame with `x`, `y`.
#' @param size Field width.
#' @param sub Sub-window width.
#' @param filter Named list: column to values.
#' @param ranges Named list: column to `c(min, max)` (inclusive) for numeric
#'   conditions, combined with `filter`.
#' @param step Grid spacing.
#' @param x,y Column names.
#' @return One-row data frame with `x`, `y`, `n`, `dx`, `dy` (offset from the
#'   field centre).
#' @export
BestSubWindow <- function(cells, centre, size, sub, filter = list(), ranges = list(), step = 10,
                          x = "x", y = "y") {
  .fig_require_columns(cells, c(x, y, names(filter), names(ranges)), "cells")
  centre <- .fig_c_centre(cells, centre, NULL, NULL, NULL, NULL)
  keep <- .fig_c_filter(cells, filter, ranges)
  px <- as.numeric(cells[[x]][keep])
  py <- as.numeric(cells[[y]][keep])
  hs <- sub / 2
  g <- seq(-size / 2 + hs, size / 2 - hs + 1e-9, by = step)
  best <- NULL
  for (gy in g) for (gx in g) {
    n <- sum(abs(px - (centre[1] + gx)) <= hs & abs(py - (centre[2] + gy)) <= hs)
    if (is.null(best) || n > best$n) best <- list(gx = gx, gy = gy, n = n)
  }
  data.frame(x = centre[1] + best$gx, y = centre[2] + best$gy, n = best$n, dx = best$gx, dy = best$gy)
}

#' Composite Fluorescence Images from Channel Fields
#'
#' Turns image fields (lists with a `channels` element of named matrices, as
#' returned by `segmantR::sg_read_field()`) into RGB images for galleries:
#' every view is an additive mixture of display-scaled channels,
#' `clip((value - lo) / (hi - lo), 0, 1) ^ gamma * weight * colour`.
#'
#' A layer is a list with `channel` (a channel name) or `column` (a column
#' of the field's `row` table that holds the channel name), `colour` (hex or
#' style colour), optional `weight` (default 1), `overlay` (paint over the
#' mixture instead of adding) and display levels: `lo` and `hi`. `lo` is the
#' name of a range table (`"slide"`, `"levels"`) or `"q0.01"` (a quantile of
#' the field's own values); `hi` is one or several terms, each a table name,
#' a table name with a factor (`"slide*0.9"`) or a quantile (`"q0.995"`);
#' the largest term is used, and never less than `lo + min_span`.
#'
#' @param fields List of fields (`channels`, and `row` with the field's table
#'   row for column lookups).
#' @param views Named list of views; each view is a list of layers.
#' @param slide,levels Optional data frames with columns `channel`, `lo`,
#'   `hi` and, when fields come from several images, `source`.
#' @param source Column of a field's `row` that matches `source` in the
#'   range tables.
#' @param gamma Display gamma.
#' @param min_span Minimum distance between the levels.
#' @param style A [ManuscriptStyle()] object (resolves colour names).
#' @return A list of class `phenoscapR_images` with `images` (list of RGB
#'   arrays) and `info` (data frame: `image`, `field`, `view` and the
#'   columns of each field's row).
#' @export
CompositeFields <- function(fields, views, slide = NULL, levels = NULL, source = "source",
                            gamma = 0.8, min_span = 1, style = ManuscriptStyle()) {
  if (inherits(fields, "sg_field") || (!is.null(fields$channels) && is.list(fields$channels))) {
    fields <- list(fields)
  }
  tables <- list(slide = slide, levels = levels)
  images <- list()
  info <- list()
  for (f in seq_along(fields)) {
    fld <- fields[[f]]
    row <- if (is.null(fld$row)) {
      data.frame(field_name = if (is.null(names(fields))) as.character(f) else names(fields)[f])
    } else {
      fld$row
    }
    for (v in names(views)) {
      images[[length(images) + 1L]] <- .fig_c_composite(fld, views[[v]], tables, row, source, gamma,
                                                       min_span, style)
      info[[length(info) + 1L]] <- cbind(data.frame(image = length(images), field = f, view = v,
                                                    stringsAsFactors = FALSE), row, row.names = NULL)
    }
  }
  structure(list(images = images, info = do.call(rbind, info)), class = "phenoscapR_images")
}

#' Schematic Shapes from a Specification
#'
#' Builds the shape table drawn by [PlotImage()] for a schematic: fixed
#' shapes (rectangles, rounded boxes, ellipses, circles, segments, arrows and
#' text) and, optionally, clouds of dots placed at random inside ellipses
#' (`seed` makes them reproducible).
#'
#' @param shapes List of shapes; each a list with `type` (`"rect"`,
#'   `"roundrect"`, `"ellipse"`, `"circle"`, `"segment"`, `"arrow"`,
#'   `"text"`), position fields (`x`, `y`, and `w`, `h`, `r`, `xend`,
#'   `yend`, `angle` as needed), `fill`, `colour`, `linewidth` (points),
#'   `label`, `size` (points), `hjust`, `vjust`, `z` (drawing order).
#' @param clouds List of dot clouds: `n`, `x`, `y` (ellipse centre), `rx`,
#'   `ry` (ellipse radii), `r` (dot radius), `fill`, optional `colour` and
#'   `linewidth` (outline), `z`.
#' @param flow Optional list describing a row of boxes joined by arrows:
#'   `labels`, `x0`, `width`, `gap`, `y`, `height`, `fill`, `colour`,
#'   `text_size`, `arrow_colour`.
#' @param values Optional data frame used to fill `{name}` placeholders in
#'   labels; see `fill`.
#' @param fill Named list: placeholder to a list with `column`, `fun`
#'   (`"sum"`, `"mean"`, `"median"`, `"n"`), `scale`, `format` (sprintf) and
#'   an optional `filter` (named list of column to values).
#' @param xlim,ylim Drawing limits.
#' @param seed Random seed for the clouds.
#' @param equal Keep equal x and y scales (centred in the panel box); with
#'   `FALSE` the limits fill the box.
#' @return A list of class `phenoscapR_shapes` with `shapes`, `xlim`, `ylim`
#'   and `equal`. Rounded-box radii (`r` of `"roundrect"`) are millimetres.
#' @export
SchematicShapes <- function(shapes = list(), clouds = list(), flow = NULL, values = NULL, fill = list(),
                            xlim = c(0, 1), ylim = c(0, 1), seed = 1, equal = TRUE) {
  rows <- lapply(shapes, .fig_c_shape_row)
  if (!is.null(flow)) {
    labels <- unlist(flow$labels)
    n <- length(labels)
    w <- flow$width
    for (i in seq_len(n)) {
      x0 <- flow$x0 + (i - 1) * (w + flow$gap)
      rows[[length(rows) + 1L]] <- .fig_c_shape_row(list(
        type = "roundrect", x = x0 + w / 2, y = flow$y, w = w, h = flow$height, fill = flow$fill,
        colour = flow$colour, linewidth = if (is.null(flow$linewidth)) 0.5 else flow$linewidth,
        r = if (is.null(flow$radius)) 0.05 else flow$radius, z = 1))
      rows[[length(rows) + 1L]] <- .fig_c_shape_row(list(
        type = "text", x = x0 + w / 2, y = flow$y, label = labels[i], size = flow$text_size,
        colour = if (is.null(flow$text_colour)) "ink" else flow$text_colour, z = 2,
        lineheight = if (is.null(flow$lineheight)) 1.15 else flow$lineheight))
      if (i < n) {
        rows[[length(rows) + 1L]] <- .fig_c_shape_row(list(
          type = "arrow", x = x0 + w + flow$arrow_gap[1], y = flow$y, xend = x0 + w + flow$gap + flow$arrow_gap[2],
          yend = flow$y, colour = flow$arrow_colour, linewidth = flow$arrow_linewidth,
          head = flow$arrow_head, z = 3))
      }
    }
  }
  if (length(clouds)) {
    old <- if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) get(".Random.seed", envir = globalenv())
    on.exit(if (!is.null(old)) assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    set.seed(seed)
    for (cl in clouds) {
      a <- stats::runif(cl$n, 0, 2 * pi)
      r <- sqrt(stats::runif(cl$n))
      for (k in seq_len(cl$n)) {
        rows[[length(rows) + 1L]] <- .fig_c_shape_row(list(
          type = "circle", x = cl$x + cl$rx * r[k] * cos(a[k]), y = cl$y + cl$ry * r[k] * sin(a[k]),
          r = cl$r, fill = cl$fill, colour = cl$colour, linewidth = if (is.null(cl$linewidth)) 0.5 else cl$linewidth,
          z = if (is.null(cl$z)) 1 else cl$z))
      }
    }
  }
  tab <- do.call(rbind, rows)
  if (length(fill) && !is.null(values)) {
    for (nm in names(fill)) {
      f <- fill[[nm]]
      sel <- if (is.null(f$filter)) rep(TRUE, nrow(values)) else .fig_c_filter(values, f$filter)
      v <- values[[f$column]][sel]
      if (!identical(f$fun, "n")) v <- as.numeric(v)
      val <- switch(if (is.null(f$fun)) "sum" else f$fun, sum = sum(v, na.rm = TRUE),
                    mean = mean(v, na.rm = TRUE), median = stats::median(v, na.rm = TRUE), n = length(v))
      val <- val * (if (is.null(f$scale)) 1 else f$scale)
      tab$label <- gsub(paste0("{", nm, "}"), sprintf(f$format, val), tab$label, fixed = TRUE)
    }
  }
  tab <- tab[order(tab$z, seq_len(nrow(tab)), method = "radix"), , drop = FALSE]
  rownames(tab) <- NULL
  structure(list(shapes = tab, xlim = unlist(xlim), ylim = unlist(ylim), equal = isTRUE(equal)),
            class = "phenoscapR_shapes")
}

# ---- internals ----------------------------------------------------------------

.fig_c_centre <- function(cells, centre, centre_cell, id, grid, offset) {
  if (!is.null(centre_cell)) {
    i <- match(as.character(centre_cell), as.character(cells[[id]]))
    if (is.na(i)) stop("Unknown centre cell ", centre_cell, ".", call. = FALSE)
    centre <- c(as.numeric(cells$x[i]), as.numeric(cells$y[i]))
  } else if (is.data.frame(centre)) {
    centre <- c(as.numeric(centre$x[1]), as.numeric(centre$y[1]))
  } else if (is.list(centre)) {
    centre <- as.numeric(unlist(centre))
  }
  if (is.null(centre)) {
    if (!is.null(grid) || !is.null(offset)) stop("A centre is needed for grid or offset.", call. = FALSE)
    return(NULL)
  }
  if (length(centre) != 2L || anyNA(centre)) stop("centre must be c(x, y).", call. = FALSE)
  if (!is.null(grid)) {
    o <- c(min(cells$x), min(cells$y)) + grid$offset
    centre <- o + round((centre - o) / grid$step) * grid$step
  }
  if (!is.null(offset)) centre <- centre + as.numeric(unlist(offset))
  centre
}

.fig_c_filter <- function(cells, filter, ranges = list()) {
  keep <- rep(TRUE, nrow(cells))
  for (col in names(ranges)) {
    r <- as.numeric(unlist(ranges[[col]]))
    v <- as.numeric(cells[[col]])
    keep <- keep & !is.na(v) & v >= r[1] & v <= r[2]
  }
  for (col in names(filter)) {
    vals <- unlist(filter[[col]])
    v <- cells[[col]]
    hit <- as.character(v) %in% as.character(vals[!is.na(vals)])
    if (anyNA(vals)) hit <- hit | is.na(v)
    keep <- keep & hit
  }
  keep
}

.fig_c_shape_row <- function(s) {
  g <- function(name, default) if (is.null(s[[name]])) default else s[[name]]
  data.frame(type = s$type, x = g("x", NA_real_), y = g("y", NA_real_), w = g("w", NA_real_),
             h = g("h", NA_real_), r = g("r", NA_real_), xend = g("xend", NA_real_),
             yend = g("yend", NA_real_), angle = g("angle", 0), fill = g("fill", NA_character_),
             colour = g("colour", NA_character_), linewidth = g("linewidth", 0.5),
             label = g("label", NA_character_), size = g("size", 5), hjust = g("hjust", 0.5),
             vjust = g("vjust", 0.5), head = g("head", 6), lineheight = g("lineheight", 1.15),
             z = g("z", 1), stringsAsFactors = FALSE)
}

# Resolve display levels of one layer for one image.
.fig_c_levels <- function(layer, img, tables, row, source, min_span) {
  lookup <- function(table, what) {
    tab <- tables[[table]]
    if (is.null(tab)) stop("No '", table, "' range table.", call. = FALSE)
    sel <- as.character(tab$channel) == layer$.channel
    if (!is.null(tab$source) && !is.null(row[[source]])) sel <- sel & as.character(tab$source) == as.character(row[[source]][1])
    if (sum(sel) != 1L) stop("Need one '", table, "' range for channel ", layer$.channel, ".", call. = FALSE)
    as.numeric(tab[[what]][sel])
  }
  term <- function(t, what) {
    if (grepl("^q[0-9.]+$", t)) return(stats::quantile(img, as.numeric(sub("^q", "", t)), names = FALSE, type = 7))
    parts <- strsplit(t, "*", fixed = TRUE)[[1L]]
    v <- lookup(parts[1], what)
    if (length(parts) == 2L) v <- v * as.numeric(parts[2])
    v
  }
  lo_spec <- if (is.null(layer$lo)) "slide" else layer$lo
  hi_spec <- if (is.null(layer$hi)) lo_spec else unlist(layer$hi)
  lo <- term(lo_spec, "lo")
  hi <- max(vapply(hi_spec, term, numeric(1), what = "hi"), lo + min_span)
  c(lo, hi)
}

.fig_c_rgb <- function(colour, style) {
  if (is.numeric(colour)) return(as.numeric(colour)[1:3])
  as.numeric(grDevices::col2rgb(.fig_colour(colour, style))) / 255
}

.fig_c_composite <- function(field, layers, tables, row, source, gamma, min_span, style) {
  ch <- field$channels
  first <- ch[[1L]]
  rgb <- array(0, c(nrow(first), ncol(first), 3L))
  on_top <- list()
  for (layer in layers) {
    name <- if (!is.null(layer$column)) as.character(row[[layer$column]][1]) else layer$channel
    if (is.null(ch[[name]])) stop("Field lacks channel '", name, "'.", call. = FALSE)
    layer$.channel <- name
    img <- ch[[name]]
    lv <- .fig_c_levels(layer, img, tables, row, source, min_span)
    f <- pmin(pmax((img - lv[1]) / (lv[2] - lv[1]), 0), 1)^gamma
    w <- if (is.null(layer$weight)) 1 else layer$weight
    col <- .fig_c_rgb(layer$colour, style)
    if (isTRUE(layer$overlay)) {
      on_top[[length(on_top) + 1L]] <- list(f = f * w, col = col)
      next
    }
    for (k in 1:3) rgb[, , k] <- rgb[, , k] + f * col[k] * w
  }
  rgb <- pmin(pmax(rgb, 0), 1)
  for (o in on_top) {
    f <- pmin(pmax(o$f, 0), 1)
    for (k in 1:3) rgb[, , k] <- rgb[, , k] * (1 - f) + o$col[k] * f
  }
  pmin(pmax(rgb, 0), 1)
}

#' Field Centre as Plot Data
#'
#' Resolves a field centre as in [CellMapData()] (given point, cell,
#' grid snapping, offset) and returns it as a one-row data frame, the form
#' taken by image readers, maps and boxes.
#'
#' @inheritParams CellMapData
#' @param size Optional field width stored in a `size` column.
#' @return A data frame with `x`, `y` and, when given, `size`.
#' @examples
#' d <- data.frame(row = 0:2, x = c(1, 5, 9), y = c(2, 6, 10), label = "a")
#' FieldCentre(d, centre_cell = 1, offset = c(10, 0), size = 20)
#' @export
FieldCentre <- function(cells, centre = NULL, centre_cell = NULL, id = "row", grid = NULL, offset = NULL,
                        size = NULL, x = "x", y = "y") {
  .fig_require_columns(cells, c(x, y, if (!is.null(centre_cell)) id), "cells")
  cells <- as.data.frame(cells, check.names = FALSE)
  cells$x <- as.numeric(cells[[x]])
  cells$y <- as.numeric(cells[[y]])
  ctr <- .fig_c_centre(cells, centre, centre_cell, id, grid, offset)
  if (is.null(ctr)) stop("No centre given.", call. = FALSE)
  out <- data.frame(x = ctr[1], y = ctr[2])
  if (!is.null(size)) out$size <- size
  out
}

#' Attach Cell Positions to a Table of Cell References
#'
#' Looks up cells referenced by image and row (as in review ledgers and
#' example lists) in per-image cell tables and adds their positions and
#' further columns.
#'
#' @param table Data frame with an image key column and a row column.
#' @param cells List of cell tables (with column `row`), one per image.
#' @param labels Image keys of `cells`, in list order (default the list
#'   names).
#' @param source,row Columns of `table` holding the image key and the cell
#'   row.
#' @param columns Columns copied from the cell tables.
#' @return `table` with the added columns.
#' @export
CellPositionsFor <- function(table, cells, labels = NULL, source = "sample_id", row = "row",
                             columns = c("x", "y", "label")) {
  .fig_require_columns(table, c(source, row), "table")
  keys <- if (!is.null(labels)) as.character(unlist(labels)) else names(cells)
  if (length(keys) != length(cells)) stop("labels must name every cell table.", call. = FALSE)
  out <- table
  for (cl in columns) out[[cl]] <- NA
  for (k in seq_along(cells)) {
    sel <- which(as.character(table[[source]]) == keys[k])
    if (!length(sel)) next
    ct <- cells[[k]]
    i <- match(as.numeric(table[[row]][sel]), as.numeric(ct$row))
    if (anyNA(i)) stop("Rows not found for ", keys[k], ".", call. = FALSE)
    for (cl in columns) out[[cl]][sel] <- ct[[cl]][i]
  }
  missing <- setdiff(unique(as.character(table[[source]])), keys)
  if (length(missing)) stop("No cell table for: ", paste(missing, collapse = ", "), call. = FALSE)
  out
}

