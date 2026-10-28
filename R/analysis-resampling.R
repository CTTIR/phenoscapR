# Resampling summaries with declared random streams or supplied draws.

# Runs `expr` with R's default generators seeded by `seed`; restores the
# caller's random stream afterwards.
.an_with_seed <- function(seed, expr) {
  if (is.null(seed)) return(expr)
  .an_assert(is.numeric(seed) && length(seed) == 1L && is.finite(seed) && seed == floor(seed),
             "seed must be one whole number")
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  old_kind <- RNGkind()
  on.exit({
    RNGkind(old_kind[1L], old_kind[2L], old_kind[3L])
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  }, add = TRUE)
  set.seed(seed, kind = "Mersenne-Twister", normal.kind = "Inversion",
           sample.kind = "Rejection")
  force(expr)
}

# Row medians; the even case averages the two middle values as (a + b) / 2.
.an_row_medians <- function(m) {
  n <- ncol(m)
  if (n == 1L) return(m[, 1L])
  s <- apply(m, 1L, sort.int, method = "quick")
  if (n %% 2L) s[(n + 1L) / 2L, ] else (s[n / 2L, ] + s[n / 2L + 1L, ]) / 2
}

#' Bootstrap Percentile Interval of a Median
#'
#' Resamples the finite values of each group with replacement and reports the
#' percentile interval of the resampled medians (quantile type 7, which is
#' NumPy's default linear percentile). Draws come from R's Mersenne-Twister
#' generator with a declared seed, or from supplied resampling indices (for
#' example indices archived from another implementation), so that the
#' interval can be reproduced exactly.
#'
#' @param data Data frame in long form.
#' @param value Numeric value column.
#' @param groups Optional group columns; one interval per group.
#' @param n_boot Number of resamples.
#' @param conf_level Interval coverage.
#' @param seed Optional whole-number seed. With `reseed = TRUE` every group
#'   starts from this seed (as a per-call generator would); otherwise groups
#'   share one stream in output order. The caller's random stream is restored.
#' @param reseed See `seed`.
#' @param indices Optional supplied draws: an integer matrix with `n_boot` rows
#'   and one column per finite value (a single group), or a named list of such
#'   matrices keyed by `hypothesis_id`-style group labels (group values joined
#'   by `" :: "`). Each row is one resample.
#' @param index_base `1` (R) or `0` (zero-based archived indices).
#' @return A data frame with the group columns, `n`, `median`, `lower`,
#'   `upper`, `conf_level`, `n_boot`, `seed` and `draws` (`"R_MERSENNE_TWISTER"`
#'   or `"SUPPLIED"`).
#' @examples
#' d <- data.frame(g = rep(c("a", "b"), each = 8), v = c(1:8, (1:8)^2))
#' BootstrapMedianInterval(d, "v", "g", n_boot = 2000, seed = 42)
#' @export
BootstrapMedianInterval <- function(data, value, groups = NULL, n_boot = 10000L,
                                    conf_level = 0.95, seed = NULL, reseed = TRUE,
                                    indices = NULL, index_base = 1L) {
  .an_assert(.an_name(value) && .an_names(groups), "Invalid value or group columns")
  .an_require(data, c(value, groups))
  .an_assert(is.numeric(n_boot) && length(n_boot) == 1L && n_boot >= 1 &&
               n_boot == floor(n_boot), "n_boot must be a positive whole number")
  .an_assert(is.numeric(conf_level) && length(conf_level) == 1L && conf_level > 0 &&
               conf_level < 1, "conf_level must lie in (0, 1)")
  .an_assert(index_base %in% c(0, 1), "index_base must be 0 or 1")
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  parts <- .an_split(data, groups)
  labels <- vapply(parts, function(ii) {
    if (is.null(groups)) return("all")
    paste(vapply(groups, function(g) as.character(data[[g]][ii[1L]]), ""), collapse = " :: ")
  }, character(1))
  if (!is.null(indices) && !is.list(indices)) {
    .an_assert(length(parts) == 1L, "A single index matrix requires a single group")
    indices <- stats::setNames(list(indices), labels)
  }
  probs <- c((1 - conf_level) / 2, 1 - (1 - conf_level) / 2)
  one <- function(k) {
    ii <- parts[[k]]
    d <- as.numeric(data[[value]][ii])
    d <- d[is.finite(d)]
    n <- length(d)
    res <- list(n = n, median = NA_real_, lower = NA_real_, upper = NA_real_)
    if (!n) return(res)
    res$median <- stats::median(d)
    if (!is.null(indices)) {
      m <- indices[[labels[k]]]
      .an_assert(is.matrix(m) && nrow(m) == n_boot && ncol(m) == n &&
                   all(m == floor(m)), paste("Invalid supplied indices for", labels[k]))
      m <- m + (1L - index_base)
      .an_assert(all(m >= 1 & m <= n), "Supplied indices out of range")
    } else {
      m <- matrix(sample.int(n, n * n_boot, replace = TRUE), nrow = n_boot, byrow = TRUE)
    }
    meds <- .an_row_medians(matrix(d[m], nrow = n_boot))
    q <- stats::quantile(meds, probs, type = 7, names = FALSE)
    res$lower <- q[1L]
    res$upper <- q[2L]
    res
  }
  results <- vector("list", length(parts))
  if (is.null(indices) && !is.null(seed) && !isTRUE(reseed)) {
    results <- .an_with_seed(seed, lapply(seq_along(parts), one))
  } else {
    for (k in seq_along(parts)) {
      results[[k]] <- if (is.null(indices)) .an_with_seed(seed, one(k)) else one(k)
    }
  }
  out <- if (length(results)) {
    data.frame(do.call(rbind, lapply(results, as.data.frame)))
  } else {
    data.frame(n = integer(), median = numeric(), lower = numeric(), upper = numeric())
  }
  if (!is.null(groups)) {
    key <- data[vapply(parts, `[`, 1L, 1L), groups, drop = FALSE]
    rownames(key) <- NULL
    out <- cbind(key, out)
  }
  out$conf_level <- rep(conf_level, nrow(out))
  out$n_boot <- rep(n_boot, nrow(out))
  out$seed <- rep(if (is.null(seed) || !is.null(indices)) NA_real_ else seed, nrow(out))
  out$draws <- rep(if (is.null(indices)) "R_MERSENNE_TWISTER" else "SUPPLIED", nrow(out))
  rownames(out) <- NULL
  out
}

# All permutations of 1..n as rows (lexicographic order).
.an_permutations <- function(n) {
  if (n == 1L) return(matrix(1L, 1L, 1L))
  sub <- .an_permutations(n - 1L)
  do.call(rbind, lapply(seq_len(n), function(first) {
    rest <- setdiff(seq_len(n), first)
    cbind(first, matrix(rest[sub], nrow = nrow(sub)))
  }))
}

#' Permutation Test of a Rank or Linear Correlation
#'
#' Computes Spearman's rho (Pearson correlation of midranks) or Pearson's r
#' for the complete pairs of each group, with a two-sided permutation p value:
#' Monte Carlo with a declared R seed, `(b + 1) / (B + 1)` where `b` counts
#' permuted absolute correlations at least the observed one, or exact
#' enumeration of all `n!` orderings (`mean` of the same indicator).
#'
#' @param data Data frame.
#' @param x,y Numeric columns.
#' @param groups Optional group columns.
#' @param method `"spearman"` or `"pearson"`.
#' @param permutations `"monte_carlo"` or `"exact"`.
#' @param n_perm Number of Monte Carlo permutations.
#' @param seed Optional whole-number seed for Monte Carlo draws; every group
#'   starts from it. The caller's random stream is restored.
#' @param min_n Smallest number of complete pairs tested.
#' @param max_exact_n Largest `n` accepted for exact enumeration.
#' @param tolerance Absolute tolerance in the comparison with the observed
#'   correlation.
#' @return A data frame with the group columns, `n`, `estimate`, `p_value`,
#'   `method`, `permutations`, `n_perm` (number of orderings used), `seed`
#'   and `status`.
#' @examples
#' d <- data.frame(x = c(1, 2, 3, 4, 5, 6), y = c(2, 1, 4, 3, 6, 5))
#' PermutationCorrelation(d, "x", "y", permutations = "exact")
#' PermutationCorrelation(d, "x", "y", n_perm = 999, seed = 1)
#' @export
PermutationCorrelation <- function(data, x, y, groups = NULL,
                                   method = c("spearman", "pearson"),
                                   permutations = c("monte_carlo", "exact"),
                                   n_perm = 99999L, seed = NULL, min_n = 4L,
                                   max_exact_n = 9L, tolerance = 1e-12) {
  method <- match.arg(method)
  permutations <- match.arg(permutations)
  .an_assert(.an_name(x) && .an_name(y) && .an_names(groups), "Invalid columns")
  .an_require(data, c(x, y, groups))
  .an_assert(is.numeric(n_perm) && length(n_perm) == 1L && n_perm >= 1 &&
               n_perm == floor(n_perm), "n_perm must be a positive whole number")
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  parts <- .an_split(data, groups)
  one <- function(ii) {
    a <- as.numeric(data[[x]][ii])
    b <- as.numeric(data[[y]][ii])
    ok <- is.finite(a) & is.finite(b)
    a <- a[ok]
    b <- b[ok]
    n <- length(a)
    res <- list(n = n, estimate = NA_real_, p_value = NA_real_, n_perm = NA_real_,
                status = "UNAVAILABLE")
    if (method == "spearman") {
      a <- rank(a, ties.method = "average")
      b <- rank(b, ties.method = "average")
    }
    if (n < min_n || stats::sd(a) == 0 || stats::sd(b) == 0) return(res)
    za <- (a - mean(a)) / sqrt(sum((a - mean(a))^2))
    zb <- (b - mean(b)) / sqrt(sum((b - mean(b))^2))
    est <- stats::cor(a, b)
    if (permutations == "exact") {
      .an_assert(n <= max_exact_n, paste("Exact enumeration limited to n <=", max_exact_n))
      perm <- .an_permutations(n)
      null <- as.vector(matrix(zb[perm], nrow = nrow(perm)) %*% za)
      res$p_value <- mean(abs(null) >= abs(est) - tolerance)
      res$n_perm <- nrow(perm)
    } else {
      hits <- 0
      left <- n_perm
      while (left > 0) {
        block <- min(left, 10000)
        perm <- t(replicate(block, sample.int(n)))
        null <- as.vector(matrix(zb[perm], nrow = block) %*% za)
        hits <- hits + sum(abs(null) >= abs(est) - tolerance)
        left <- left - block
      }
      res$p_value <- (hits + 1) / (n_perm + 1)
      res$n_perm <- n_perm
    }
    res$estimate <- est
    res$status <- "TESTED"
    res
  }
  results <- lapply(parts, function(ii) {
    if (permutations == "monte_carlo") .an_with_seed(seed, one(ii)) else one(ii)
  })
  out <- if (length(results)) {
    data.frame(do.call(rbind, lapply(results, as.data.frame)))
  } else {
    data.frame(n = integer(), estimate = numeric(), p_value = numeric(), n_perm = numeric(),
               status = character(), stringsAsFactors = FALSE)
  }
  if (!is.null(groups)) {
    key <- data[vapply(parts, `[`, 1L, 1L), groups, drop = FALSE]
    rownames(key) <- NULL
    out <- cbind(key, out)
  }
  out$method <- rep(method, nrow(out))
  out$permutations <- rep(permutations, nrow(out))
  out$seed <- rep(if (is.null(seed) || permutations == "exact") NA_real_ else seed, nrow(out))
  out <- out[c(groups, "n", "estimate", "p_value", "method", "permutations", "n_perm",
               "seed", "status")]
  rownames(out) <- NULL
  out
}
