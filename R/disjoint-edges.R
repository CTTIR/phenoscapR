#' Count Undirected Edges Between Disjoint Node Sets
#'
#' Counts an explicitly supplied edge set using stable node IDs within complete
#' group and frame keys. Isolated nodes and nodes in neither set remain in the
#' supplied graph totals. No graph is constructed, no distance cap is applied,
#' and no scientific population, radius or eligibility policy is inferred.
#'
#' @param nodes Data frame containing every node, including isolated nodes.
#' @param edges Data frame with one row per undirected edge. Extra columns,
#'   including distances, are ignored; filtering is the caller's responsibility.
#' @param registry Data frame with unique group/frame keys, including desired
#'   empty frames, and character columns `geometry_source` and
#'   `geometry_reference`. The source is `"frozen_import"` or `"supplied_edges"`;
#'   the reference is a nonempty caller-declared artifact or provenance reference.
#' @param groups Nonempty character vector naming distinct group columns shared
#'   by all three tables. Include the independent sample key as appropriate.
#' @param frame Character name of the frame column shared by all three tables.
#' @param id Character name of the node ID column in `nodes`.
#' @param from,to Character names of endpoint ID columns in `edges`.
#' @param source,target Character names of logical membership columns in `nodes`.
#'   Missing membership and overlapping sets are rejected. Nodes in neither set are valid.
#'
#' @details
#' Keys and IDs must be dimensionless, nonmissing, nonblank character vectors.
#' IDs may repeat across different groups or frames, but must be unique within
#' the complete group/frame key. Factors and numeric IDs are not coerced.
#' Duplicate registry keys, unknown endpoints, self edges, and duplicate
#' undirected pairs (including reversed duplicates) raise errors. Each edge
#' declares one shared frame, so a cross-frame relationship cannot be represented;
#' an endpoint absent from the declared frame raises an error. The function cannot
#' detect incorrectly declared frames or establish physical coordinate validity.
#'
#' Each source-target edge contributes once regardless of orientation. Conditional
#' neighbor means divide cross-edge count by the number of distinct interacting
#' source or target nodes. Contact fractions divide interacting nodes by the
#' corresponding complete source or target population. Thus isolated nodes enter
#' contact-fraction denominators but not conditional-neighbor denominators.
#'
#' A population with no contacts has contact fraction zero (`DEFINED`) and
#' conditional mean `NA` (`NO_INTERACTING_SOURCE` or `NO_INTERACTING_TARGET`).
#' An absent population has contact fraction `NA` (`NO_SOURCE` or `NO_TARGET`).
#' Missing membership never becomes an observed zero. Empty registries return
#' the same typed zero-row schema.
#'
#' Provenance is copied from the registry, not authenticated. In particular,
#' `frozen_import` does not mean geometry was regenerated or its hashes verified.
#' The result declares `geometry_recomputed = FALSE` and
#' `geometry_authentication = "CALLER_DECLARED_NOT_VERIFIED"`. This API does not
#' invoke or certify any triangulation, distance, review or geometry backend.
#'
#' @return Data frame sorted by group/frame keys. Schema version `"1.0.0"` has
#'   integer-valued numeric counts `n_nodes`, `n_edges`, `n_source`, `n_target`,
#'   `n_cross_edges`, `n_interacting_source`, and `n_interacting_target`;
#'   `source_neighbor_mean`, `target_neighbor_mean`, `source_contact_fraction`,
#'   and `target_contact_fraction`; and their corresponding `_status` columns.
#'   Supplied graph totals include all nodes and edges, even those contributing
#'   no source-target contact. Geometry provenance columns and `schema_version`
#'   are retained explicitly. Extra input columns are not returned.
#' @examples
#' nodes <- data.frame(sample = rep("one", 3), frame = rep("image", 3),
#'   cell = c("a", "b", "isolated"), is_source = c(TRUE, FALSE, TRUE),
#'   is_target = c(FALSE, TRUE, FALSE))
#' edges <- data.frame(sample = "one", frame = "image", from = "b", to = "a")
#' registry <- data.frame(sample = c("one", "empty"), frame = "image",
#'   geometry_source = "supplied_edges", geometry_reference = "example-v1")
#' CountDisjointEdges(nodes, edges, registry, groups = "sample", frame = "frame",
#'   id = "cell", from = "from", to = "to", source = "is_source", target = "is_target")
#' @export
CountDisjointEdges <- function(nodes, edges, registry, groups, frame, id,
                               from, to, source, target) {
  assert <- function(ok, message) {
    if (!isTRUE(ok)) stop(message, call. = FALSE)
  }
  names_ok <- function(x) {
    is.character(x) && is.null(dim(x)) && length(x) > 0L && !anyNA(x) &&
      all(nzchar(trimws(x))) && !anyDuplicated(x)
  }
  scalar_name <- function(x) names_ok(x) && length(x) == 1L
  assert(names_ok(groups), "groups must name distinct nonempty columns")
  assert(all(vapply(list(frame, id, from, to, source, target), scalar_name,
                    logical(1))), "selected columns must be scalar names")
  keys <- c(groups, frame)
  outputs <- c("n_nodes", "n_edges", "n_source", "n_target", "n_cross_edges",
    "n_interacting_source", "n_interacting_target", "source_neighbor_mean",
    "target_neighbor_mean", "source_contact_fraction", "target_contact_fraction",
    "source_neighbor_status", "target_neighbor_status", "source_contact_status",
    "target_contact_status", "geometry_recomputed", "geometry_authentication",
    "schema_version")
  provenance <- c("geometry_source", "geometry_reference")
  assert(names_ok(c(keys, id, source, target)) && names_ok(c(keys, from, to)),
         "key and selected roles must have distinct columns within each table")
  assert(!any(keys %in% c(outputs, provenance)), "keys collide with output columns")
  table <- function(x, required, label) {
    assert(is.data.frame(x) && !anyDuplicated(names(x)) &&
             all(required %in% names(x)), paste(label, "has invalid schema"))
    as.data.frame(x, stringsAsFactors = FALSE)
  }
  nodes <- table(nodes, c(keys, id, source, target), "nodes")
  edges <- table(edges, c(keys, from, to), "edges")
  registry <- table(registry, c(keys, provenance), "registry")
  text_columns <- function(x, cols) {
    for (col in cols) assert(is.character(x[[col]]) && is.null(dim(x[[col]])) &&
      !anyNA(x[[col]]) && all(nzchar(trimws(x[[col]]))),
      paste("nonempty nonmissing character values required in", col))
  }
  text_columns(nodes, c(keys, id))
  text_columns(edges, c(keys, from, to))
  text_columns(registry, c(keys, provenance))
  # Length-prefix each UTF-8 field; separators inside IDs cannot collide.
  key <- function(x, cols) {
    parts <- lapply(x[cols], function(v) {
      v <- enc2utf8(v)
      paste0(nchar(v, type = "bytes"), ":", v)
    })
    if (!nrow(x)) character() else do.call(paste0, unname(parts))
  }
  rk <- key(registry, keys)
  nk <- key(nodes, c(keys, id))
  assert(!anyDuplicated(rk), "duplicate registry key")
  assert(!anyDuplicated(nk), "duplicate node ID within group/frame")
  ng <- match(key(nodes, keys), rk)
  eg <- match(key(edges, keys), rk)
  assert(!anyNA(ng) && !anyNA(eg), "group/frame absent from registry")
  membership <- function(x) is.logical(x) && is.null(dim(x)) && !anyNA(x)
  assert(membership(nodes[[source]]) && membership(nodes[[target]]),
         "memberships must be logical without missing values")
  assert(!any(nodes[[source]] & nodes[[target]]), "source and target overlap")
  assert(all(registry$geometry_source %in% c("frozen_import", "supplied_edges")),
         "geometry_source must be frozen_import or supplied_edges")
  endpoint <- function(column) {
    d <- edges[keys]
    d[[id]] <- edges[[column]]
    match(key(d, c(keys, id)), nk)
  }
  a <- endpoint(from)
  z <- endpoint(to)
  assert(!anyNA(a) && !anyNA(z), "unknown endpoint in declared group/frame")
  assert(!any(a == z), "self edges are not allowed")
  canonical <- paste(pmin(a, z), pmax(a, z), sep = ":")
  assert(!anyDuplicated(canonical), "duplicate undirected edge")
  s <- nodes[[source]]
  t <- nodes[[target]]
  forward <- s[a] & t[z]
  reverse <- s[z] & t[a]
  si <- c(a[forward], z[reverse])
  ti <- c(z[forward], a[reverse])
  n <- nrow(registry)
  counts <- function(g) as.double(tabulate(g, nbins = n))
  out <- registry[c(keys, provenance)]
  out$n_nodes <- counts(ng)
  out$n_edges <- counts(eg)
  out$n_source <- counts(ng[s])
  out$n_target <- counts(ng[t])
  out$n_cross_edges <- counts(ng[si])
  out$n_interacting_source <- counts(ng[unique(si)])
  out$n_interacting_target <- counts(ng[unique(ti)])
  divide <- function(num, den) {
    ans <- rep(NA_real_, length(den))
    use <- den > 0
    ans[use] <- num[use] / den[use]
    ans
  }
  out$source_neighbor_mean <- divide(out$n_cross_edges, out$n_interacting_source)
  out$target_neighbor_mean <- divide(out$n_cross_edges, out$n_interacting_target)
  out$source_contact_fraction <- divide(out$n_interacting_source, out$n_source)
  out$target_contact_fraction <- divide(out$n_interacting_target, out$n_target)
  out$source_neighbor_status <- as.character(ifelse(out$n_interacting_source > 0,
                                                    "DEFINED", "NO_INTERACTING_SOURCE"))
  out$target_neighbor_status <- as.character(ifelse(out$n_interacting_target > 0,
                                                    "DEFINED", "NO_INTERACTING_TARGET"))
  out$source_contact_status <- as.character(ifelse(out$n_source > 0, "DEFINED", "NO_SOURCE"))
  out$target_contact_status <- as.character(ifelse(out$n_target > 0, "DEFINED", "NO_TARGET"))
  out$geometry_recomputed <- rep(FALSE, n)
  out$geometry_authentication <- rep("CALLER_DECLARED_NOT_VERIFIED", n)
  out$schema_version <- rep("1.0.0", n)
  sort_keys <- lapply(out[keys], enc2utf8)
  out <- out[do.call(order, c(unname(sort_keys), list(method = "radix"))), , drop = FALSE]
  rownames(out) <- NULL
  out
}
