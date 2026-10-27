#' Manuscript Figure Style
#'
#' Returns the typography, colours, line widths and page settings of a
#' compact journal figure style: DejaVu Sans at 6 pt, 8 pt bold lower-case
#' panel letters, 6.4 pt bold panel headings, thin grey axes without top and
#' right lines, a 180 mm page width and 450 dpi raster output. Every plot
#' builder and [ComposeFigure()] reads its settings from this object, so one
#' change here restyles all figures.
#'
#' Sizes are in points, line widths in points (converted for 'ggplot2' with
#' [PtLinewidth()]) and page dimensions in millimetres. Palettes hold generic
#' names; map study labels to them in study configuration, not in code.
#'
#' @param ... Named values replacing top-level entries or, for list entries,
#'   individual elements (for example `size = list(base = 7)`).
#'
#' @return A list of class `phenoscapR_style` with elements `family`, `size`,
#'   `colour`, `line`, `page` and `palettes`.
#' @examples
#' style <- ManuscriptStyle()
#' style$size$letter
#' ManuscriptStyle(size = list(base = 7))$size$base
#' @seealso [ThemeManuscript()], [ManuscriptPalettes()], [ComposeFigure()]
#' @export
ManuscriptStyle <- function(...) {
  style <- list(
    family = "DejaVu Sans",
    size = list(
      base = 6, letter = 8, heading = 6.4, axis_title = 5.8, tick = 5.5,
      tick_small = 5.1, legend = 5, statistic = 4.8, note = 4.6, label = 5
    ),
    colour = list(
      ink = "#222222", muted = "#6B6B6B", axis = "#555555", grid = "#EDEDED",
      reference = "#9E9E9E", frame = "#BBBBBB", missing = "#EEEEEE",
      significant = "#B2182B", minimum_p = "#D55E00", open_edge = "#8A8A8A"
    ),
    line = list(axis = 0.5, tick = 0.4, tick_length = 2, grid = 0.5, reference = 0.55,
                data = 0.65, summary = 1.4, frame = 0.4),
    page = list(width_mm = 180, dpi = 450),
    palettes = ManuscriptPalettes()
  )
  changes <- list(...)
  if (length(changes)) {
    if (is.null(names(changes)) || any(!nzchar(names(changes))) ||
        any(!names(changes) %in% names(style))) {
      stop("Style changes must be named entries of ManuscriptStyle().", call. = FALSE)
    }
    for (name in names(changes)) {
      if (is.list(style[[name]]) && is.list(changes[[name]])) {
        unknown <- setdiff(names(changes[[name]]), names(style[[name]]))
        if (name != "palettes" && length(unknown)) {
          stop("Unknown ", name, " entr", if (length(unknown) == 1L) "y" else "ies",
               ": ", paste(unknown, collapse = ", "), call. = FALSE)
        }
        style[[name]][names(changes[[name]])] <- changes[[name]]
      } else {
        style[[name]] <- changes[[name]]
      }
    }
  }
  structure(style, class = "phenoscapR_style")
}

#' Manuscript Palettes
#'
#' Named colour palettes used by [ManuscriptStyle()]. Names are generic cell
#' types, groups, markers and alteration classes; a study maps its own labels
#' onto them.
#'
#' * `groups`: Okabe-Ito colours for three clinical groups (`group1` to
#'   `group3`).
#' * `lineage`: one colour per cell lineage for legends and embeddings.
#' * `subsets`: highlight colours for cell maps (focus subsets on grey
#'   background cells) and the tumour interface tint.
#' * `coarse`: six coarse classes for whole-section maps.
#' * `neighbourhood`: an ordered palette for cellular neighbourhoods.
#' * `fluorescence`: display colours of common immunofluorescence channels.
#' * `alteration`: genomic alteration classes.
#' * `qc`: four colours for exclusion classes.
#' * `sequential`, `diverging`: endpoints for continuous scales.
#' * `clusters`: twenty colours for many unordered clusters.
#'
#' @return A named list of named character vectors.
#' @examples
#' ManuscriptPalettes()$groups
#' @export
ManuscriptPalettes <- function() {
  list(
    groups = c(group1 = "#009E73", group2 = "#D55E00", group3 = "#0072B2"),
    lineage = c(
      tumour = "#e34948", tumour_state = "#8E1B1B", epithelium = "#F4B7AE",
      treg = "#7B2FBE", cd4_t = "#3B7DD8", cd8_t = "#1F3F8F", other_t = "#9CC3F0",
      nk = "#35B5C4", b = "#eda100", plasma = "#A9740A", macrophage = "#D9730D",
      granulocyte = "#008300", other_immune = "#9AA02B", endothelial = "#1baf7a",
      stromal = "#B9A38A", fdc = "#C2378E", unassigned = "#E3E3E3"
    ),
    subsets = c(
      treg = "#7B2FBE", cd4_t = "#3B7DD8", cd8_t = "#0F8F7E", macrophage = "#D9730D",
      fdc = "#C2378E", tumour = "#A6A6A6", other = "#E3E3E3", interface = "#FBE3C8",
      tumour_territory = "#F4C3BC", other_territory = "#E6E6E6"
    ),
    coarse = c(
      tumour = "#e34948", treg = "#7B2FBE", t_nk = "#2a78d6", b_plasma = "#eda100",
      myeloid = "#008300", endothelial_stromal = "#1baf7a", unassigned = "#D9D9D9"
    ),
    neighbourhood = c(
      tumour = "#e34948", macrophage_cd4 = "#eda100", vessel = "#1baf7a",
      stroma_fdc = "#4a3aa7", other_t_nk = "#2a78d6", cd8_t = "#008300",
      tumour_mixed = "#F3A7A0", macrophage = "#9C4A00"
    ),
    fluorescence = c(
      dapi = "#4059FF", panck = "#D9D9D9", cd3e = "#1AE640", foxp3 = "#FF1AB3",
      cd68 = "#FF9E00"
    ),
    alteration = c(
      missense = "#008300", truncating = "#222222", deletion = "#2a78d6",
      amplification = "#e34948", multiple = "#eda100", none = "#F0F0F0",
      burden = "#8A8A8A", subtype1 = "#7B2FBE", subtype2 = "#1baf7a"
    ),
    qc = c(class1 = "#e34948", class2 = "#eda100", class3 = "#2a78d6",
           class4 = "#7B2FBE", retained = "#DADADA"),
    sequential = c(low = "#f7fbff", high = "#08306b"),
    diverging = c(low = "#2166ac", mid = "#f7f7f7", high = "#b2182b"),
    clusters = c(
      "#1f77b4", "#aec7e8", "#ff7f0e", "#ffbb78", "#2ca02c", "#98df8a", "#d62728",
      "#ff9896", "#9467bd", "#c5b0d5", "#8c564b", "#c49c94", "#e377c2", "#f7b6d2",
      "#7f7f7f", "#c7c7c7", "#bcbd22", "#dbdb8d", "#17becf", "#9edae5"
    )
  )
}

#' Convert Points to a 'ggplot2' Line Width
#'
#' 'ggplot2' draws a line width of 1 as 0.75 mm (R's line width unit is
#' 1/96 inch); this converts a width given in typographic points.
#'
#' @param pt Numeric line width in points.
#' @return Numeric 'ggplot2' `linewidth`.
#' @examples
#' PtLinewidth(0.5)
#' @export
PtLinewidth <- function(pt) pt / (0.75 * ggplot2::.pt)

.fig_check_style <- function(style) {
  if (!inherits(style, "phenoscapR_style")) {
    stop("style must come from ManuscriptStyle().", call. = FALSE)
  }
  style
}

# Size in points to the 'ggplot2' text size unit (millimetres).
.fig_text_size <- function(pt) pt / ggplot2::.pt

.fig_has_rich_text <- function() {
  requireNamespace("gridtext", quietly = TRUE) && requireNamespace("ggtext", quietly = TRUE)
}

#' Manuscript 'ggplot2' Theme
#'
#' A compact theme for multi-panel figures: no panel title (headings are
#' placed by [ComposeFigure()]), thin grey left and bottom axis lines, short
#' ticks, light horizontal grid lines when `grid = "y"`, no legend
#' background and zero outer margins. When the optional packages 'ggtext'
#' and 'gridtext' are installed, axis titles and tick labels accept the
#' rich text produced by [TypesetLabel()].
#'
#' @param style A [ManuscriptStyle()] object.
#' @param grid One of `"y"`, `"x"`, `"both"` or `"none"`.
#' @param axes One of `"xy"` (left and bottom lines), `"x"`, `"y"` or
#'   `"none"`.
#' @return A 'ggplot2' theme.
#' @examples
#' library(ggplot2)
#' ggplot(data.frame(x = 1:3, y = c(2, 4, 3)), aes(x, y)) +
#'   geom_point() +
#'   ThemeManuscript()
#' @export
ThemeManuscript <- function(style = ManuscriptStyle(), grid = c("y", "x", "both", "none"),
                            axes = c("xy", "x", "y", "none")) {
  style <- .fig_check_style(style)
  grid <- match.arg(grid)
  axes <- match.arg(axes)
  s <- style$size
  k <- style$colour
  l <- style$line
  rich <- .fig_has_rich_text()
  text_el <- function(size, colour = k$ink, ...) {
    if (rich) {
      ggtext::element_markdown(size = size, colour = colour, family = style$family, ...)
    } else {
      ggplot2::element_text(size = size, colour = colour, family = style$family, ...)
    }
  }
  axis_line <- ggplot2::element_line(colour = k$axis, linewidth = PtLinewidth(l$axis),
                                     lineend = "butt")
  grid_line <- ggplot2::element_line(colour = k$grid, linewidth = PtLinewidth(l$grid))
  blank <- ggplot2::element_blank()
  ggplot2::theme_classic(base_size = s$base, base_family = style$family) +
    ggplot2::theme(
      text = ggplot2::element_text(size = s$base, colour = k$ink, family = style$family),
      plot.title = blank,
      plot.subtitle = blank,
      plot.background = ggplot2::element_rect(fill = NA, colour = NA),
      panel.background = ggplot2::element_rect(fill = NA, colour = NA),
      plot.margin = ggplot2::margin(0, 0, 0, 0),
      axis.title.x = text_el(s$axis_title, margin = ggplot2::margin(t = 2)),
      axis.title.y = text_el(s$axis_title, angle = 90, margin = ggplot2::margin(r = 2)),
      axis.text.x = text_el(s$tick, margin = ggplot2::margin(t = 1)),
      axis.text.y = text_el(s$tick, margin = ggplot2::margin(r = 1)),
      axis.ticks = ggplot2::element_line(colour = k$ink, linewidth = PtLinewidth(l$tick)),
      axis.ticks.length = ggplot2::unit(l$tick_length, "pt"),
      axis.minor.ticks.length = ggplot2::unit(l$tick_length * 0.55, "pt"),
      axis.line.x = if (axes %in% c("xy", "x")) axis_line else blank,
      axis.line.y = if (axes %in% c("xy", "y")) axis_line else blank,
      panel.grid.major.y = if (grid %in% c("y", "both")) grid_line else blank,
      panel.grid.major.x = if (grid %in% c("x", "both")) grid_line else blank,
      panel.grid.minor = blank,
      legend.background = blank,
      legend.key = blank,
      legend.title = blank,
      legend.text = ggplot2::element_text(size = s$legend, colour = k$ink, family = style$family),
      legend.key.size = ggplot2::unit(6, "pt"),
      legend.margin = ggplot2::margin(0, 0, 0, 0),
      legend.box.spacing = ggplot2::unit(2, "pt"),
      strip.background = blank,
      strip.text = ggplot2::element_text(size = s$tick, colour = k$ink, family = style$family)
    )
}

#' Format P Values for Figures
#'
#' Two significant digits from 0.001 upwards, scientific notation below
#' (`4.9 × 10⁻⁴` after [TypesetLabel()]) and `"n.e."` (not evaluable) for
#' missing or non-finite values. This is the C format `%.2g` / `%.1e` of
#' common figure code.
#'
#' @param p Numeric vector of P values.
#' @return Character vector; values below 0.001 use the plain form
#'   `"4.9e-04"`, which [TypesetLabel()] turns into a power of ten.
#' @examples
#' FormatP(c(0.0039, 0.055, 0.5, 4.9e-4, NA))
#' @export
FormatP <- function(p) {
  if (!is.numeric(p)) stop("p must be numeric.", call. = FALSE)
  out <- rep("n.e.", length(p))
  ok <- is.finite(p)
  big <- ok & p >= 1e-3
  out[big] <- sprintf("%.2g", p[big])
  out[ok & !big] <- sprintf("%.1e", p[ok & !big])
  out
}

#' Typeset Figure Text
#'
#' Applies manuscript typesetting to plain labels and returns rich text for
#' 'gridtext'/'ggtext': italic *P*, *q* and *n* before `=` or `<`; powers of
#' ten for `4.9e-04`; superscript plus signs on markers (`CD8+`, `FOXP3+`,
#' `CD4 T`, `CD8 T`); `Treg`/`Tregs` with subscript *reg*; `log2`; `mm2`;
#' micrometres; italic gene symbols; and line breaks.
#'
#' @param x Character vector of labels.
#' @param genes Gene symbols to set in italics.
#' @param markers Marker names that take a superscript `+` when followed by
#'   `+`.
#' @param rich If `FALSE`, return plain text with Unicode substitutes
#'   (superscript plus, subscript two, minus sign) instead of markup. The
#'   default uses markup when 'gridtext' and 'ggtext' are installed.
#' @return Character vector of the same length.
#' @examples
#' TypesetLabel(c("p = 4.9e-04", "Tregs near CD8+ cells", "log2 ratio (mm2)"),
#'              rich = FALSE)
#' @export
TypesetLabel <- function(x, genes = c("TP53", "RB1"),
                         markers = c("CD\\d+[a-z]?", "FOXP3", "PD-L1", "PD-1", "Ki67", "MPO"),
                         rich = .fig_has_rich_text()) {
  if (!is.character(x)) stop("x must be character.", call. = FALSE)
  na <- is.na(x)
  x[na] <- ""
  marker_rx <- paste0("\\b(", paste(markers, collapse = "|"), ")\\+")
  gene_rx <- if (length(genes)) paste0("\\b(", paste(genes, collapse = "|"), ")\\b") else NULL
  if (rich) {
    x <- gsub("&", "&amp;", x, fixed = TRUE)
    x <- gsub("<", "&lt;", x, fixed = TRUE)
    x <- gsub(">", "&gt;", x, fixed = TRUE)
    x <- gsub("(\\d(?:\\.\\d+)?)e-0*(\\d+)", "\\1 \u00d7 10<sup>\u2212\\2</sup>", x, perl = TRUE)
    x <- gsub("(?<![A-Za-z])p\\s?(=|&lt;)\\s?", "<i>P</i> \\1 ", x, perl = TRUE)
    x <- gsub("(?<![A-Za-z])q\\s?(=|&lt;)\\s?", "<i>q</i> \\1 ", x, perl = TRUE)
    x <- gsub("(?<![A-Za-z])n\\s?=\\s?", "<i>n</i> = ", x, perl = TRUE)
    x <- gsub(marker_rx, "\\1<sup>+</sup>", x, perl = TRUE)
    x <- gsub("\\b(CD4|CD8)( T\\b)", "\\1<sup>+</sup>\\2", x, perl = TRUE)
    x <- gsub("\\bTregs\\b", "T<sub>reg</sub> cells", x, perl = TRUE)
    x <- gsub("\\bTreg\\b", "T<sub>reg</sub>", x, perl = TRUE)
    x <- gsub("\\blog2\\b", "log<sub>2</sub>", x, perl = TRUE)
    x <- gsub("mm2\\b", "mm<sup>2</sup>", x, perl = TRUE)
    x <- gsub("(\\d)[ -]um\\b", "\\1 \u00b5m", x, perl = TRUE)
    if (!is.null(gene_rx)) x <- gsub(gene_rx, "<i>\\1</i>", x, perl = TRUE)
    x <- gsub("\n", "<br>", x, fixed = TRUE)
  } else {
    sup <- c("0" = "\u2070", "1" = "\u00b9", "2" = "\u00b2", "3" = "\u00b3", "4" = "\u2074",
             "5" = "\u2075", "6" = "\u2076", "7" = "\u2077", "8" = "\u2078", "9" = "\u2079")
    m <- regmatches(x, gregexpr("(\\d(?:\\.\\d+)?)e-0*(\\d+)", x, perl = TRUE))
    for (i in seq_along(x)) {
      for (hit in m[[i]]) {
        parts <- regmatches(hit, regexec("^(\\d(?:\\.\\d+)?)e-0*(\\d+)$", hit))[[1L]]
        exponent <- paste(sup[strsplit(parts[[3L]], "")[[1L]]], collapse = "")
        x[i] <- sub(hit, paste0(parts[[2L]], " \u00d7 10\u207b", exponent), x[i], fixed = TRUE)
      }
    }
    x <- gsub("(?<![A-Za-z])p\\s?(=|<)\\s?", "P \\1 ", x, perl = TRUE)
    x <- gsub(marker_rx, "\\1\u207a", x, perl = TRUE)
    x <- gsub("\\b(CD4|CD8)( T\\b)", "\\1\u207a\\2", x, perl = TRUE)
    x <- gsub("\\bTregs\\b", "Treg cells", x, perl = TRUE)
    x <- gsub("\\blog2\\b", "log\u2082", x, perl = TRUE)
    x <- gsub("mm2\\b", "mm\u00b2", x, perl = TRUE)
    x <- gsub("(\\d)[ -]um\\b", "\\1 \u00b5m", x, perl = TRUE)
  }
  x[na] <- NA_character_
  x
}

#' Format a Patient-Level Statistic Line
#'
#' Builds the short statistic text placed above a panel, for example
#' `"11/12 patients; p = 0.0015"` or `"+3.4; p = 0.021; q = 0.18"`, before
#' typesetting.
#'
#' @param p P value.
#' @param k,n Patients in the expected direction and evaluable patients; omit
#'   both for a contrast line.
#' @param q Optional adjusted P value.
#' @param estimate Optional signed effect shown first, with `digits`
#'   decimals and a true minus sign.
#' @param digits Decimals of `estimate`.
#' @param unit Optional text after the patient count, default `"patients"`.
#' @return Character vector.
#' @examples
#' FormatStatistic(0.0015, k = 11, n = 12)
#' FormatStatistic(0.021, q = 0.18, estimate = -3.42)
#' @export
FormatStatistic <- function(p, k = NULL, n = NULL, q = NULL, estimate = NULL, digits = 1,
                            unit = "patients") {
  parts <- list()
  if (!is.null(estimate)) {
    e <- formatC(abs(estimate), format = "f", digits = digits)
    parts$estimate <- ifelse(is.na(estimate), "n.e.",
                             paste0(ifelse(estimate < 0, "\u2212", "+"), e))
  }
  if (!is.null(k) || !is.null(n)) {
    if (is.null(k) || is.null(n)) stop("Supply both k and n.", call. = FALSE)
    parts$count <- paste0(k, "/", n, if (nzchar(unit)) paste0(" ", unit) else "")
  }
  parts$p <- paste0("p = ", FormatP(p))
  if (!is.null(q)) parts$q <- paste0("q = ", FormatP(q))
  do.call(paste, c(unname(parts), sep = "; "))
}
