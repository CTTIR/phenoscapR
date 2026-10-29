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
#' Positions can also be given as fractions of the page, as in figure code
#' that places axes with `[left, bottom, width, height]` fractions: a panel
#' `axes` field replaces `box`, `letter_xy` replaces `letter_at`, and a text
#' or legend `xy` replaces `at` (fractions measured from the bottom-left
#' corner; letters and texts hang from the given point).
#'
#' A specification may be split over several files: give a character vector
#' of JSON paths (or a directory of `*.json` files). Page fields are taken
#' from the first file that has them; `panels`, `texts` and `legends` are
#' concatenated in file order.
#'
#' Colours in `args`, `texts` and `legends` may be hex values, style colour
#' names (`"ink"`, `"muted"`, ...) or palette entries written
#' `"palette/name"` (for example `"groups/group1"`); character vectors and
#' named lists of such values are resolved element by element. Every builder
#' argument whose name ends in `colour`, `color`, `fill` or `palette` (or
#' their plurals) is resolved this way, so arguments that name data columns
#' must not end like that. The value `"group"` is kept as it is, for
#' builders that colour by group (`label_colour = "group"`).
#'
#' Builders with a `box_mm` argument receive the size of their data area in
#' millimetres (used for `"auto"` tick intervals, see [NiceBreaks()]).
#'
#' Typesetting ([TypesetLabel()]) can be switched off with `"typeset":
#' false` for the whole specification, for one panel (its heading, note and
#' plot), for one text or for one legend; `"typeset": {"off": ["treg"]}`
#' switches off single rules only (see [TypesetLabel()]).
#'
#' Legends take `labels`, `colours`, `shape`, `ncol`, `size` and the layout
#' options of [LegendKeys()] (`key_mm`, `marker_size`, `row_mm`,
#' `text_gap_mm`, `column_gap_mm`, `byrow`). Texts take `label`, `xy` or
#' `at`, `size`, `colour`, `bold`, `hjust`, `vjust` (a number or
#' `"baseline"`) and `angle`.
#'
#' @param spec A specification list, a JSON path, several JSON paths or a
#'   directory of JSON files.
#' @param data Named list of data frames (or other inputs) referred to by
#'   the panels.
#' @param style A [ManuscriptStyle()] object; `spec$style` entries are
#'   applied on top.
#' @return A [ComposeFigure()] result.
#' @examples
#' d <- data.frame(group = rep(c("A", "B"), each = 3), value = c(1, 2, 3, 2, 3, 5))
#' spec <- list(height_mm = 50, width_mm = 70, panels = list(
#'   list(box = c(15, 10, 45, 30), letter = "a", heading = "Values", grammar = "group_strip",
#'        data = "values",
#'        args = list(group_colours = list(A = "groups/group1", B = "groups/group2")))))
#' fig <- RenderFigure(spec, list(values = d))
#' grid::grid.newpage(); print(fig)
#' @export
RenderFigure <- function(spec, data = list(), style = ManuscriptStyle()) {
  if (is.character(spec)) spec <- .fig_read_spec(spec)
  if (!is.list(spec) || is.null(spec$height_mm) || !is.list(spec$panels)) {
    stop("spec needs height_mm and a list of panels.", call. = FALSE)
  }
  if (!is.list(data) || (length(data) && is.null(names(data)))) stop("data must be a named list.", call. = FALSE)
  style <- .fig_check_style(style)
  if (!is.null(spec$style)) style <- do.call(ManuscriptStyle, utils::modifyList(unclass(style), spec$style))
  grammars <- FigureGrammars()
  W <- if (is.null(spec$width_mm)) style$page$width_mm else spec$width_mm
  H <- spec$height_mm
  frac_box <- function(a) c(a[1] * W, (1 - a[2] - a[4]) * H, a[3] * W, a[4] * H)
  frac_at <- function(a) c(a[1] * W, (1 - a[2]) * H)
  typeset_page <- .fig_typeset_value(spec$typeset, TRUE)
  flag <- function(x) .fig_typeset_value(x, typeset_page)
  panels <- lapply(seq_along(spec$panels), function(i) {
    p <- spec$panels[[i]]
    plot <- NULL
    box <- if (!is.null(p$axes)) frac_box(unlist(p$axes)) else unlist(p$box)
    typeset <- flag(p$typeset)
    if (!is.null(p$grammar)) {
      if (!p$grammar %in% names(grammars)) stop("Unknown grammar '", p$grammar, "' in panel ", i, ".", call. = FALSE)
      fun <- get(grammars[[p$grammar]], envir = asNamespace("phenoscapR"), mode = "function")
      args <- .fig_resolve(if (is.null(p$args)) list() else p$args, style)
      inputs <- .fig_panel_data(p$data, data, i)
      if ("box_mm" %in% names(formals(fun)) && is.null(args$box_mm)) args$box_mm <- box[3:4]
      plot <- .fig_with_typeset(typeset, do.call(fun, c(inputs, args, list(style = style))))
    }
    letter_at <- if (!is.null(p$letter_xy)) frac_at(unlist(p$letter_xy)) else unlist(p$letter_at)
    FigurePanel(plot, box = box, letter = p$letter, letter_at = letter_at,
                heading = p$heading, note = p$note, fill_box = isTRUE(p$fill_box), typeset = typeset)
  })
  texts <- lapply(spec$texts, function(t) {
    FigureText(t$label, if (!is.null(t$xy)) frac_at(unlist(t$xy)) else unlist(t$at), size = t$size,
               colour = if (is.null(t$colour)) NULL else .fig_colour(t$colour, style),
               bold = isTRUE(t$bold), hjust = if (is.null(t$hjust)) 0 else t$hjust,
               vjust = if (is.null(t$vjust)) 1 else t$vjust, angle = if (is.null(t$angle)) 0 else t$angle,
               typeset = flag(t$typeset))
  })
  legends <- lapply(spec$legends, function(l) {
    if (!is.null(l$mpl)) l <- .fig_mpl_legend(l, style)
    opt <- function(name, default = NULL) if (is.null(l[[name]])) default else l[[name]]
    at <- if (!is.null(l$xy)) frac_at(unlist(l$xy)) else unlist(l$at)
    if (!is.null(l$offset_mm)) at <- at + as.numeric(unlist(l$offset_mm))
    FigureGrob(LegendKeys(unlist(l$labels), .fig_colour(unlist(l$colours), style),
                          shape = if (is.null(l$shape)) "point" else unlist(l$shape),
                          ncol = if (is.null(l$ncol)) length(l$labels) else l$ncol,
                          size = l$size, key_mm = opt("key_mm", 2.2), marker_size = l$marker_size,
                          row_mm = l$row_mm, text_gap_mm = opt("text_gap_mm", 0.8),
                          column_gap_mm = opt("column_gap_mm", 0.8), byrow = opt("byrow", TRUE), linewidth = l$linewidth,
                          typeset = flag(l$typeset), style = style),
               at, hjust = opt("hjust", 0))
  })
  ComposeFigure(panels, height_mm = spec$height_mm, width_mm = spec$width_mm,
                texts = c(texts, legends), style = style)
}

#' Read a Figure Specification
#'
#' Reads one or more JSON specification files (or a directory of them) and
#' merges them as described in [RenderFigure()].
#'
#' @param paths JSON file paths or one directory.
#' @return The merged specification list.
#' @examples
#' if (requireNamespace("jsonlite", quietly = TRUE)) {
#'   dir <- tempfile("spec")
#'   dir.create(dir)
#'   writeLines('{"height_mm": 50, "panels": [{"box": [15, 10, 45, 30], "grammar": "group_strip",
#'     "data": "values"}]}', file.path(dir, "1-page.json"))
#'   writeLines('{"texts": [{"label": "Note", "at": [5, 48]}]}', file.path(dir, "2-texts.json"))
#'   str(ReadFigureSpec(dir), max.level = 1)
#'   unlink(dir, recursive = TRUE)
#' }
#' @export
ReadFigureSpec <- function(paths) .fig_read_spec(paths)

# Read one or more JSON specification files and merge them.
.fig_read_spec <- function(paths) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Reading a JSON specification needs 'jsonlite'.", call. = FALSE)
  if (length(paths) == 1L && dir.exists(paths)) {
    paths <- sort(list.files(paths, pattern = "\\.json$", full.names = TRUE))
  }
  if (!length(paths) || !all(file.exists(paths))) stop("Specification file(s) not found.", call. = FALSE)
  parts <- lapply(paths, jsonlite::read_json, simplifyVector = TRUE, simplifyDataFrame = FALSE,
                  simplifyMatrix = FALSE)
  out <- list(panels = list(), texts = list(), legends = list())
  for (x in parts) {
    for (field in setdiff(names(x), c("panels", "texts", "legends"))) {
      if (is.null(out[[field]])) out[[field]] <- x[[field]]
    }
    for (field in c("panels", "texts", "legends")) out[[field]] <- c(out[[field]], x[[field]])
  }
  out
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
#' @examples
#' values <- tempfile(fileext = ".tsv")
#' write.table(data.frame(group = rep(c("A", "B"), each = 3), value = c(1, 2, 3, 2, 3, 5)),
#'             values, sep = "\t", row.names = FALSE, quote = FALSE)
#' spec <- list(height_mm = 50, width_mm = 70, panels = list(
#'   list(box = c(15, 10, 45, 30), letter = "a", grammar = "group_strip", data = "values")))
#' if (capabilities("cairo")) {
#'   WriteFigure(spec, list(values = values), pdf = tempfile(fileext = ".pdf"),
#'               png = tempfile(fileext = ".png"))
#' }
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

# Resolve colour references inside builder arguments. The keyword "group"
# (colour by group, as in `label_colour`) is passed on unchanged.
.fig_resolve <- function(args, style) {
  colour_args <- grepl("(colour|color|fill|palette)s?$", names(args))
  args[colour_args] <- lapply(args[colour_args], function(v) {
    if (identical(v, "group")) v else .fig_colour(v, style = style)
  })
  args
}

.fig_colour <- function(x, style) {
  if (is.null(x)) return(NULL)
  if (is.list(x)) {
    out <- lapply(x, .fig_colour, style = style)
    flat <- all(vapply(out, function(v) is.character(v) && length(v) == 1L, logical(1)))
    return(if (flat) unlist(out) else out)
  }
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

#' Read a Plot Data Table
#'
#' Reads a tab-separated (optionally gzipped), comma-separated or RDS table
#' as a plain data frame with the column names unchanged, using one thread.
#' Empty strings and `NA` are missing values.
#'
#' @param path File path.
#' @return A data frame (or the RDS object).
#' @examples
#' f <- tempfile(fileext = ".tsv")
#' writeLines(c("patient\tvalue", "p1\t2.5"), f)
#' ReadPlotTable(f)
#' @export
ReadPlotTable <- function(path) {
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    stop("path must be an existing file.", call. = FALSE)
  }
  .fig_read_input(path)
}

# Translate the legend parameters of common plotting code (font size,
# marker size, handle length, paddings and spacings in font-size units,
# upper-left anchor at `xy`) into LegendKeys() layout options and an
# offset of the anchor in millimetres.
.fig_mpl_legend <- function(l, style) {
  m <- l$mpl
  get <- function(name, default) if (is.null(m[[name]])) default else as.numeric(m[[name]])
  fs <- if (is.null(l$size)) style$size$legend else l$size
  mm <- 25.4 / 72
  pad <- (get("borderaxespad", 0.5) + get("borderpad", 0.4)) * fs * mm
  row <- (1 + get("labelspacing", 0.5)) * fs * mm
  l$size <- fs
  l$key_mm <- get("handlelength", 2) * fs * mm
  l$text_gap_mm <- get("handletextpad", 0.8) * fs * mm
  l$column_gap_mm <- get("columnspacing", 2) * fs * mm
  l$row_mm <- row
  if (is.null(l$marker_size)) l$marker_size <- get("markersize", 6) + get("markeredgewidth", 1)
  if (is.null(l$byrow)) l$byrow <- FALSE
  # the first row centre lies half a font size below the padded top; a legend
  # anchored at its upper right corner ends at its last label
  right <- identical(m$loc, "upper right")
  l$hjust <- if (right) 1 else 0
  l$offset_mm <- c(if (right) -pad + l$column_gap_mm else pad, pad - (row - fs * mm) / 2)
  l
}
