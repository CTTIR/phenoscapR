.ed_contract <- function(contract) {
  fields <- c(
    "package_version", "description_sha256", "native_library_sha256",
    "binsrtR_body_serialized_sha256", "binsrtR_body_deparse_sha256",
    "wrapper_body_serialized_sha256", "wrapper_body_deparse_sha256",
    "digOutxy_body_serialized_sha256", "digOutxy_body_deparse_sha256",
    "digOutz_body_serialized_sha256", "digOutz_body_deparse_sha256",
    "binsrt_num_parameters", "master_num_parameters"
  )
  .ed_assert(
    is.list(contract) && identical(sort(names(contract)), sort(fields)),
    "Backend contract requires exactly the declared fields; pointers are forbidden"
  )
  .ed_assert(identical(contract$package_version, "2.0-4"), "Unsupported backend profile")
  for (k in fields[2:11]) {
    .ed_assert(is.character(contract[[k]]) && !is.object(contract[[k]]) &&
      is.null(dim(contract[[k]])) && length(contract[[k]]) == 1L &&
      !is.na(contract[[k]]) && grepl("^[0-9a-f]{64}$", contract[[k]]), "Invalid backend digest")
  }
  .ed_assert(.ed_whole(contract$binsrt_num_parameters, 9, 9) &&
    .ed_whole(contract$master_num_parameters, 16, 16), "Unsupported routine arities")
  invisible(TRUE)
}


.ed_detached_closure <- function(original, parent) {
  # Detach language objects: ordinary closure copies can share runtime-mutated AST metadata.
  clone <- function() NULL
  formals(clone) <- unserialize(serialize(formals(original), NULL))
  body(clone) <- unserialize(serialize(body(original), NULL))
  environment(clone) <- parent
  attributes(clone) <- attributes(original)
  clone
}

.ed_bind_calls <- function(sorter, wrapper, registered, namespace, helpers = list()) {
  # Clone closures over their original lexical parents; leave originals intact.
  # Approved bodies call .Fortran by an unqualified name, intercepted here.
  target <- list(binsrt = registered$binsrt, master = registered$master)
  bridge <- function(.NAME, ..., PACKAGE) {
    .ed_assert(
      is.character(.NAME) && length(.NAME) == 1L &&
        .NAME %in% names(target) && identical(PACKAGE, "deldir"),
      "Unapproved native dispatch"
    )
    base::.Fortran(target[[.NAME]], ...)
  }
  sorter_binding <- new.env(parent = environment(sorter))
  sorter_binding$.Fortran <- bridge
  sorter_clone <- .ed_detached_closure(sorter, sorter_binding)
  wrapper_binding <- new.env(parent = environment(wrapper))
  wrapper_binding$.Fortran <- bridge
  wrapper_binding$binsrtR <- sorter_clone
  for (k in names(helpers)) {
    helper_binding <- new.env(parent = environment(helpers[[k]]))
    helper_clone <- .ed_detached_closure(helpers[[k]], helper_binding)
    lockEnvironment(helper_binding, bindings = TRUE)
    wrapper_binding[[k]] <- helper_clone
  }
  wrapper_clone <- .ed_detached_closure(wrapper, wrapper_binding)
  lockEnvironment(sorter_binding, bindings = TRUE)
  lockEnvironment(wrapper_binding, bindings = TRUE)
  list(sorter = sorter_clone, wrapper = wrapper_clone)
}

.ed_backend <- function(contract) {
  .ed_contract(contract)
  .ed_assert(
    requireNamespace("digest", quietly = TRUE) && requireNamespace("deldir", quietly = TRUE),
    "Required backend packages unavailable"
  )
  ns <- asNamespace("deldir")
  root <- normalizePath(getNamespaceInfo(ns, "path"), mustWork = TRUE)
  desc <- file.path(root, "DESCRIPTION")
  dll <- getLoadedDLLs()[["deldir"]]
  .ed_assert(
    !is.null(dll) && identical(dll[["dynamicLookup"]], FALSE),
    "Registered backend DLL required"
  )
  path <- normalizePath(dll[["path"]], mustWork = TRUE)
  .ed_assert(
    startsWith(path, paste0(root, .Platform$file.sep, "libs", .Platform$file.sep)),
    "Loaded DLL is outside the loaded package library"
  )
  sorter <- get("binsrtR", envir = ns, inherits = FALSE)
  .ed_assert(is.function(sorter), "Backend sorter unavailable")
  wrapper <- get("deldir", envir = ns, inherits = FALSE)
  .ed_assert(is.function(wrapper), "Backend wrapper unavailable")
  helpers <- lapply(c("digOutxy", "digOutz"), function(k) {
    get(k, envir = environment(wrapper), inherits = FALSE)
  })
  names(helpers) <- c("digOutxy", "digOutz")
  .ed_assert(all(vapply(helpers, is.function, logical(1))), "Wrapper lexical helpers unavailable")
  hashfile <- function(p) digest::digest(file = p, algo = "sha256", serialize = FALSE)
  observed <- list(
    package_version = as.character(read.dcf(desc, fields = "Version")[[1]]),
    description_sha256 = hashfile(desc), native_library_sha256 = hashfile(path),
    binsrtR_body_serialized_sha256 = digest::digest(body(sorter), algo = "sha256"),
    binsrtR_body_deparse_sha256 = digest::digest(paste(deparse(body(sorter), width.cutoff = 500L),
      collapse = "\n"
    ), algo = "sha256", serialize = FALSE),
    wrapper_body_serialized_sha256 = digest::digest(body(wrapper), algo = "sha256"),
    wrapper_body_deparse_sha256 = digest::digest(paste(deparse(body(wrapper), width.cutoff = 500L),
      collapse = "\n"
    ), algo = "sha256", serialize = FALSE),
    binsrt_num_parameters = 9L, master_num_parameters = 16L
  )
  for (k in names(helpers)) {
    observed[[paste0(k, "_body_serialized_sha256")]] <- digest::digest(body(helpers[[k]]),
      algo = "sha256")
    observed[[paste0(k, "_body_deparse_sha256")]] <- digest::digest(
      paste(deparse(body(helpers[[k]]), width.cutoff = 500L), collapse = "\n"),
      algo = "sha256", serialize = FALSE
    )
  }
  for (k in names(observed)[!names(observed) %in% c("binsrt_num_parameters",
    "master_num_parameters")]) {
    .ed_assert(
      identical(observed[[k]], contract[[k]]),
      paste("Backend pin mismatch:", k)
    )
  }
  reg <- getDLLRegisteredRoutines(dll)$.Fortran
  for (name in c("binsrt", "master")) {
    s <- reg[[name]]
    arity <- if (name == "binsrt") 9L else 16L
    .ed_assert(inherits(s, "NativeSymbolInfo") && identical(s$name, name) &&
      identical(as.integer(s$numParameters), arity) &&
      identical(s$dll[["name"]], "deldir") &&
      identical(normalizePath(s$dll[["path"]], mustWork = TRUE), path) &&
      identical(s$dll[["dynamicLookup"]], FALSE), "Registered symbol metadata mismatch")
  }
  # Fresh namespace/registration lookup, never a caller-provided pointer.
  bound <- .ed_bind_calls(sorter, wrapper, reg, ns, helpers)
  list(
    observed = observed, sorter = bound$sorter, master = reg$master,
    wrapper = bound$wrapper, dll_path = path,
    trust = "MATCHES_CALLER_PINS_ORIGIN_NOT_AUTHENTICATED"
  )
}

.ed_strict <- function(expr) {
  withCallingHandlers(expr,
    warning = function(w) stop(paste("Backend warning:", conditionMessage(w)), call. = FALSE),
    message = function(m) {
      stop(paste("Unexpected backend message:", conditionMessage(m)), call. = FALSE)
    }
  )
}

.ed_result <- function(result, plan) {
  lengths <- plan$native_lengths
  .ed_assert(
    is.list(result) && !anyDuplicated(names(result)) &&
      all(names(lengths) %in% names(result)) &&
      all(vapply(names(lengths), function(k) length(result[[k]]) == lengths[[k]], logical(1))),
    "Incompatible native result lengths"
  )
  .ed_assert(
    .ed_whole(result$incAdj, 0, 1) && .ed_whole(result$incSeg, 0, 1),
    "Invalid native retry flags"
  )
  invisible(TRUE)
}

.ed_build_geometry <- function(x, y, backend_contract, eps, mode,
                               initial_madj = 64L, max_retries = 32L) {
  # This low-level constructor consumes points already in explicit source order.
  .ed_assert(
    .ed_number(x) && .ed_number(y) && length(x) == length(y),
    "Finite paired coordinates required"
  )
  .ed_assert(.ed_number(eps) && length(eps) == 1L && eps > 0, "Positive scalar eps required")
  .ed_contract(backend_contract)
  plan <- PlanExactDelaunayWorkspace(length(x), mode, initial_madj, max_retries, FALSE)
  .ed_assert(!anyDuplicated(data.frame(x = x, y = y)), "Duplicate coordinates")
  # Match source chull audit, rather than the pure validator conservative determinant.
  .ed_assert(
    length(unique(x)) >= 2L && length(unique(y)) >= 2L && length(grDevices::chull(x, y)) >= 3L,
    "Two-dimensional geometry required"
  )
  window <- .ed_window(x, y)
  rw <- window$bounds
  x <- as.double(x)
  y <- as.double(y)
  n <- length(x)
  backend <- .ed_backend(backend_contract)
  retries <- 0
  if (!plan$bounded_planned) {
    answer <- .ed_strict(backend$wrapper(x, y,
      rw = rw, eps = eps, sort = TRUE,
      round = FALSE, suppressMsge = TRUE
    ))
    .ed_assert(is.list(answer) && identical(as.double(answer$n.data), as.double(n)) &&
      is.data.frame(answer$delsgs), "Invalid stock result schema or point count")
    edges <- answer$delsgs
  } else {
    sorted <- .ed_strict(backend$sorter(x, y, rw))
    .ed_assert(
      is.list(sorted) && .ed_number(sorted$x) && .ed_number(sorted$y) &&
        .ed_number(sorted$rind) && length(sorted$x) == n && length(sorted$y) == n &&
        length(sorted$rind) == n && all(sorted$rind == floor(sorted$rind)) &&
        !anyDuplicated(sorted$rind) && setequal(sorted$rind, seq_len(n)),
      "Invalid sorter permutation"
    )
    .ed_assert(
      all(sorted$x == x[sorted$rind] & sorted$y == y[sorted$rind]),
      "Sorter coordinates disagree with permutation"
    )
    xw <- c(rep(0, 4), sorted$x, rep(0, 4))
    yw <- c(rep(0, 4), sorted$y, rep(0, 4))
    repeat {
      # Recheck pins and obtain a fresh registered pointer before each native call.
      backend <- .ed_backend(backend_contract)
      l <- plan$native_lengths
      cap <- plan$segment_capacity
      result <- .ed_strict(.Fortran(backend$master,
        x = as.double(xw), y = as.double(yw), rw = as.double(rw), nn = as.integer(n),
          ntot = as.integer(n + 4),
        nadj = integer(l[["nadj"]]), madj = as.integer(plan$initial_madj_used),
          eps = as.double(eps),
        delsgs = double(l[["delsgs"]]), ndel = as.integer(cap), delsum = double(l[["delsum"]]),
        dirsgs = double(l[["dirsgs"]]), ndir = as.integer(cap), dirsum = double(l[["dirsum"]]),
        incAdj = integer(1), incSeg = integer(1)
      ))
      .ed_result(result, plan)
      next_state <- .ed_next_workspace(
        n, plan$initial_madj_used, retries,
        max_retries, result$incAdj, result$incSeg
      )
      if (next_state$status == "NO_GROWTH_REQUESTED") break
      plan <- next_state$workspace
      retries <- next_state$retries
      rm(result)
      invisible(gc(verbose = FALSE))
    }
    .ed_assert(
      .ed_whole(result$ndel, 1, cap) && .ed_whole(result$ndir, 0, cap),
      "Invalid bounded output counts"
    )
    edges <- as.data.frame(t(matrix(result$delsgs, nrow = 6)[, seq_len(result$ndel), drop = FALSE]))
    names(edges) <- c("x1", "y1", "x2", "y2", "ind1", "ind2")
    for (k in c("ind1", "ind2")) {
      a <- edges[[k]]
      .ed_assert(
        .ed_number(a) && all(a == floor(a) & a >= 1 & a <= n),
        "Invalid native sorted indices"
      )
      edges[[k]] <- as.integer(sorted$rind[a])
    }
  }
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
      engine = "deldir", observed = backend$observed,
      pin_trust = backend$trust, native_execution = TRUE, eps = eps, sort = TRUE, round = FALSE,
      requested_mode = mode, execution_path = plan$execution_path,
      bounded_required = plan$bounded_required, retries = retries,
      final_workspace = plan, coordinate_units = "CALLER_DEFINED_UNCHANGED",
      point_order = "INPUT_VECTOR_ORDER", historical_parity = "NOT_ESTABLISHED"
    )
  )
}
