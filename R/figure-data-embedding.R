# Plot-data builders for embeddings (for example a frozen UMAP with
# clusters): display limits, layered and shuffled
# point data, cluster label positions, per-group density levels and the
# lookup of per-cell values stored on nested subsets of rows.

# Evaluate with a fixed seed of R's default generator and restore the
# caller's random number state afterwards.
.figb_with_seed <- function(seed, expr) {
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  on.exit({
    if (had) assign(".Random.seed", old, envir = globalenv()) else
      if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) rm(".Random.seed", envir = globalenv())
  }, add = TRUE)
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")
  force(expr)
}

#' Display Limits of an Embedding
#'
#' Limits enclosing the central part of the points plus a margin: the
#' `probs` quantiles of each coordinate (type 7, linear interpolation)
#' widened by `pad` times their span on both sides.
#'
#' @param data Data frame with coordinates.
#' @param x,y Coordinate columns.
#' @param filter Optional named list of columns and values selecting the
#'   points used.
#' @param probs Lower and upper quantile.
#' @param pad Margin as a fraction of the quantile span.
#' @return A one-row data frame with `xmin`, `xmax`, `ymin`, `ymax`.
#' @examples
#' EmbeddingLimits(data.frame(x = 1:100, y = (1:100)^2))
#' @export
EmbeddingLimits <- function(data, x = "x", y = "y", filter = NULL, probs = c(0.0005, 0.9995), pad = 0.04) {
  .fig_require_columns(data, c(x, y))
  ok <- .fig_filter_rows(data, filter)
  qx <- stats::quantile(as.numeric(data[[x]][ok]), probs, names = FALSE, type = 7)
  qy <- stats::quantile(as.numeric(data[[y]][ok]), probs, names = FALSE, type = 7)
  px <- pad * diff(qx)
  py <- pad * diff(qy)
  data.frame(xmin = qx[1] - px, xmax = qx[2] + px, ymin = qy[1] - py, ymax = qy[2] + py)
}

#' Layered Point Data for an Embedding
#'
#' Stacks the points of several layers in drawing order: each layer selects
#' rows by column values, takes its key either as a fixed name or from a
#' column, and may be put in random order (for example so that no cell type
#' is systematically drawn on top). The random order is a permutation from
#' R's default generator after `set.seed(seed)`; the caller's random state
#' is left unchanged.
#'
#' @param data Data frame with coordinates.
#' @param x,y Coordinate columns.
#' @param layers List of layers, each a list with `filter` (named list of
#'   columns and values), `key` (fixed key) or `key_from` (column holding
#'   the key), optional `recode` (named mapping of keys) and `shuffle`.
#' @param carry Further columns copied to the output.
#' @param seed Seed for shuffled layers.
#' @return A data frame with `x`, `y`, `key`, `layer` and the carried
#'   columns, in drawing order.
#' @examples
#' d <- data.frame(u = 1:6, v = 6:1, type = c("a", "b", "a", "c", "b", "a"), kept = TRUE)
#' EmbeddingLayers(d, "u", "v", layers = list(
#'   list(filter = list(kept = TRUE), key = "background"),
#'   list(filter = list(type = "a"), key_from = "type", shuffle = TRUE)), seed = 1)
#' @export
EmbeddingLayers <- function(data, x = "x", y = "y", layers, carry = NULL, seed = NULL) {
  .fig_require_columns(data, c(x, y, unlist(carry)))
  if (!is.list(layers) || !length(layers)) stop("layers must be a non-empty list.", call. = FALSE)
  if (!is.null(layers$filter) || !is.null(layers$key) || !is.null(layers$key_from)) layers <- list(layers)
  parts <- lapply(seq_along(layers), function(i) {
    l <- layers[[i]]
    ok <- .fig_filter_rows(data, l$filter)
    idx <- which(ok)
    if (isTRUE(l$shuffle) && length(idx) > 1L) {
      if (is.null(seed)) stop("Shuffled layers need a seed.", call. = FALSE)
      idx <- idx[.figb_with_seed(seed + i - 1L, sample.int(length(idx)))]
    }
    key <- if (!is.null(l$key_from)) as.character(data[[l$key_from]][idx]) else rep(as.character(l$key), length(idx))
    if (!is.null(l$recode)) {
      map <- unlist(l$recode)
      hit <- key %in% names(map)
      key[hit] <- unname(map[key[hit]])
    }
    out <- data.frame(x = as.numeric(data[[x]][idx]), y = as.numeric(data[[y]][idx]), key = key,
                      layer = rep(i, length(idx)), stringsAsFactors = FALSE)
    for (cc in unlist(carry)) out[[cc]] <- data[[cc]][idx]
    out
  })
  out <- do.call(rbind, parts)
  rownames(out) <- NULL
  out
}

#' Label Positions of Clusters on an Embedding
#'
#' The median position of the points of each cluster with at least
#' `min_points` points, for numbering clusters on the embedding.
#'
#' @param data Data frame with coordinates and a cluster column.
#' @param x,y,cluster Column names.
#' @param filter Optional named list of columns and values selecting the
#'   points used.
#' @param min_points Smallest cluster that gets a label.
#' @return A data frame with `label`, `x`, `y` and `n`, ordered by cluster.
#' @examples
#' d <- data.frame(x = c(1, 2, 3, 10), y = c(1, 1, 2, 5), cl = c(1, 1, 1, 2))
#' ClusterLabelPositions(d, cluster = "cl", min_points = 2)
#' @export
ClusterLabelPositions <- function(data, x = "x", y = "y", cluster = "cluster", filter = NULL, min_points = 150) {
  .fig_require_columns(data, c(x, y, cluster))
  ok <- .fig_filter_rows(data, filter)
  cl <- data[[cluster]][ok]
  lev <- sort(unique(cl))
  out <- lapply(lev, function(k) {
    m <- cl == k
    data.frame(label = as.character(k), x = stats::median(data[[x]][ok][m]),
               y = stats::median(data[[y]][ok][m]), n = sum(m))
  })
  out <- do.call(rbind, out)
  out <- out[out$n >= min_points, , drop = FALSE]
  rownames(out) <- NULL
  out
}

# Gaussian smoothing of a matrix along both axes with mirror ("reflect")
# boundaries: kernel exp(-k^2 / (2 sigma^2)) on |k| <= truncate * sigma
# (rounded), normalised; each output value is accumulated as the centre
# term plus symmetric pairs, outwards.
.figb_gaussian_smooth <- function(m, sigma = 2, truncate = 4) {
  r <- as.integer(truncate * sigma + 0.5)
  k <- -r:r
  w <- exp(-0.5 / sigma^2 * k^2)
  w <- w / sum(w)
  wc <- w[r + 1L]
  wp <- w[(r + 2L):(2L * r + 1L)]
  reflect <- function(i, n) {
    # period 2n mirror including the edge sample
    i <- (i - 1L) %% (2L * n)
    ifelse(i < n, i + 1L, 2L * n - i)
  }
  smooth_rows <- function(a) {
    n <- nrow(a)
    out <- wc * a
    for (j in seq_len(r)) out <- out + wp[j] * (a[reflect(seq_len(n) - j, n), , drop = FALSE] +
                                                  a[reflect(seq_len(n) + j, n), , drop = FALSE])
    out
  }
  t(smooth_rows(t(smooth_rows(m))))
}

#' Density Level Region of Each Group on an Embedding
#'
#' For each group (for example each patient), counts the points in a
#' `bins` x `bins` histogram over the display limits, smooths the counts with
#' a Gaussian kernel of `sigma` bins (mirror boundaries, kernel truncated at
#' `truncate` sigma), and finds the density level whose superlevel region
#' holds the fraction `level` of the smoothed mass: the smallest bin value
#' that is still needed when bins are added from the highest down until
#' their sum reaches `level` times the total. The region above that level is
#' returned as filled bands and outline paths on the bin centres.
#'
#' @param data Data frame with coordinates and a group column.
#' @param x,y,group Column names.
#' @param limits Display limits `c(xmin, xmax, ymin, ymax)` or a data frame
#'   from [EmbeddingLimits()]; the histogram spans them exactly.
#' @param filter Optional named list of columns and values selecting the
#'   points used.
#' @param bins Bins per axis.
#' @param sigma Kernel standard deviation in bins.
#' @param level Fraction of the smoothed mass inside the region.
#' @param truncate Kernel half-width in standard deviations.
#' @param groups Optional group order (also the order of slots).
#' @param carry Columns constant within a group copied to the output (for
#'   example the clinical group).
#' @param slot_within Optional carried column: slots count groups within
#'   each of its values (for example patients within a clinical group).
#' @param label_from,label_sub Column for the key label (default the
#'   group) and an optional regular expression replacement `c(pattern,
#'   replacement)` applied to it.
#' @return A data frame with the group column (named as in `data`), `slot`,
#'   `label`, carried columns,
#'   `kind` (`"band"`, `"line"`), `piece`, `x`, `y`, `level` (the density
#'   level) and `n` (points of the group).
#' @examples
#' set.seed(3)
#' d <- data.frame(x = rnorm(400), y = rnorm(400), g = rep(c("a", "b"), 200))
#' head(DensityLevelContour(d, group = "g", limits = c(-4, 4, -4, 4), bins = 30))
#' @export
DensityLevelContour <- function(data, x = "x", y = "y", group = "group", limits, filter = NULL, bins = 90,
                                sigma = 2, level = 0.9, truncate = 4, groups = NULL, carry = NULL,
                                slot_within = NULL, label_from = NULL, label_sub = NULL) {
  if (!requireNamespace("isoband", quietly = TRUE)) stop("DensityLevelContour() needs 'isoband'.", call. = FALSE)
  .fig_require_columns(data, c(x, y, group, unlist(carry), label_from))
  if (any(unlist(carry) %in% c(group, "slot", "label", "kind", "piece", "x", "y", "level", "n"))) {
    stop("Carried columns must not reuse output column names.", call. = FALSE)
  }
  lim <- .figb_limits(limits)
  ok <- .fig_filter_rows(data, filter)
  d <- data[ok, , drop = FALSE]
  groups <- .figb_levels(groups, d[[group]])
  groups <- groups[groups %in% as.character(d[[group]])]
  xe <- seq(lim[1], lim[2], length.out = bins + 1L)
  ye <- seq(lim[3], lim[4], length.out = bins + 1L)
  xc <- (xe[-1L] + xe[-(bins + 1L)]) / 2
  yc <- (ye[-1L] + ye[-(bins + 1L)]) / 2
  info <- data.frame(.group = groups, stringsAsFactors = FALSE)
  for (cc in unlist(carry)) info[[cc]] <- d[[cc]][match(groups, as.character(d[[group]]))]
  info$slot <- if (is.null(slot_within)) seq_along(groups) else stats::ave(seq_along(groups), info[[slot_within]], FUN = seq_along)
  lab <- if (is.null(label_from)) groups else as.character(d[[label_from]][match(groups, as.character(d[[group]]))])
  if (!is.null(label_sub)) lab <- sub(label_sub[[1]], label_sub[[2]], lab)
  info$label <- lab
  out <- lapply(seq_along(groups), function(k) {
    g <- groups[k]
    m <- as.character(d[[group]]) == g
    px <- as.numeric(d[[x]][m])
    py <- as.numeric(d[[y]][m])
    ix <- findInterval(px, xe, rightmost.closed = TRUE)
    iy <- findInterval(py, ye, rightmost.closed = TRUE)
    inside <- ix >= 1L & ix <= bins & iy >= 1L & iy <= bins
    h <- matrix(tabulate(ix[inside] + bins * (iy[inside] - 1L), nbins = bins * bins), bins, bins)
    z <- .figb_gaussian_smooth(h, sigma, truncate)
    v <- sort(as.vector(z), decreasing = TRUE)
    lev <- v[which(cumsum(v) >= level * sum(v))[1L]]
    band <- isoband::isobands(xc, yc, t(z), lev, max(z) + 1e-9)[[1L]]
    line <- isoband::isolines(xc, yc, t(z), lev)[[1L]]
    parts <- list()
    if (length(band$x)) parts$band <- data.frame(kind = "band", piece = band$id, x = band$x, y = band$y)
    if (length(line$x)) parts$line <- data.frame(kind = "line", piece = line$id, x = line$x, y = line$y)
    r <- do.call(rbind, parts)
    if (is.null(r)) r <- data.frame(kind = character(), piece = integer(), x = numeric(), y = numeric())
    r$level <- rep(lev, nrow(r))
    r$n <- rep(sum(m), nrow(r))
    cbind(info[rep(k, nrow(r)), , drop = FALSE], r)
  })
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out <- out[, c(".group", "slot", "label", setdiff(names(info), c(".group", "slot", "label")), "kind", "piece", "x", "y",
                 "level", "n")]
  names(out)[1] <- group
  out
}

#' Look Up Values Stored on Nested Row Subsets
#'
#' Per-cell results are often stored only for a subset of a subset of the
#' rows of a sample (for example neighbourhood labels for the defined cells
#' among the counted cells). For records that refer to rows of the full
#' sample table, this returns the stored value, or `missing` where the row
#' lies outside the subsets.
#'
#' @param data Data frame of records with a sample and a row column.
#' @param sample,row Column names; rows are counted from `base`.
#' @param outer List (one entry per sample, in the order of `samples`) of
#'   logical vectors over all rows, or lists holding such a vector named
#'   `outer_name`.
#' @param inner List of logical vectors over the outer rows, or lists
#'   holding one named `inner_name` together with the values `value_name`.
#' @param values Optional list of value vectors over the inner rows (default
#'   taken from `inner`).
#' @param samples Sample names matching the entries of the lists.
#' @param outer_name,inner_name,value_name Element names inside list
#'   entries.
#' @param missing Value for rows outside the subsets.
#' @param base Index of the first row (0 for arrays from Python).
#' @param to Name of the new column.
#' @return `data` with the new column.
#' @examples
#' d <- data.frame(s = c("a", "a", "b"), r = c(0, 2, 1))
#' LookupNestedRows(d, "s", "r", outer = list(c(TRUE, FALSE, TRUE), c(TRUE, TRUE)),
#'                  inner = list(c(TRUE, TRUE), c(FALSE, TRUE)),
#'                  values = list(c(5L, 6L), 7L), samples = c("a", "b"))
#' @export
LookupNestedRows <- function(data, sample = "sample", row = "row", outer, inner, values = NULL, samples,
                             outer_name = "counted", inner_name = "defined_rows", value_name = "cn",
                             missing = -1L, base = 0L, to = "value") {
  .fig_require_columns(data, c(sample, row))
  samples <- as.character(unlist(samples))
  if (length(outer) != length(samples) || length(inner) != length(samples)) {
    stop("outer and inner need one entry per sample.", call. = FALSE)
  }
  pick <- function(x, name) if (is.list(x)) x[[name]] else x
  res <- rep(missing, nrow(data))
  for (k in seq_along(samples)) {
    o <- as.logical(pick(outer[[k]], outer_name))
    inn <- as.logical(pick(inner[[k]], inner_name))
    val <- if (is.null(values)) pick(inner[[k]], value_name) else values[[k]]
    if (sum(o) != length(inn)) stop("Inner subset of sample '", samples[k], "' does not match its outer rows.", call. = FALSE)
    if (sum(inn) != length(val)) stop("Values of sample '", samples[k], "' do not match its inner rows.", call. = FALSE)
    full <- rep(missing, length(o))
    full[which(o)[inn]] <- val
    m <- as.character(data[[sample]]) == samples[k]
    r <- as.integer(data[[row]][m]) - base + 1L
    if (any(r < 1L | r > length(o))) stop("Rows out of range for sample '", samples[k], "'.", call. = FALSE)
    res[m] <- full[r]
  }
  data[[to]] <- res
  data
}
