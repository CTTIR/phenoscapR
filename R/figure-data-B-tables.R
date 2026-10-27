# Plot-data builders for matrices and bars: shares within groups, cluster
# order by dominant category, column means, recoding, joins, row ranks,
# annotation tracks, alteration matrices and simple counts. Values are
# rearranged or summarised; no tests are computed here.

#' Shares of One Category within Another
#'
#' Cross-tabulates two columns and returns every combination with its count,
#' the total of its row category and the share of the row total (for
#' example the cell-type composition of each cluster, or the neighbourhoods
#' of the cells of each cluster).
#'
#' @param data Data frame.
#' @param row,column Column names.
#' @param keep Optional named list of columns and values selecting records.
#' @param rows,columns Optional level sets (and order); default the sorted
#'   values present.
#' @param scale Multiplier of the share (100 for percentages).
#' @return A data frame with `row`, `column` (named as the inputs), `n`,
#'   `total` and `share`.
#' @examples
#' d <- data.frame(cl = c(1, 1, 2, 2, 2), type = c("a", "b", "a", "a", "c"))
#' CrossShares(d, "cl", "type")
#' @export
CrossShares <- function(data, row, column, keep = NULL, rows = NULL, columns = NULL, scale = 100) {
  .fig_require_columns(data, c(row, column))
  ok <- .figb_keep(data, keep)
  r <- as.character(data[[row]][ok])
  cc <- as.character(data[[column]][ok])
  srt <- function(v) {
    u <- unique(v)
    num <- suppressWarnings(as.numeric(u))
    if (!anyNA(num)) u[order(num)] else sort(u)
  }
  rows <- if (is.null(rows)) srt(r) else .figb_levels(rows, r)
  columns <- if (is.null(columns)) srt(cc) else .figb_levels(columns, cc)
  tab <- table(factor(r, levels = rows), factor(cc, levels = columns))
  out <- data.frame(a = rep(rows, times = length(columns)), b = rep(columns, each = length(rows)),
                    n = as.vector(tab), stringsAsFactors = FALSE)
  tot <- rowSums(tab)
  out$total <- unname(tot[out$a])
  out$share <- ifelse(out$total > 0, scale * out$n / out$total, NA_real_)
  names(out)[1:2] <- c(row, column)
  out[order(match(out[[row]], rows), match(out[[column]], columns)), , drop = FALSE] -> out
  rownames(out) <- NULL
  out
}

#' Order Groups by Their Dominant Category
#'
#' For each row group of a share table (from [CrossShares()]), finds the
#' category with the largest share (ties go to the earlier category in
#' `columns`) and orders the groups by the position of that category in
#' `priority`, then by the group value. Categories missing from `priority`
#' take position zero, before all listed ones.
#'
#' @param data Long share table.
#' @param row,column,value Column names.
#' @param columns Category order used to break ties.
#' @param priority Category order defining the group order.
#' @return A data frame with the group, `dominant`, `dominant_share` and
#'   `rank`, sorted by rank.
#' @examples
#' s <- CrossShares(data.frame(cl = c(1, 1, 2, 3), type = c("b", "b", "a", "b")), "cl", "type")
#' RankByDominant(s, "cl", "type", "share", columns = c("a", "b"), priority = c("a", "b"))
#' @export
RankByDominant <- function(data, row, column, value = "share", columns = NULL, priority = NULL) {
  .fig_require_columns(data, c(row, column, value))
  columns <- .figb_levels(columns, data[[column]])
  priority <- if (is.null(priority)) columns else as.character(unlist(priority))
  groups <- unique(as.character(data[[row]]))
  dom <- vapply(groups, function(g) {
    s <- data[as.character(data[[row]]) == g, , drop = FALSE]
    s <- s[order(match(as.character(s[[column]]), columns)), , drop = FALSE]
    s <- s[as.character(s[[column]]) %in% columns, , drop = FALSE]
    as.character(s[[column]][which.max(as.numeric(s[[value]]))])
  }, character(1))
  dshare <- vapply(seq_along(groups), function(i) {
    s <- data[as.character(data[[row]]) == groups[i] & as.character(data[[column]]) == dom[i], value]
    as.numeric(s[1])
  }, numeric(1))
  pos <- match(dom, priority)
  pos[is.na(pos)] <- 0L
  gnum <- suppressWarnings(as.numeric(groups))
  o <- if (!anyNA(gnum)) order(pos, gnum) else order(pos, groups)
  out <- data.frame(g = groups[o], dominant = unname(dom[o]), dominant_share = dshare[o], rank = seq_along(o),
                    stringsAsFactors = FALSE)
  names(out)[1] <- row
  out
}

#' Column Summaries by Group
#'
#' Means (or another summary) of several numeric columns within groups, in
#' long form: one row per group and column.
#'
#' @param data Data frame.
#' @param by Grouping column(s); none for one overall group.
#' @param columns Columns to summarise.
#' @param keep Optional named list selecting records.
#' @param fun `"mean"`, `"median"` or `"sum"`.
#' @param names_to,values_to Names of the column-name and value columns.
#' @return A data frame with the `by` columns, `names_to` and `values_to`;
#'   groups in sorted order, columns in the given order.
#' @examples
#' SummariseColumns(data.frame(g = c(1, 1, 2), a = 1:3, b = c(2, 4, 8)), "g", c("a", "b"))
#' @export
SummariseColumns <- function(data, by = NULL, columns, keep = NULL, fun = c("mean", "median", "sum"),
                             names_to = "feature", values_to = "value") {
  fun <- match.arg(fun)
  by <- as.character(unlist(by))
  columns <- as.character(unlist(columns))
  .fig_require_columns(data, c(by, columns))
  ok <- .figb_keep(data, keep)
  d <- data[ok, , drop = FALSE]
  f <- switch(fun, mean = mean, median = stats::median, sum = sum)
  if (length(by)) {
    grp <- d[by]
    o <- do.call(order, unname(as.list(grp)))
    key <- do.call(paste, c(grp, sep = "\r"))
    lev <- unique(key[o])
    first <- d[match(lev, key), by, drop = FALSE]
  } else {
    key <- rep("all", nrow(d))
    lev <- "all"
    first <- data.frame(row.names = 1)
  }
  out <- do.call(rbind, lapply(columns, function(cc) {
    v <- as.numeric(d[[cc]])
    r <- first
    r[[names_to]] <- rep(cc, length(lev))
    r[[values_to]] <- vapply(lev, function(k) f(v[key == k]), numeric(1))
    r
  }))
  rownames(out) <- NULL
  out
}

#' Product of Columns
#'
#' Multiplies columns row by row, divides by a constant and optionally
#' rounds (half to even), for example a count from a total and a
#' percentage.
#'
#' @param data Data frame.
#' @param columns Columns to multiply, in order.
#' @param divide Divisor applied after the product.
#' @param round Round to whole numbers.
#' @param to Output column.
#' @return `data` with the new column.
#' @examples
#' MultiplyColumns(data.frame(n = c(44, 2), pct = c(54.5454545, 50)), c("n", "pct"), divide = 100,
#'                 round = TRUE, to = "k")
#' @export
MultiplyColumns <- function(data, columns, divide = 1, round = FALSE, to = "value") {
  columns <- as.character(unlist(columns))
  .fig_require_columns(data, columns)
  v <- as.numeric(data[[columns[1]]])
  for (cc in columns[-1]) v <- v * as.numeric(data[[cc]])
  v <- v / divide
  data[[to]] <- if (isTRUE(round)) round(v) else v
  data
}

#' Recode a Column
#'
#' Maps the values of a column by an exact mapping, then by regular
#' expressions, then by position in a list of names (codes counted from
#' `index_base`), with a default for everything else. An optional regular
#' expression first extracts the part of each value that is looked up.
#'
#' @param data Data frame.
#' @param column Column to recode.
#' @param map Named mapping from old to new values.
#' @param patterns Named mapping from regular expressions to new values,
#'   tried in order for values not in `map`.
#' @param index Optional names (vector, or data frame whose first column is
#'   used) for integer codes.
#' @param index_base Code of the first name.
#' @param extract Optional regular expression with one group; the group is
#'   looked up instead of the full value.
#' @param default Value for unmatched entries; default keeps them.
#' @param to Output column (default `column`).
#' @return `data` with the recoded column.
#' @examples
#' d <- data.frame(g = c("TME-A (x)", "TME-B (y)"), cn = c(0, 2))
#' RecodeColumn(d, "g", patterns = c("^TME-A" = "1"), default = "2", to = "label")
#' RecodeColumn(d, "cn", index = c("first", "second", "third"))
#' @export
RecodeColumn <- function(data, column, map = NULL, patterns = NULL, index = NULL, index_base = 0L,
                         extract = NULL, default = NULL, to = column) {
  .fig_require_columns(data, column)
  v <- data[[column]]
  key <- as.character(v)
  if (!is.null(extract)) key <- ifelse(grepl(extract, key, perl = TRUE), sub(extract, "\\1", key, perl = TRUE), key)
  out <- rep(NA_character_, length(v))
  if (!is.null(map)) {
    map <- unlist(map)
    hit <- key %in% names(map)
    out[hit] <- unname(map[key[hit]])
  }
  if (!is.null(patterns)) {
    patterns <- unlist(patterns)
    for (rx in names(patterns)) {
      hit <- is.na(out) & grepl(rx, key, perl = TRUE)
      out[hit] <- patterns[[rx]]
    }
  }
  if (!is.null(index)) {
    nm <- if (is.data.frame(index)) as.character(index[[1L]]) else as.character(unlist(index))
    code <- suppressWarnings(as.integer(as.numeric(key))) - as.integer(index_base) + 1L
    hit <- is.na(out) & !is.na(code) & code >= 1L & code <= length(nm)
    out[hit] <- nm[code[hit]]
  }
  miss <- is.na(out)
  out[miss] <- if (is.null(default)) as.character(v)[miss] else default
  data[[to]] <- out
  data
}

#' Join Columns of Another Table
#'
#' Adds columns of `other` to `data` by matching key columns (a left join
#' that keeps the rows and their order).
#'
#' @param data,other Data frames.
#' @param by Key column, or a named pair `c(data_key = "other_key")`.
#' @param columns Columns of `other` to add; a named vector renames them.
#' @return `data` with the added columns.
#' @examples
#' JoinColumns(data.frame(p = c("a", "b", "a")), data.frame(id = c("a", "b"), area = c(6, 12)),
#'             by = c(p = "id"), columns = "area")
#' @export
JoinColumns <- function(data, other, by, columns) {
  by <- unlist(by)
  left <- if (is.null(names(by)) || !nzchar(names(by)[1])) by[[1]] else names(by)[1]
  right <- by[[1]]
  columns <- unlist(columns)
  new <- if (is.null(names(columns))) columns else ifelse(nzchar(names(columns)), names(columns), columns)
  .fig_require_columns(data, left)
  .fig_require_columns(other, c(right, columns), "other")
  i <- match(as.character(data[[left]]), as.character(other[[right]]))
  for (k in seq_along(columns)) data[[new[k]]] <- other[[columns[k]]][i]
  data
}

#' Rank Rows by the Sum of Selected Columns
#'
#' Sums the columns named in `columns` or matching `pattern` in each row and
#' ranks the rows (rank 1 = largest sum by default; ties keep the row order).
#'
#' @param data Wide data frame with one row per item.
#' @param id Identifier column.
#' @param columns Columns to add up.
#' @param pattern Regular expression selecting further columns.
#' @param decreasing Rank the largest sum first.
#' @param keep Optional identifiers to keep (others are dropped).
#' @return A data frame with `id`, `value` and `rank`, sorted by rank.
#' @examples
#' d <- data.frame(p = c("a", "b", "c"), "CN1 T" = c(10, 40, 20), check.names = FALSE)
#' RankRows(d, "p", pattern = "^CN1 ")
#' @export
RankRows <- function(data, id, columns = NULL, pattern = NULL, decreasing = TRUE, keep = NULL) {
  .fig_require_columns(data, c(id, unlist(columns)))
  cols <- unique(c(unlist(columns), if (!is.null(pattern)) grep(pattern, names(data), value = TRUE, perl = TRUE)))
  if (!length(cols)) stop("No columns selected.", call. = FALSE)
  if (!is.null(keep)) data <- data[as.character(data[[id]]) %in% .figb_levels(keep, NULL), , drop = FALSE]
  v <- rowSums(as.matrix(data[, cols, drop = FALSE]))
  o <- order(if (decreasing) -v else v)
  out <- data.frame(id = as.character(data[[id]])[o], value = unname(v[o]), rank = seq_along(o),
                    stringsAsFactors = FALSE)
  names(out)[1] <- id
  out
}

#' Wide Columns to Long Rows by Pattern
#'
#' Stacks all columns whose names match `pattern` (or all non-identifier
#' columns) into one row per identifier and column, keeping the column
#' order of the table.
#'
#' @param data Data frame.
#' @param id Identifier columns kept on every row.
#' @param pattern Regular expression selecting the value columns; default
#'   all other columns.
#' @param exclude Columns never stacked.
#' @param names_to,values_to Names of the new columns.
#' @return A data frame.
#' @examples
#' ColumnsToLong(data.frame(p = c("a", "b"), CN1 = 1:2, CN2 = 3:4, g = "x"), c("p", "g"), "^CN")
#' @export
ColumnsToLong <- function(data, id, pattern = NULL, exclude = NULL, names_to = "name", values_to = "value") {
  id <- as.character(unlist(id))
  .fig_require_columns(data, id)
  cols <- setdiff(names(data), c(id, unlist(exclude)))
  if (!is.null(pattern)) cols <- grep(pattern, cols, value = TRUE, perl = TRUE)
  if (!length(cols)) stop("No value columns selected.", call. = FALSE)
  PlotDataLonger(data, id, cols, names_to = names_to, values_to = values_to)
}

#' Coloured Annotation Tracks
#'
#' Builds categorical annotation tracks (for example clinical group,
#' co-mutation, architecture) for a set of items: each track takes a value
#' column, maps values to colours by exact values or regular expressions and
#' uses a default colour otherwise.
#'
#' @param data Data frame with one row per item.
#' @param id Identifier column.
#' @param tracks List of tracks: `name`, `column`, `colours` (named mapping
#'   value to colour), optional `patterns` (named mapping regular expression
#'   to colour) and `default`. Colours may be hex values or palette entries
#'   such as `"groups/group1"`.
#' @param style A [ManuscriptStyle()] object resolving palette entries.
#' @return A long data frame with `id`, `track`, `value`, `colour` and
#'   `track_rank`.
#' @examples
#' d <- data.frame(p = c("a", "b"), grp = c("x", "y"), mut = c("yes", "no"))
#' AnnotationTracks(d, "p", list(
#'   list(name = "Group", column = "grp", colours = c(x = "groups/group1", y = "groups/group2")),
#'   list(name = "Mutation", column = "mut", colours = c(yes = "#222222"), default = "#E0E0E0")))
#' @export
AnnotationTracks <- function(data, id, tracks, style = ManuscriptStyle()) {
  .fig_require_columns(data, id)
  if (!is.null(tracks$name)) tracks <- list(tracks)
  out <- lapply(seq_along(tracks), function(k) {
    t <- tracks[[k]]
    .fig_require_columns(data, t$column)
    v <- as.character(data[[t$column]])
    col <- rep(NA_character_, length(v))
    if (!is.null(t$colours)) {
      map <- unlist(t$colours)
      hit <- v %in% names(map)
      col[hit] <- unname(map[v[hit]])
    }
    if (!is.null(t$patterns)) {
      pats <- unlist(t$patterns)
      for (rx in names(pats)) {
        hit <- is.na(col) & grepl(rx, v, perl = TRUE)
        col[hit] <- pats[[rx]]
      }
    }
    col[is.na(col)] <- if (is.null(t$default)) "#E0E0E0" else t$default
    data.frame(id = as.character(data[[id]]), track = t$name, value = v,
               colour = .fig_colour(col, style), track_rank = k, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, out)
  names(out)[1] <- id
  rownames(out) <- NULL
  out
}

#' Alteration Classes for an Alteration Matrix
#'
#' Turns a gene-by-sample table of alteration types (several types joined by
#' a separator) into one class per gene and item: types are mapped to
#' classes (for example nonsense, frameshift and splice variants to
#' "Truncating"), and a gene with more than one class in a sample is
#' "Multiple". Genes are selected and ordered as `first`, then genes altered
#' in at least `min_count` samples by decreasing count (ties in table
#' order), then `last`.
#'
#' @param matrix Data frame: gene column and one column per sample; empty
#'   or missing entries mean no alteration.
#' @param gene Gene column (default the first column).
#' @param ids Items (columns of the plot) in order: vector or data frame
#'   ordered by `rank`.
#' @param id_map Optional data frame mapping items to sample columns.
#' @param map_from,map_to Columns of `id_map`.
#' @param first,last Genes always shown first and last.
#' @param min_count Smallest number of altered samples for other genes.
#' @param classes Named list: class to the types it collects; other types
#'   keep their name.
#' @param multiple Class of genes with several classes in one sample.
#' @param separator Separator of several types in one entry.
#' @return A long data frame with `gene`, `id`, `class` (missing if none),
#'   `count` (altered samples of the gene in the table), `percent` (count
#'   relative to the number of items) and `gene_rank`.
#' @examples
#' m <- data.frame(gene = c("G1", "G2"), S1 = c("Missense", ""), S2 = c("Nonsense|Missense", "Deletion"))
#' AlterationMatrixData(m, ids = c("S1", "S2"), min_count = 1)
#' @export
AlterationMatrixData <- function(matrix, gene = NULL, ids, id_map = NULL, map_from = NULL, map_to = NULL,
                                 first = NULL, last = NULL, min_count = 1,
                                 classes = list(Truncating = c("Nonsense", "Frameshift", "Splice")),
                                 multiple = "Multiple", separator = "|") {
  matrix <- as.data.frame(matrix, check.names = FALSE)
  if (is.null(gene)) gene <- names(matrix)[1L]
  ids <- .figb_levels(ids, NULL)
  cols <- if (is.null(id_map)) ids else {
    .fig_require_columns(id_map, c(map_from, map_to), "id_map")
    as.character(id_map[[map_to]][match(ids, as.character(id_map[[map_from]]))])
  }
  if (anyNA(cols) || !all(cols %in% names(matrix))) stop("Some items have no column in the matrix.", call. = FALSE)
  genes_all <- as.character(matrix[[gene]])
  vals <- as.matrix(matrix[, setdiff(names(matrix), gene), drop = FALSE])
  vals[!is.na(vals) & !nzchar(trimws(vals))] <- NA
  counts <- stats::setNames(rowSums(!is.na(vals)), genes_all)
  cand <- genes_all[counts >= min_count]
  cand <- cand[order(-counts[cand], match(cand, genes_all))]
  genes <- unique(c(unlist(first), cand, unlist(last)))
  cls_of <- function(v) {
    if (is.na(v)) return(NA_character_)
    k <- unique(strsplit(v, separator, fixed = TRUE)[[1L]])
    for (cn in names(classes)) k[k %in% unlist(classes[[cn]])] <- cn
    k <- unique(k)
    if (length(k) > 1L) multiple else k
  }
  out <- expand.grid(id = ids, gene = genes, stringsAsFactors = FALSE)
  out$class <- mapply(function(g, s) {
    r <- match(g, genes_all)
    if (is.na(r)) NA_character_ else cls_of(vals[r, cols[match(s, ids)]])
  }, out$gene, out$id, USE.NAMES = FALSE)
  out$count <- ifelse(out$gene %in% genes_all, unname(counts[out$gene]), 0)
  out$percent <- 100 * out$count / length(ids)
  out$gene_rank <- match(out$gene, genes)
  out[, c("gene", "id", "class", "count", "percent", "gene_rank")]
}

#' Counts and Shares by Group
#'
#' Counts records per group (or overall), optionally the number of distinct
#' values of a column and the records per distinct value, the share of all
#' counted records, and counts of selected values of further columns.
#'
#' @param data Data frame.
#' @param by Grouping columns (none for one overall row).
#' @param keep Optional named list selecting records.
#' @param distinct Optional column whose distinct values are counted.
#' @param tally Optional named list of extra counts: each a list of
#'   `column` and `values`.
#' @param scale Multiplier of the share (100 for percentages).
#' @return A data frame with the groups, `n`, `share`, and if requested
#'   `n_distinct`, `n_per_distinct` (integer division) and the tallies.
#' @examples
#' d <- data.frame(g = c("a", "a", "b"), p = c("x", "y", "x"), t = c("T", "U", "T"))
#' CountBy(d, "g", distinct = "p", tally = list(n_t = list(column = "t", values = "T")))
#' @export
CountBy <- function(data, by = NULL, keep = NULL, distinct = NULL, tally = NULL, scale = 100) {
  by <- as.character(unlist(by))
  .fig_require_columns(data, c(by, distinct))
  ok <- .figb_keep(data, keep)
  d <- data[ok, , drop = FALSE]
  key <- if (length(by)) do.call(paste, c(d[by], sep = "\r")) else rep("all", nrow(d))
  lev <- unique(key)
  out <- if (length(by)) d[match(lev, key), by, drop = FALSE] else data.frame(row.names = 1)
  out$n <- as.integer(vapply(lev, function(k) sum(key == k), numeric(1)))
  out$share <- scale * out$n / nrow(d)
  if (!is.null(distinct)) {
    out$n_distinct <- vapply(lev, function(k) length(unique(d[[distinct]][key == k])), integer(1))
    out$n_per_distinct <- out$n %/% out$n_distinct
  }
  for (nm in names(tally)) {
    t <- tally[[nm]]
    .fig_require_columns(d, t$column)
    hit <- as.character(d[[t$column]]) %in% as.character(unlist(t$values))
    out[[nm]] <- as.integer(vapply(lev, function(k) sum(hit[key == k]), numeric(1)))
  }
  rownames(out) <- NULL
  out
}

#' Key Colours from a Categorical Palette
#'
#' Assigns colours to integer keys (for example cluster numbers) by cycling
#' through one or more categorical palettes: key `k` takes colour
#' `((k - first) mod n) + 1` of the joined palettes.
#'
#' @param keys Keys: a vector, or a data frame whose `column` holds them.
#' @param column Key column when `keys` is a data frame.
#' @param palettes Palette names: `"tab20"`, `"tab20b"`, `"tab20c"` or
#'   `"clusters"` (the style's cluster palette), joined in order.
#' @param first Key that takes the first colour.
#' @return A data frame with `key` and `colour`, sorted by key.
#' @examples
#' KeyColours(1:25)
#' @export
KeyColours <- function(keys, column = "key", palettes = c("tab20", "tab20b"), first = 1) {
  k <- if (is.data.frame(keys)) keys[[column]] else unlist(keys)
  k <- sort(unique(as.numeric(k[!is.na(k)])))
  pal <- unlist(lapply(unlist(palettes), .figb_categorical))
  data.frame(key = as.character(k), colour = pal[((k - first) %% length(pal)) + 1L], stringsAsFactors = FALSE)
}

.figb_categorical <- function(name) {
  switch(name,
    tab20 = ManuscriptPalettes()$clusters,
    clusters = ManuscriptPalettes()$clusters,
    tab20b = c("#393b79", "#5254a3", "#6b6ecf", "#9c9ede", "#637939", "#8ca252", "#b5cf6b", "#cedb9c",
               "#8c6d31", "#bd9e39", "#e7ba52", "#e7cb94", "#843c39", "#ad494a", "#d6616b", "#e7969c",
               "#7b4173", "#a55194", "#ce6dbd", "#de9ed6"),
    tab20c = c("#3182bd", "#6baed6", "#9ecae1", "#c6dbef", "#e6550d", "#fd8d3c", "#fdae6b", "#fdd0a2",
               "#31a354", "#74c476", "#a1d99b", "#c7e9c0", "#756bb1", "#9e9ac8", "#bcbddc", "#dadaeb",
               "#636363", "#969696", "#bdbdbd", "#d9d9d9"),
    stop("Unknown categorical palette '", name, "'.", call. = FALSE)
  )
}

#' Scale a Column to a Reference Row
#'
#' Divides a column by its value in a reference row (the first row by
#' default, or the row where `at_column` equals `at`), for curves shown
#' relative to their first point.
#'
#' @param data Data frame.
#' @param column Column to scale.
#' @param at_column,at Optional reference row selector.
#' @param to Output column (default `column`).
#' @return `data` with the scaled column.
#' @examples
#' ScaleToReference(data.frame(k = 4:6, inertia = c(50, 40, 30)), "inertia")
#' @export
ScaleToReference <- function(data, column, at_column = NULL, at = NULL, to = column) {
  .fig_require_columns(data, c(column, at_column))
  ref <- if (is.null(at_column)) data[[column]][1L] else data[[column]][which(data[[at_column]] == at)[1L]]
  data[[to]] <- as.numeric(data[[column]]) / as.numeric(ref)
  data
}

#' Bind Rows of Several Tables
#'
#' Stacks tables with the same columns and records their origin.
#'
#' @param tables Named list of data frames.
#' @param labels Optional labels for the origin column, in table order;
#'   default the list names.
#' @param origin Name of the origin column.
#' @param columns Optional columns to keep (all must exist in every table).
#' @return A data frame.
#' @examples
#' BindTables(list(a = data.frame(k = 1:2, v = 3:4), b = data.frame(k = 1, v = 9)))
#' @export
BindTables <- function(tables, labels = NULL, origin = "source", columns = NULL) {
  if (!is.list(tables) || !length(tables)) stop("tables must be a non-empty list.", call. = FALSE)
  labels <- if (is.null(labels)) names(tables) else as.character(unlist(labels))
  parts <- lapply(seq_along(tables), function(i) {
    t <- as.data.frame(tables[[i]], check.names = FALSE)
    if (!is.null(columns)) t <- t[, unlist(columns), drop = FALSE]
    t[[origin]] <- rep(labels[i], nrow(t))
    t
  })
  out <- do.call(rbind, parts)
  rownames(out) <- NULL
  out
}
