# Plot-data builders for annotated matrices: coloured categorical tracks and
# gene-by-item alteration classes.

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

