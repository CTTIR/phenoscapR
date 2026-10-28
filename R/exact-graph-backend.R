.ed_strict <- function(expr) {
  withCallingHandlers(expr,
    warning = function(w) stop(paste("Backend warning:", conditionMessage(w)), call. = FALSE),
    message = function(m) {
      stop(paste("Unexpected backend message:", conditionMessage(m)), call. = FALSE)
    }
  )
}

# deldir::deldir() reports each enlargement of its own workspace before retrying;
# the retried triangulation is complete, so these messages are counted, not raised.
.ed_workspace_growth <- function(message) {
  grepl("^Increasing (madj|ndel)", message)
}

.ed_build_geometry <- function(x, y, backend_contract, eps, mode,
                               initial_madj = 64L, max_retries = 32L) {
  # This low-level constructor consumes points already in explicit source order.
  # `backend_contract` is accepted for compatibility and not used.
  .ed_assert(
    .ed_number(x) && .ed_number(y) && length(x) == length(y),
    "Finite paired coordinates required"
  )
  .ed_assert(.ed_number(eps) && length(eps) == 1L && eps > 0, "Positive scalar eps required")
  plan <- PlanExactDelaunayWorkspace(length(x), mode, initial_madj, max_retries, FALSE)
  .ed_assert(
    !plan$bounded_required,
    "Frame exceeds the integer workspace of deldir::deldir()"
  )
  .ed_assert(!anyDuplicated(data.frame(x = x, y = y)), "Duplicate coordinates")
  # Match source chull audit, rather than the pure validator conservative determinant.
  .ed_assert(
    length(unique(x)) >= 2L && length(unique(y)) >= 2L && length(grDevices::chull(x, y)) >= 3L,
    "Two-dimensional geometry required"
  )
  .ed_assert(
    requireNamespace("deldir", quietly = TRUE),
    "Delaunay construction requires the deldir package"
  )
  window <- .ed_window(x, y)
  rw <- window$bounds
  x <- as.double(x)
  y <- as.double(y)
  n <- length(x)
  growth <- 0L
  answer <- .ed_strict(withCallingHandlers(
    deldir::deldir(x, y,
      rw = rw, eps = eps, sort = TRUE,
      round = FALSE, suppressMsge = TRUE
    ),
    message = function(m) {
      if (.ed_workspace_growth(conditionMessage(m))) {
        growth <<- growth + 1L
        invokeRestart("muffleMessage")
      }
    }
  ))
  .ed_assert(is.list(answer) && identical(as.double(answer$n.data), as.double(n)) &&
    is.data.frame(answer$delsgs), "Invalid deldir result schema or point count")
  edges <- answer$delsgs
  # Complete graph invariants are checked before any caller eligibility induction.
  nodes <- data.frame(
    scope = "geometry", frame = "single", id = as.character(seq_len(n)),
    x = x, y = y, point_order = seq_len(n), orientation_rank = seq_len(n), geometry = TRUE,
      eligible = TRUE
  )
  .ed_assert(is.data.frame(edges) && !anyDuplicated(names(edges)) &&
    all(c("ind1", "ind2", "x1", "y1", "x2", "y2") %in% names(edges)), "Invalid edge result schema")
  raw <- edges[c("ind1", "ind2", "x1", "y1", "x2", "y2")]
  raw$scope <- rep("geometry", nrow(raw))
  raw$frame <- rep("single", nrow(raw))
  checked <- .ed_validate_supplied_edges(
    nodes, raw, data.frame(scope = "geometry", frame = "single", unit = "um"),
    "scope", "frame", "id", "x", "y", "point_order", "orientation_rank", "geometry",
      "eligible", "unit", "um", "orientation_rank"
  )
  # Internal unit token is validation-only; no physical unit claim is returned.
  list(
    raw_edges = edges[c("ind1", "ind2", "x1", "y1", "x2", "y2")], n_points = n,
    n_validated_edges = nrow(checked$full_edges), window = window,
    provenance = list(
      engine = "deldir", interface = "deldir::deldir",
      deldir_version = as.character(utils::packageVersion("deldir")),
      native_execution = TRUE, eps = eps, sort = TRUE, round = FALSE,
      requested_mode = mode, execution_path = "STOCK_WRAPPER",
      workspace_growth = growth, coordinate_units = "CALLER_DEFINED_UNCHANGED",
      point_order = "INPUT_VECTOR_ORDER", historical_parity = "NOT_ESTABLISHED"
    )
  )
}
