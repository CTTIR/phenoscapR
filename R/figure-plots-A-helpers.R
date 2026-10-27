# Internal helpers of the patient-level plot builders (series A): sizes in
# points, tick placement, text placed with offsets in points or panel
# fractions, and a theme with the tick and label distances of common figure
# code (tick labels 3.5 pt from the ticks, axis titles 4 pt from the labels).

# Point size for a filled circle without edge, from a scatter area s (pt^2)
# plus an edge drawn in the face colour of width lw (pt).
.figA_size_filled <- function(s, lw = 0) .fig_point(sqrt(s) + lw)

# Size and stroke of shape 21 whose outline path has diameter sqrt(s) pt and
# whose edge is lw pt wide.
.figA_size_edged <- function(s, lw) {
  stroke <- lw / (0.75 * ggplot2::.stroke / 2)
  size <- (sqrt(s) / 0.75 - stroke * ggplot2::.stroke / 2) / ggplot2::.pt
  list(size = max(size, 0.01), stroke = stroke)
}

# Diameter (pt) of a line marker of size ms with edge width mew.
.figA_size_marker <- function(ms, mew = 1) .fig_point(ms + mew)

.figA_col <- function(x, style) {
  if (is.null(x)) return(NULL)
  out <- .fig_colour(x, style)
  if (is.list(out)) out <- unlist(out)
  out
}

# Named colour lookup with a default.
.figA_lookup <- function(keys, colours, default, style) {
  colours <- .figA_col(colours, style)
  if (is.null(colours)) return(rep(default, length(keys)))
  if (is.null(names(colours))) return(rep_len(unname(colours), length(keys)))
  out <- unname(colours[as.character(keys)])
  out[is.na(out)] <- default
  out
}

# Tick locations of the automatic locator of common plotting code (maximum
# nbins intervals, steps 1, 2, 2.5, 5, 10), restricted to the limits.
.figA_breaks <- function(limits, nbins = 9, steps = c(1, 2, 2.5, 5, 10), min_n = 2) {
  lo <- limits[1]
  hi <- limits[2]
  if (!is.finite(lo) || !is.finite(hi) || hi <= lo) return(pretty(limits))
  nbins <- max(1, floor(nbins))
  ext <- c(0.1 * steps[-length(steps)], steps, 10 * steps[2])
  dv <- hi - lo
  meanv <- (hi + lo) / 2
  offset <- if (abs(meanv) / dv < 100) 0 else sign(meanv) * 10^floor(log10(abs(meanv)))
  scale <- 10^floor(log10(dv / nbins))
  vmin <- lo - offset
  vmax <- hi - offset
  st <- ext * scale
  raw <- dv / nbins
  istep <- which(st >= raw)[1]
  if (is.na(istep)) istep <- length(st)
  ticks <- numeric()
  for (step in rev(st[seq_len(istep)])) {
    best <- floor(vmin / step) * step
    le <- function(x) {
      d <- floor(x / step)
      m <- x - d * step
      if (abs(m / step - 1) < 1e-10) d + 1 else d
    }
    ge <- function(x) {
      d <- floor(x / step)
      m <- x - d * step
      if (abs(m / step) < 1e-10) d else d + 1
    }
    ticks <- (le(vmin - best):ge(vmax - best)) * step + best
    if (sum(ticks <= vmax & ticks >= vmin) >= min_n) break
  }
  ticks <- ticks + offset
  tol <- 1e-9 * dv
  ticks <- ticks[ticks >= lo - tol & ticks <= hi + tol]
  ticks[abs(ticks) < tol] <- 0
  ticks
}

# Axis limits: explicit values where given, otherwise the data range plus a
# relative margin on each side (the automatic limits of common figure code).
.figA_limits <- function(values, limits = NULL, margin = 0.05, log = FALSE) {
  values <- as.numeric(values)
  values <- values[is.finite(values) & (!log | values > 0)]
  if (log) values <- log10(values)
  if (!length(values)) values <- c(0, 1)
  r <- range(values)
  if (diff(r) == 0) r <- r + c(-0.5, 0.5) * max(1, abs(r[1]) * 0.1)
  auto <- r + c(-1, 1) * margin * diff(r)
  if (log) auto <- 10^auto
  if (is.null(limits)) return(auto)
  limits <- as.numeric(unlist(limits))
  if (length(limits) != 2L) stop("Limits must have two values.", call. = FALSE)
  limits[is.na(limits)] <- auto[is.na(limits)]
  limits
}

.figA_scale <- function(axis, limits, breaks = NULL, nbins = 9, labels = ggplot2::waiver(), log = FALSE,
                        expand = c(0, 0)) {
  if (log) {
    return(.fig_scale_log10(axis, limits = limits))
  }
  if (is.null(breaks)) breaks <- .figA_breaks(limits, nbins)
  fn <- if (axis == "x") ggplot2::scale_x_continuous else ggplot2::scale_y_continuous
  if (inherits(labels, "waiver")) labels <- .figA_number_labels(breaks)
  fn(limits = limits, breaks = breaks, labels = labels, expand = expand, oob = function(x, ...) x)
}

# Tick labels as common figure code writes them: the shortest decimals that
# show all ticks, with a true minus sign.
.figA_number_labels <- function(breaks) {
  if (!length(breaks)) return(character())
  digits <- 0
  while (digits < 6 && any(abs(round(breaks, digits) - breaks) > 1e-9 * max(1, abs(breaks)))) {
    digits <- digits + 1
  }
  out <- formatC(breaks, format = "f", digits = digits)
  sub("^-", "\u2212", out)
}

# Text element: rich when 'ggtext' is available, plain otherwise.
.figA_element <- function(style, size, colour = style$colour$ink, margin = ggplot2::margin(), angle = 0,
                          hjust = NULL, vjust = NULL, face = "plain", lineheight = 1.1) {
  if (.fig_has_rich_text()) {
    ggtext::element_markdown(size = size, colour = colour, family = style$family, margin = margin,
                             angle = angle, hjust = hjust, vjust = vjust, lineheight = lineheight)
  } else {
    ggplot2::element_text(size = size, colour = colour, family = style$family, margin = margin,
                          angle = angle, hjust = hjust, vjust = vjust, face = face, lineheight = lineheight)
  }
}

# Manuscript theme with tick-label and axis-title distances in points.
.figA_theme <- function(style, grid = "y", axes = "xy", tick_size = NULL, tick_size_x = tick_size,
                        tick_size_y = tick_size, title_size = NULL, title_size_x = title_size,
                        title_size_y = title_size, tick_pad = 3.5, title_pad = 4, x_angle = 0,
                        ticks_x = TRUE, ticks_y = TRUE) {
  s <- style$size
  if (is.null(tick_size_x)) tick_size_x <- s$tick
  if (is.null(tick_size_y)) tick_size_y <- s$tick
  if (is.null(title_size_x)) title_size_x <- s$axis_title
  if (is.null(title_size_y)) title_size_y <- s$axis_title
  x_text <- if (x_angle == 0) {
    .figA_element(style, tick_size_x, margin = ggplot2::margin(t = tick_pad), vjust = 1)
  } else {
    .figA_element(style, tick_size_x, margin = ggplot2::margin(t = tick_pad), angle = x_angle, hjust = 1, vjust = 1)
  }
  th <- ThemeManuscript(style, grid = grid, axes = axes) +
    ggplot2::theme(
      axis.text.x = x_text,
      axis.text.y = .figA_element(style, tick_size_y, margin = ggplot2::margin(r = tick_pad), hjust = 1),
      axis.title.x = .figA_element(style, title_size_x, margin = ggplot2::margin(t = title_pad), vjust = 1),
      axis.title.y = .figA_element(style, title_size_y, margin = ggplot2::margin(r = title_pad), angle = 90, vjust = 0),
      legend.text = .figA_element(style, s$legend)
    )
  if (!ticks_x) th <- th + ggplot2::theme(axis.ticks.x = ggplot2::element_blank())
  if (!ticks_y) th <- th + ggplot2::theme(axis.ticks.y = ggplot2::element_blank())
  th
}

# Labels for an axis, coloured per label when colours are given.
.figA_tick_labels <- function(labels, colours = NULL) {
  labels <- as.character(labels)
  if (.fig_has_rich_text()) {
    out <- TypesetLabel(labels, rich = TRUE)
    if (!is.null(colours)) {
      ok <- !is.na(colours)
      out[ok] <- paste0("<span style='color:", colours[ok], "'>", out[ok], "</span>")
    }
    out
  } else {
    TypesetLabel(labels, rich = FALSE)
  }
}

.figA_axis_title <- function(x) if (is.null(x)) NULL else TypesetLabel(as.character(x))

# A text grob with manuscript typesetting.
.figA_text_grob <- function(label, x, y, hjust = 0, vjust = 0.5, size = 5, colour = "#222222",
                            bold = FALSE, angle = 0, style, lineheight = 1.1, typeset = TRUE) {
  if (is.na(label) || !nzchar(label)) return(grid::nullGrob())
  if (typeset && .fig_has_rich_text()) {
    text <- TypesetLabel(label, rich = TRUE)
    if (bold) text <- gsub("<sub>reg</sub>", "<sub>**reg**</sub>", paste0("**", text, "**"), fixed = TRUE)
    gridtext::richtext_grob(text, x = x, y = y, hjust = hjust, vjust = vjust, rot = angle,
                            gp = grid::gpar(fontsize = size, col = colour, fontfamily = style$family,
                                            lineheight = lineheight),
                            padding = grid::unit(0, "pt"), margin = grid::unit(0, "pt"))
  } else {
    if (typeset) label <- TypesetLabel(label, rich = FALSE)
    grid::textGrob(label, x = x, y = y, hjust = hjust, vjust = vjust, rot = angle,
                   gp = grid::gpar(fontsize = size, col = colour, fontfamily = style$family,
                                   fontface = if (bold) "bold" else "plain", lineheight = lineheight))
  }
}

# Geom drawing typeset text at data positions shifted by points (dx, dy)
# and panel fractions (dx_npc, dy_npc). Infinite positions mark the panel
# edges, so x = -Inf with dx_npc = 0.97 is the axes fraction 0.97.
.figA_GeomText <- ggplot2::ggproto("FigAGeomText", ggplot2::Geom,
  required_aes = c("x", "y", "label"),
  default_aes = ggplot2::aes(tcolour = "#222222", fontsize = 5, hjust = 0, vjust = 0.5, dx = 0, dy = 0,
                             dx_npc = 0, dy_npc = 0, angle = 0, bold = FALSE),
  draw_key = ggplot2::draw_key_blank,
  handle_na = function(self, data, params) data[!is.na(data$label) & nzchar(data$label), , drop = FALSE],
  draw_panel = function(data, panel_params, coord, style = ManuscriptStyle(), lineheight = 1.1) {
    d <- coord$transform(data, panel_params)
    if (!nrow(d)) return(grid::nullGrob())
    grobs <- lapply(seq_len(nrow(d)), function(i) {
      .figA_text_grob(d$label[i],
                      x = grid::unit(d$x[i] + d$dx_npc[i], "npc") + grid::unit(d$dx[i], "pt"),
                      y = grid::unit(d$y[i] + d$dy_npc[i], "npc") + grid::unit(d$dy[i], "pt"),
                      hjust = d$hjust[i], vjust = d$vjust[i], size = d$fontsize[i], colour = d$tcolour[i],
                      bold = isTRUE(d$bold[i]), angle = d$angle[i], style = style, lineheight = lineheight)
    })
    grid::gTree(children = do.call(grid::gList, grobs))
  }
)

# Layer of .figA_GeomText from a data frame with columns x, y, label and
# optional dx, dy, dx_npc, dy_npc, hjust, vjust, fontsize, colour, bold.
.figA_text_layer <- function(data, style, lineheight = 1.1) {
  if (is.null(data) || !nrow(data)) return(NULL)
  defaults <- list(dx = 0, dy = 0, dx_npc = 0, dy_npc = 0, hjust = 0, vjust = 0.5, fontsize = 5,
                   colour = style$colour$ink, bold = FALSE, angle = 0)
  for (a in names(defaults)) if (is.null(data[[a]])) data[[a]] <- rep(defaults[[a]], nrow(data))
  data$label <- as.character(data$label)
  mapping <- ggplot2::aes(x = .data$x, y = .data$y, label = .data$label, dx = .data$dx, dy = .data$dy,
                          dx_npc = .data$dx_npc, dy_npc = .data$dy_npc, hjust = .data$hjust,
                          vjust = .data$vjust, fontsize = .data$fontsize, tcolour = .data$colour,
                          bold = .data$bold, angle = .data$angle)
  ggplot2::layer(geom = .figA_GeomText, stat = "identity", position = "identity", data = data,
                 mapping = mapping, inherit.aes = FALSE, show.legend = FALSE,
                 params = list(style = style, lineheight = lineheight))
}

# One text row in panel fractions (axes coordinates).
.figA_npc_text <- function(label, x, y, hjust = 0, vjust = 0, size = 5, colour = "#222222", bold = FALSE,
                           x_base = -Inf, y_base = -Inf) {
  data.frame(x = x_base, y = y_base, label = label, dx_npc = x, dy_npc = y,
             hjust = hjust, vjust = vjust, fontsize = size, colour = colour, bold = bold,
             stringsAsFactors = FALSE)
}

# Geom drawing horizontal bars centred on data positions with a half-width
# in points (the "_" marker of common plotting code).
.figA_GeomBar <- ggplot2::ggproto("FigAGeomBar", ggplot2::Geom,
  required_aes = c("x", "y"),
  default_aes = ggplot2::aes(bcolour = "#222222", half = 6, lw = 1.3),
  draw_key = ggplot2::draw_key_blank,
  draw_panel = function(data, panel_params, coord) {
    d <- coord$transform(data, panel_params)
    if (!nrow(d)) return(grid::nullGrob())
    grid::segmentsGrob(x0 = grid::unit(d$x, "npc") - grid::unit(d$half, "pt"),
                       x1 = grid::unit(d$x, "npc") + grid::unit(d$half, "pt"),
                       y0 = grid::unit(d$y, "npc"), y1 = grid::unit(d$y, "npc"),
                       gp = grid::gpar(col = d$bcolour, lwd = d$lw / 0.75, lineend = "butt"))
  }
)

.figA_bar_layer <- function(data, colour, half_pt, linewidth_pt) {
  if (is.null(data) || !nrow(data)) return(NULL)
  data$colour <- colour
  data$half <- half_pt
  data$lw <- linewidth_pt
  ggplot2::layer(geom = .figA_GeomBar, stat = "identity", position = "identity", data = data,
                 mapping = ggplot2::aes(x = .data$x, y = .data$y, bcolour = .data$colour, half = .data$half,
                                        lw = .data$lw),
                 inherit.aes = FALSE, show.legend = FALSE, params = list())
}

# Note text from a template and the first row of a data frame.
.figA_note <- function(template, data) {
  if (is.null(template)) return(NULL)
  rows <- if (is.data.frame(data) && nrow(data)) data[1L, , drop = FALSE] else data
  paste(FormatTemplate(template, rows), collapse = "\n")
}

# Uniform jitter in (-half, half) from a declared seed; the global random
# state is restored afterwards so that drawing a figure has no side effects.
.figA_jitter <- function(n, half, seed) {
  if (!n || half == 0) return(rep(0, n))
  if (is.null(seed)) return(stats::runif(n, -half, half))
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  old <- if (had) get(".Random.seed", envir = globalenv(), inherits = FALSE) else NULL
  on.exit(if (had) assign(".Random.seed", old, envir = globalenv()) else
    rm(".Random.seed", envir = globalenv()), add = TRUE)
  set.seed(seed)
  stats::runif(n, -half, half)
}

# ---- clipping ---------------------------------------------------------------
# Panels are drawn without clipping so that texts may extend beyond the axes;
# data layers are clipped here instead, as plotting devices clip data to the
# axes: lines are cut at the boundary, points outside are dropped and bars
# are clamped.

.figA_keep <- function(x, ...) x

# Liang-Barsky clipping of one segment; NULL when it lies outside.
.figA_clip_segment <- function(x0, y0, x1, y1, xl, yl) {
  if (any(!is.finite(c(x0, y0, x1, y1)))) return(NULL)
  dx <- x1 - x0
  dy <- y1 - y0
  p <- c(-dx, dx, -dy, dy)
  q <- c(x0 - xl[1], xl[2] - x0, y0 - yl[1], yl[2] - y0)
  u0 <- 0
  u1 <- 1
  for (k in 1:4) {
    if (p[k] == 0) {
      if (q[k] < 0) return(NULL)
    } else {
      t <- q[k] / p[k]
      if (p[k] < 0) {
        if (t > u1) return(NULL)
        if (t > u0) u0 <- t
      } else {
        if (t < u0) return(NULL)
        if (t < u1) u1 <- t
      }
    }
  }
  c(x0 + u0 * dx, y0 + u0 * dy, x0 + u1 * dx, y0 + u1 * dy)
}

# Clip polylines (rows in drawing order within `group`) to the limits; the
# result has one row per vertex and a `piece` id per continuous part.
.figA_clip_path <- function(d, xl, yl, x = "x", y = "y", group = NULL) {
  if (is.null(d) || !nrow(d)) return(d)
  g <- if (is.null(group)) rep(1L, nrow(d)) else d[[group]]
  pieces <- list()
  pid <- 0L
  flush <- function(cur, row) {
    if (is.null(cur) || nrow(cur) < 2L) return(NULL)
    pid <<- pid + 1L
    out <- row[rep(1L, nrow(cur)), , drop = FALSE]
    out[[x]] <- cur[, 1]
    out[[y]] <- cur[, 2]
    out$piece <- pid
    out
  }
  for (gg in unique(g)) {
    idx <- which(g == gg)
    xs <- as.numeric(d[[x]][idx])
    ys <- as.numeric(d[[y]][idx])
    cur <- NULL
    for (j in seq_len(max(0L, length(idx) - 1L))) {
      s <- .figA_clip_segment(xs[j], ys[j], xs[j + 1L], ys[j + 1L], xl, yl)
      if (is.null(s)) {
        pieces[[length(pieces) + 1L]] <- flush(cur, d[idx[j], , drop = FALSE])
        cur <- NULL
        next
      }
      if (!is.null(cur) && abs(cur[nrow(cur), 1] - s[1]) < 1e-12 && abs(cur[nrow(cur), 2] - s[2]) < 1e-12) {
        cur <- rbind(cur, s[3:4])
      } else {
        pieces[[length(pieces) + 1L]] <- flush(cur, d[idx[j], , drop = FALSE])
        cur <- rbind(s[1:2], s[3:4])
      }
    }
    pieces[[length(pieces) + 1L]] <- flush(cur, d[idx[1L], , drop = FALSE])
  }
  pieces <- pieces[!vapply(pieces, is.null, logical(1))]
  if (!length(pieces)) {
    out <- d[0, , drop = FALSE]
    out$piece <- integer()
    return(out)
  }
  out <- do.call(rbind, pieces)
  rownames(out) <- NULL
  out
}

# Points whose centre lies inside the limits.
.figA_inside <- function(x, y, xl, yl, tol = 1e-9) {
  tx <- tol * max(1, abs(diff(xl)))
  ty <- tol * max(1, abs(diff(yl)))
  is.finite(x) & is.finite(y) & x >= xl[1] - tx & x <= xl[2] + tx & y >= yl[1] - ty & y <= yl[2] + ty
}

# Ribbon clipped to an x range (interpolated at the edges) with y clamped.
.figA_clip_ribbon <- function(x, lo, hi, xl, yl) {
  keep <- is.finite(x) & is.finite(lo) & is.finite(hi)
  x <- x[keep]
  lo <- lo[keep]
  hi <- hi[keep]
  o <- order(x)
  x <- x[o]
  lo <- lo[o]
  hi <- hi[o]
  if (length(x) < 2L) return(data.frame(x = x, lower = lo, upper = hi))
  inside <- x >= xl[1] & x <= xl[2]
  edges <- xl[xl > min(x) & xl < max(x)]
  xe <- sort(unique(c(x[inside], edges)))
  data.frame(x = xe, lower = pmin(pmax(stats::approx(x, lo, xe)$y, yl[1]), yl[2]),
             upper = pmin(pmax(stats::approx(x, hi, xe)$y, yl[1]), yl[2]))
}

# Size and stroke of a downward triangle (shape 25) whose outline is
# sqrt(s) pt wide, as the "v" marker of common plotting code; the device
# draws pch 25 about 1.01 times its character size wide.
.figA_size_triangle <- function(s, lw) {
  stroke <- lw / (0.75 * ggplot2::.stroke / 2)
  size <- (sqrt(s) / 1.0104 - stroke * ggplot2::.stroke / 2) / ggplot2::.pt
  list(size = max(size, 0.01), stroke = stroke)
}

# A logarithmic axis for values already on the log10 scale: majors at
# integers labelled 10^k, unlabelled minor ticks at 2-9 times each power.
.figA_scale_log_space <- function(axis, limits) {
  lo <- floor(limits[1]) - 1
  hi <- ceiling(limits[2]) + 1
  majors <- lo:hi
  minors <- log10(as.vector(outer(2:9, 10^majors)))
  inside <- function(v) v[v >= limits[1] - 1e-9 & v <= limits[2] + 1e-9]
  majors <- inside(majors)
  minors <- inside(minors)
  labels <- if (.fig_has_rich_text()) paste0("10<sup>", majors, "</sup>") else parse(text = paste0("10^", majors))
  fn <- if (axis == "y") ggplot2::scale_y_continuous else ggplot2::scale_x_continuous
  fn(limits = limits, breaks = majors, labels = labels, minor_breaks = minors, expand = c(0, 0), oob = .figA_keep,
     guide = ggplot2::guide_axis(minor.ticks = TRUE))
}
