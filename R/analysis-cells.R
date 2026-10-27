# Cell tables from NumPy archives and per-section summaries of them.

#' Read a Cell Table from a NumPy Archive
#'
#' Reads selected one-dimensional arrays of an `.npz` archive with
#' `cellspecR::cs_read_npz()` (pure R, no Python) into a data frame, keeping
#' the rows selected by an optional logical mask array.
#'
#' @param path Path to the `.npz` archive.
#' @param arrays Character vector of array names; names of the vector, when
#'   given, become the output column names.
#' @param keep Optional name of a logical array selecting the rows to keep.
#' @param row_id Name of the output column holding the 1-based row of each
#'   kept cell in the archive (before masking); `NULL` omits it.
#' @return A data frame with `row_id` and the selected arrays (32-bit floats
#'   become doubles, strings character, booleans logical).
#' @examples
#' if (requireNamespace("cellspecR", quietly = TRUE)) {
#'   f <- tempfile(fileext = ".npz")
#'   cellspecR::cs_write_npz(list(x_um = c(1, 2, 3), label = c("a", "b", "a"),
#'                                kept = c(TRUE, FALSE, TRUE)), f)
#'   ReadCellArrays(f, c(x = "x_um", type = "label"), keep = "kept")
#' }
#' @export
ReadCellArrays <- function(path, arrays, keep = NULL, row_id = "source_row") {
  .an_assert(requireNamespace("cellspecR", quietly = TRUE),
             "ReadCellArrays requires the cellspecR package")
  .an_assert(.an_name(path) && file.exists(path), "path must be an existing file")
  if (is.list(arrays)) arrays <- unlist(arrays)
  .an_assert(.an_names(unname(arrays), FALSE), "arrays must be distinct array names")
  .an_assert(is.null(keep) || .an_name(keep), "keep must be one array name")
  .an_assert(is.null(row_id) || .an_name(row_id), "Invalid row_id")
  out_names <- if (is.null(names(arrays))) arrays else ifelse(nzchar(names(arrays)), names(arrays), arrays)
  .an_assert(!anyDuplicated(c(out_names, row_id)), "Duplicate output column names")
  z <- cellspecR::cs_read_npz(path, arrays = unique(c(unname(arrays), keep)))
  .an_assert(all(c(arrays, keep) %in% names(z)), "Archive lacks requested arrays")
  n <- unique(vapply(z, length, integer(1)))
  .an_assert(length(n) == 1L && all(vapply(z, function(a) is.null(dim(a)), logical(1))),
             "Selected arrays must be one-dimensional with one length")
  mask <- rep(TRUE, n)
  if (!is.null(keep)) {
    mask <- z[[keep]]
    .an_assert(is.logical(mask) && !anyNA(mask), "keep must be a logical array without NA")
  }
  out <- lapply(unname(arrays), function(a) z[[a]][mask])
  names(out) <- out_names
  out <- as.data.frame(out, stringsAsFactors = FALSE, optional = TRUE)
  if (!is.null(row_id)) out <- cbind(stats::setNames(data.frame(which(mask)), row_id), out)
  out
}

.an_sets <- function(x, what) {
  if (is.null(names(x))) {
    x <- as.list(x)
    names(x) <- unlist(x)
  }
  .an_assert(is.list(x) || is.character(x), paste(what, "must name sets of labels"))
  x <- lapply(as.list(x), function(v) as.character(unlist(v)))
  .an_assert(.an_names(names(x), FALSE), paste(what, "needs distinct set names"))
  x
}

#' Nearest-Target Distances Summarised per Cell Set
#'
#' For each declared source set of cell types, finds the Euclidean distance
#' from every source cell to its nearest target cell (via [CrossNNDistance()])
#' and reports the number of source cells, the median distance and the
#' percentage (or fraction) within each radius (inclusive). Optionally adds
#' the summed area of all cells (for example Voronoi territories) as tissue
#' area.
#'
#' @param cells Cell table with coordinate and type columns.
#' @param from Named list (or named character vector) of source sets: output
#'   label to cell types. An unnamed character vector uses each type as its
#'   own set. Sets must be disjoint from each other and from `to`.
#' @param to Character vector of target cell types.
#' @param x,y,type Column names in `cells`.
#' @param radius Optional numeric radii; one output row per set and radius.
#' @param percent Report percentages (`TRUE`) or fractions.
#' @param area Optional column summed over all cells into `area`.
#' @param area_divisor Divisor applied to the summed area (e.g. `1e6` for
#'   square micrometres to square millimetres).
#' @return A data frame with `from`, `n`, `n_target`, `median_distance`,
#'   `radius`, `within` and optionally `area`.
#' @examples
#' set.seed(1)
#' cells <- data.frame(x = runif(200, 0, 100), y = runif(200, 0, 100),
#'                     type = sample(c("t", "a", "b"), 200, replace = TRUE))
#' SummarizeNearestDistances(cells, from = list(A = "a", B = "b"), to = "t",
#'                           radius = 10)
#' @export
SummarizeNearestDistances <- function(cells, from, to, x = "x", y = "y", type = "type",
                                      radius = NULL, percent = TRUE, area = NULL,
                                      area_divisor = 1) {
  .an_assert(all(vapply(list(x, y, type), .an_name, logical(1))), "Invalid columns")
  .an_require(cells, c(x, y, type, area), "cells")
  from <- .an_sets(from, "from")
  to <- as.character(unlist(to))
  .an_assert(length(to) > 0L, "to must name target types")
  all_from <- unlist(from, use.names = FALSE)
  .an_assert(!anyDuplicated(all_from) && !length(intersect(all_from, to)),
             "Source sets must be disjoint from each other and from the targets")
  .an_assert(is.null(radius) || (is.numeric(radius) && all(is.finite(radius))),
             "radius must be finite numbers")
  lab <- as.character(cells[[type]])
  .an_assert(!anyNA(lab), "Cell types must not be missing")
  xy <- cbind(as.numeric(cells[[x]]), as.numeric(cells[[y]]))
  .an_assert(all(is.finite(xy)), "Coordinates must be finite")
  target_label <- "\001target"
  phen <- rep("\001other", length(lab))
  phen[lab %in% to] <- target_label
  for (k in names(from)) phen[lab %in% from[[k]]] <- k
  n_target <- sum(phen == target_label)
  object <- NULL
  if (n_target > 0L && any(phen %in% names(from))) {
    keep <- phen != "\001other"
    object <- CreateSpatialObject(matrix(numeric(0), nrow = sum(keep), ncol = 0),
      data.frame(x = xy[keep, 1L], y = xy[keep, 2L]),
      data.frame(cell_id = as.character(which(keep)), sample_id = "section",
                 phenotype = phen[keep], stringsAsFactors = FALSE))
  }
  total_area <- if (is.null(area)) NULL else sum(as.numeric(cells[[area]])) / area_divisor
  rows <- lapply(names(from), function(k) {
    n <- sum(phen == k)
    d <- if (n > 0L && n_target > 0L) as.numeric(CrossNNDistance(object, k, target_label)) else numeric()
    med <- if (length(d)) stats::median(d) else NA_real_
    rr <- if (is.null(radius)) NA_real_ else radius
    within <- vapply(rr, function(r) {
      if (is.na(r) || !length(d)) return(NA_real_)
      (if (percent) 100 else 1) * mean(d <= r)
    }, numeric(1))
    out <- data.frame(from = k, n = n, n_target = n_target, median_distance = med,
                      radius = rr, within = within, stringsAsFactors = FALSE)
    if (!is.null(total_area)) out$area <- total_area
    out
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

#' Cell-Type Composition, Densities and Declared State Fractions of a Section
#'
#' Counts cells per registered type, expresses them as fractions of all cells
#' and as densities per unit area, and adds declared subset fractions such as
#' "marker-positive cells among cells of some types". Fractions are computed
#' from exact counts with [SummarizeGroupedCountFractions()].
#'
#' @param cells Cell table (one section).
#' @param type Cell-type column; every value must be in `levels`.
#' @param levels Character vector: the complete type registry (zero counts
#'   are reported).
#' @param area Optional column summed over all cells into the section area;
#'   adds density rows.
#' @param area_divisor Divisor applied to the summed area.
#' @param fractions Optional named list of subset fractions. Each element is a
#'   list with `numerator` (types), `denominator` (types) and optional `flag`
#'   (name of a logical or 0/1 column that numerator cells must have set).
#' @param percent Express fractions in percent.
#' @param prefix Named character vector with prefixes of the `fraction` and
#'   `density` endpoint names (followed by the type).
#' @param totals Named character vector: endpoint names of the `cells` and
#'   `area` totals.
#' @return A data frame with `endpoint`, `measure` (`"fraction"`, `"density"`,
#'   `"subset_fraction"` or `"total"`), `type` (for per-type rows), `numerator`,
#'   `denominator` and `value`.
#' @examples
#' cells <- data.frame(type = c("t", "t", "a", "b", "t"), pos = c(1, 0, 0, 1, 1),
#'                     area = c(10, 12, 9, 11, 8))
#' SummarizeCellComposition(cells, "type", c("t", "a", "b", "c"), area = "area",
#'   fractions = list("pos % t" = list(numerator = "t", denominator = "t",
#'                                     flag = "pos")))
#' @export
SummarizeCellComposition <- function(cells, type, levels, area = NULL, area_divisor = 1,
                                     fractions = NULL, percent = TRUE,
                                     prefix = c(fraction = "fraction|", density = "density|"),
                                     totals = c(cells = "cells", area = "area")) {
  .an_assert(.an_name(type) && .an_names(as.character(unlist(levels)), FALSE),
             "Invalid type column or levels")
  levels <- as.character(unlist(levels))
  prefix <- unlist(prefix)
  totals <- unlist(totals)
  .an_assert(all(c("fraction", "density") %in% names(prefix)) &&
               all(c("cells", "area") %in% names(totals)), "Invalid prefix or totals")
  flags <- unique(unlist(lapply(fractions, function(f) f$flag)))
  .an_require(cells, c(type, area, flags), "cells")
  lab <- as.character(cells[[type]])
  .an_assert(!anyNA(lab) && all(lab %in% levels), "Cell types outside the registry")
  n <- length(lab)
  count <- as.numeric(table(factor(lab, levels = levels)))
  scale <- if (percent) 100 else 1
  num <- count
  den <- rep(n, length(levels))
  endpoints <- paste0(prefix[["fraction"]], levels)
  if (!is.null(fractions)) {
    .an_assert(is.list(fractions) && .an_names(names(fractions), FALSE),
               "fractions must be a named list")
    for (k in names(fractions)) {
      f <- fractions[[k]]
      .an_assert(!is.null(f$numerator) && !is.null(f$denominator),
                 paste("Fraction", k, "needs numerator and denominator types"))
      hit <- lab %in% unlist(f$numerator)
      if (!is.null(f$flag)) {
        v <- cells[[f$flag]]
        .an_assert((is.logical(v) || is.numeric(v)) && !anyNA(v) && all(v %in% c(0, 1)),
                   paste("Flag", f$flag, "must be logical or 0/1"))
        hit <- hit & as.logical(v)
      }
      num <- c(num, sum(hit))
      den <- c(den, sum(lab %in% unlist(f$denominator)))
      endpoints <- c(endpoints, k)
    }
  }
  .an_assert(!anyDuplicated(endpoints), "Duplicate endpoint names")
  frac <- SummarizeGroupedCountFractions(
    data.frame(endpoint = endpoints, section = "s", numerator = num, denominator = den,
               stringsAsFactors = FALSE),
    "endpoint", "section", "numerator", "denominator")
  frac <- frac[match(endpoints, frac$endpoint), , drop = FALSE]
  out <- data.frame(endpoint = endpoints,
                    measure = c(rep("fraction", length(levels)),
                                rep("subset_fraction", length(endpoints) - length(levels))),
                    numerator = frac$numerator_total, denominator = frac$denominator_total,
                    value = scale * frac$fraction, stringsAsFactors = FALSE)
  extra <- data.frame(endpoint = totals[["cells"]], measure = "total", numerator = n,
                      denominator = NA_real_, value = n, stringsAsFactors = FALSE)
  if (!is.null(area)) {
    a <- as.numeric(cells[[area]])
    .an_assert(all(is.finite(a) & a >= 0), "Areas must be finite and nonnegative")
    total <- sum(a) / area_divisor
    density <- data.frame(endpoint = paste0(prefix[["density"]], levels), measure = "density",
                          numerator = count, denominator = total, value = count / total,
                          stringsAsFactors = FALSE)
    out <- rbind(out, density)
    extra <- rbind(extra, data.frame(endpoint = totals[["area"]], measure = "total",
                                     numerator = NA_real_, denominator = NA_real_,
                                     value = total, stringsAsFactors = FALSE))
  }
  out <- rbind(out, extra)
  out$type <- NA_character_
  out$type[out$measure %in% c("fraction", "density")] <- c(levels, if (!is.null(area)) levels)
  out <- out[c("endpoint", "measure", "type", "numerator", "denominator", "value")]
  rownames(out) <- NULL
  out
}
