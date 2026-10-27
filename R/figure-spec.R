#' Figure Plot Builders Available to Figure Specifications
#'
#' Names usable in the `grammar` field of a figure specification and the
#' exported function each one calls.
#'
#' @return Named character vector: grammar name to function name.
#' @examples
#' head(FigureGrammars())
#' @seealso [RenderFigure()]
#' @export
FigureGrammars <- function() {
  c(
    paired_patients = "PlotPairedPatients",
    quantile_curves = "PlotQuantileCurves",
    band_profiles = "PlotBandProfiles",
    interval_forest = "PlotIntervalForest",
    group_strip = "PlotGroupStrip",
    stacked_bars = "PlotStackedBars",
    annotated_heatmap = "PlotAnnotatedHeatmap",
    dot_matrix = "PlotDotMatrix",
    embedding = "PlotEmbedding",
    density_outlines = "PlotDensityOutlines",
    cell_map = "PlotCellMap",
    territories = "PlotTerritories",
    group_differences = "PlotGroupDifferences",
    volcano = "PlotVolcano",
    fluorescence_field = "PlotFluorescenceField",
    alteration_matrix = "PlotAlterationMatrix",
    scatter_groups = "PlotScatterGroups",
    bars = "PlotBars",
    image = "PlotImage",
    text_block = "PlotTextBlock"
  )
}

#' Render a Figure from a Specification
#'
#' Builds every panel of a figure from a declarative specification and
#' named plot data, then composes the page. A specification is a list (or a
#' JSON file) with `height_mm`, optional `width_mm`, `panels`, `texts` and
#' `legends`. Each panel has a `box` (`[left, top, width, height]` in mm),
#' optional `letter`, `letter_at`, `heading` and `note`, a `grammar` from
#' [FigureGrammars()], the name(s) of its `data` and builder `args`.
#'
#' Colours in `args`, `texts` and `legends` may be hex values, style colour
#' names (`"ink"`, `"muted"`, ...) or palette entries written
#' `"palette/name"` (for example `"groups/group1"`); character vectors and
#' named lists of such values are resolved element by element.
#'
#' @param spec A specification list or the path of a JSON file.
#' @param data Named list of data frames (or other inputs) referred to by
#'   the panels.
#' @param style A [ManuscriptStyle()] object; `spec$style` entries are
#'   applied on top.
#' @return A [ComposeFigure()] result.
#' @export
RenderFigure <- function(spec, data = list(), style = ManuscriptStyle()) {
  if (is.character(spec) && length(spec) == 1L) {
    if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Reading a JSON specification needs 'jsonlite'.", call. = FALSE)
    spec <- jsonlite::read_json(spec, simplifyVector = TRUE, simplifyDataFrame = FALSE,
                                simplifyMatrix = FALSE)
  }
  if (!is.list(spec) || is.null(spec$height_mm) || !is.list(spec$panels)) {
    stop("spec needs height_mm and a list of panels.", call. = FALSE)
  }
  if (!is.list(data) || (length(data) && is.null(names(data)))) stop("data must be a named list.", call. = FALSE)
  style <- .fig_check_style(style)
  if (!is.null(spec$style)) style <- do.call(ManuscriptStyle, utils::modifyList(unclass(style), spec$style))
  grammars <- FigureGrammars()
  panels <- lapply(seq_along(spec$panels), function(i) {
    p <- spec$panels[[i]]
    plot <- NULL
    if (!is.null(p$grammar)) {
      if (!p$grammar %in% names(grammars)) stop("Unknown grammar '", p$grammar, "' in panel ", i, ".", call. = FALSE)
      fun <- get(grammars[[p$grammar]], envir = asNamespace("phenoscapR"), mode = "function")
      args <- .fig_resolve(if (is.null(p$args)) list() else p$args, style)
      inputs <- .fig_panel_data(p$data, data, i)
      plot <- do.call(fun, c(inputs, args, list(style = style)))
    }
    FigurePanel(plot, box = unlist(p$box), letter = p$letter, letter_at = unlist(p$letter_at),
                heading = p$heading, note = p$note, fill_box = isTRUE(p$fill_box))
  })
  texts <- lapply(spec$texts, function(t) {
    FigureText(t$label, unlist(t$at), size = t$size,
               colour = if (is.null(t$colour)) NULL else .fig_colour(t$colour, style),
               bold = isTRUE(t$bold), hjust = if (is.null(t$hjust)) 0 else t$hjust,
               vjust = if (is.null(t$vjust)) 1 else t$vjust, angle = if (is.null(t$angle)) 0 else t$angle)
  })
  legends <- lapply(spec$legends, function(l) {
    FigureGrob(LegendKeys(unlist(l$labels), .fig_colour(unlist(l$colours), style),
                          shape = if (is.null(l$shape)) "point" else unlist(l$shape),
                          ncol = if (is.null(l$ncol)) length(l$labels) else l$ncol,
                          size = l$size, style = style), unlist(l$at))
  })
  ComposeFigure(panels, height_mm = spec$height_mm, width_mm = spec$width_mm,
                texts = c(texts, legends), style = style)
}

#' Write a Figure from a Specification
#'
#' File-producing form of [RenderFigure()] for workflow graphs: reads the
#' specification and the panel data, renders the figure and writes PDF and
#' PNG files.
#'
#' @param spec Specification list or JSON path.
#' @param data Named list of data frames, or of paths to `.rds`, `.tsv`,
#'   `.tsv.gz` or `.csv` files.
#' @param pdf,png Output paths.
#' @param style A [ManuscriptStyle()] object.
#' @return Output paths, invisibly.
#' @export
WriteFigure <- function(spec, data, pdf, png, style = ManuscriptStyle()) {
  data <- lapply(data, .fig_read_input)
  SaveFigure(RenderFigure(spec, data, style), pdf = pdf, png = png)
}

.fig_read_input <- function(x) {
  if (!is.character(x) || length(x) != 1L || !file.exists(x)) return(x)
  if (grepl("\\.rds$", x, ignore.case = TRUE)) return(readRDS(x))
  if (grepl("\\.(tsv|tsv\\.gz|txt)$", x, ignore.case = TRUE)) {
    return(as.data.frame(data.table::fread(x, sep = "\t", check.names = FALSE, na.strings = c("NA", ""),
                                           nThread = 1L)))
  }
  if (grepl("\\.csv(\\.gz)?$", x, ignore.case = TRUE)) {
    return(as.data.frame(data.table::fread(x, check.names = FALSE, nThread = 1L)))
  }
  x
}

.fig_panel_data <- function(names, data, i) {
  if (is.null(names)) return(list())
  if (is.character(names) && length(names) == 1L && is.null(base::names(names))) {
    if (!names %in% base::names(data)) stop("Panel ", i, " refers to missing data '", names, "'.", call. = FALSE)
    return(list(data = data[[names]]))
  }
  names <- as.list(names)
  if (is.null(base::names(names)) || any(!nzchar(base::names(names)))) {
    stop("Panel ", i, " data must be one name or a named set of names.", call. = FALSE)
  }
  lapply(names, function(n) {
    if (!n %in% base::names(data)) stop("Panel ", i, " refers to missing data '", n, "'.", call. = FALSE)
    data[[n]]
  })
}

# Resolve colour references inside builder arguments.
.fig_resolve <- function(args, style) {
  colour_args <- grepl("(colour|color|fill|palette)s?$", names(args))
  args[colour_args] <- lapply(args[colour_args], .fig_colour, style = style)
  args
}

.fig_colour <- function(x, style) {
  if (is.null(x)) return(NULL)
  if (is.list(x)) return(lapply(x, .fig_colour, style = style))
  if (!is.character(x)) return(x)
  if (length(x) == 1L && grepl("^[a-z_]+$", x) && x %in% names(style$palettes) && !x %in% names(style$colour)) {
    return(style$palettes[[x]])
  }
  out <- vapply(x, function(v) {
    if (is.na(v) || grepl("^#", v) || v %in% grDevices::colors()) return(v)
    if (v %in% names(style$colour)) return(style$colour[[v]])
    if (grepl("^[a-z_]+/[A-Za-z0-9_]+$", v)) {
      parts <- strsplit(v, "/", fixed = TRUE)[[1L]]
      pal <- style$palettes[[parts[1]]]
      if (!is.null(pal) && parts[2] %in% names(pal)) return(unname(pal[[parts[2]]]))
    }
    stop("Unknown colour '", v, "'.", call. = FALSE)
  }, character(1))
  stats::setNames(out, names(x))
}
