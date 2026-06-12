# ============================================================================
# results.R -- Classed result objects for the spatial statistics
# ----------------------------------------------------------------------------
# Each statistic returns a lightweight S3-classed object that still behaves like
# its underlying data.frame / list / vector (so `$` and `[` access is
# unchanged), but gains tidy `print`, `summary`, and ggplot2 `autoplot` methods
# for a consistent, discoverable API.
# ============================================================================

#' Tag a value with a phenoscapR result class
#' @noRd
.as_result <- function(x, subclass) {
  class(x) <- c(subclass, class(x))
  x
}

# --- Ripley's K --------------------------------------------------------------

#' @export
print.phenoscapR_ripley <- function(x, ...) {
  cat("<phenoscapR> Ripley's K /", attr(x, "correction") %||% "none",
      "correction\n")
  cat(sprintf("  %d radii from %.3g to %.3g\n", nrow(x),
              min(x$r), max(x$r)))
  rng <- range(x$L, na.rm = TRUE)
  cat(sprintf("  L(r) range: [%.3g, %.3g]  (>0 clustered, <0 dispersed)\n",
              rng[1L], rng[2L]))
  print(utils::head(as.data.frame(x), 4L))
  invisible(x)
}

#' @importFrom ggplot2 autoplot ggplot aes geom_line geom_hline labs .data
#' @exportS3Method ggplot2::autoplot
autoplot.phenoscapR_ripley <- function(object, ...) {
  ggplot2::ggplot(as.data.frame(object), ggplot2::aes(.data$r, .data$L)) +
    ggplot2::geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
    ggplot2::geom_line(linewidth = 1, colour = "#3366cc") +
    ggplot2::labs(x = "r", y = "L(r)", title = "Ripley's L function") +
    ggplot2::theme_minimal(base_size = 11)
}

# --- Pair correlation function ----------------------------------------------

#' @export
print.phenoscapR_pcf <- function(x, ...) {
  cat("<phenoscapR> Pair correlation function g(r)\n")
  cat(sprintf("  %d radii from %.3g to %.3g; peak g = %.3g at r = %.3g\n",
              nrow(x), min(x$r), max(x$r), max(x$g, na.rm = TRUE),
              x$r[which.max(x$g)]))
  print(utils::head(as.data.frame(x), 4L))
  invisible(x)
}

#' @exportS3Method ggplot2::autoplot
autoplot.phenoscapR_pcf <- function(object, ...) {
  ggplot2::ggplot(as.data.frame(object), ggplot2::aes(.data$r, .data$g)) +
    ggplot2::geom_hline(yintercept = 1, linetype = 2, colour = "grey50") +
    ggplot2::geom_line(linewidth = 1, colour = "#cc3366") +
    ggplot2::labs(x = "r", y = "g(r)",
                  title = "Pair correlation function") +
    ggplot2::theme_minimal(base_size = 11)
}

# --- Moran's I ---------------------------------------------------------------

#' @export
print.phenoscapR_moran <- function(x, ...) {
  cat("<phenoscapR> Moran's I spatial autocorrelation\n")
  cat(sprintf("  I = %.4f   (expected %.4f under no autocorrelation)\n",
              x$I, x$expected))
  cat(sprintf("  z = %.3f, p = %.3g\n", x$z_score, x$p_value))
  verdict <- if (x$p_value < 0.05 && x$I > x$expected) {
    "significant positive autocorrelation (clustered)"
  } else if (x$p_value < 0.05 && x$I < x$expected) {
    "significant negative autocorrelation (dispersed)"
  } else {
    "no significant spatial autocorrelation"
  }
  cat("  ", verdict, "\n", sep = "")
  invisible(x)
}

# --- Quadrat analysis --------------------------------------------------------

#' @export
print.phenoscapR_quadrat <- function(x, ...) {
  cat("<phenoscapR> Quadrat analysis (chi-squared test of CSR)\n")
  cat(sprintf("  grid %d x %d; chi-sq = %.1f, p = %.3g; VMR = %.2f\n",
              nrow(x$counts), ncol(x$counts), x$chi_sq, x$p_value, x$VMR))
  cat("  ", if (x$VMR > 1) "clustered (VMR > 1)" else
              if (x$VMR < 1) "regular (VMR < 1)" else "random",
      "\n", sep = "")
  invisible(x)
}

#' @exportS3Method ggplot2::autoplot
autoplot.phenoscapR_quadrat <- function(object, ...) {
  m <- object$counts
  df <- data.frame(
    col = as.vector(col(m)), row = as.vector(row(m)),
    count = as.vector(m)
  )
  ggplot2::ggplot(df, ggplot2::aes(.data$col, .data$row, fill = .data$count)) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::scale_fill_gradientn(colours = PaletteContinuous(256L)) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = "quadrat column", y = "quadrat row", fill = "cells",
                  title = "Quadrat counts") +
    ggplot2::theme_minimal(base_size = 11)
}

# --- Neighbourhood enrichment -----------------------------------------------

#' @export
print.phenoscapR_enrichment <- function(x, ...) {
  cat("<phenoscapR> Neighbourhood enrichment (permutation test)\n")
  d <- as.data.frame(x)
  top <- d[order(-d$z_score), ][seq_len(min(5L, nrow(d))), ]
  cat("  top co-localised pairs (by z-score):\n")
  print(top[, c("from", "to", "z_score", "p_value")], row.names = FALSE)
  invisible(x)
}

#' @exportS3Method ggplot2::autoplot
autoplot.phenoscapR_enrichment <- function(object, ...) {
  d <- as.data.frame(object)
  lim <- max(abs(d$z_score), na.rm = TRUE)
  ggplot2::ggplot(d, ggplot2::aes(.data$to, .data$from, fill = .data$z_score)) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::scale_fill_gradient2(low = "#3b4cc0", mid = "white",
                                  high = "#b40426", midpoint = 0,
                                  limits = c(-lim, lim)) +
    ggplot2::coord_equal() +
    ggplot2::labs(x = NULL, y = NULL, fill = "z",
                  title = "Neighbourhood enrichment") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}

# --- Interaction matrix ------------------------------------------------------

#' @export
print.phenoscapR_interaction <- function(x, ...) {
  cat("<phenoscapR> Phenotype interaction matrix\n")
  d <- as.data.frame(x)
  np <- length(unique(d$from))
  cat(sprintf("  %d phenotypes; score = log2(observed / expected)\n", np))
  top <- d[order(-d$interaction_score), ][seq_len(min(5L, nrow(d))), ]
  cat("  strongest attractions:\n")
  print(top[, c("from", "to", "interaction_score")], row.names = FALSE)
  invisible(x)
}

#' @exportS3Method ggplot2::autoplot
autoplot.phenoscapR_interaction <- function(object, ...) {
  InteractionPlot(as.data.frame(object))
}

# --- Cross nearest-neighbour distance ---------------------------------------

#' @export
print.phenoscapR_crossnn <- function(x, ...) {
  cat("<phenoscapR> Cross nearest-neighbour distances\n")
  cat(sprintf("  %s -> %s : %d cells\n", attr(x, "from") %||% "?",
              attr(x, "to") %||% "?", length(x)))
  cat(sprintf("  median %.3g, mean %.3g, range [%.3g, %.3g]\n",
              stats::median(x), mean(x), min(x), max(x)))
  invisible(x)
}

#' @exportS3Method ggplot2::autoplot
autoplot.phenoscapR_crossnn <- function(object, ...) {
  df <- data.frame(d = as.numeric(object))
  ggplot2::ggplot(df, ggplot2::aes(.data$d)) +
    ggplot2::geom_histogram(bins = 40, fill = "#3366cc", colour = "white") +
    ggplot2::labs(
      x = sprintf("distance: %s -> nearest %s",
                  attr(object, "from") %||% "from", attr(object, "to") %||% "to"),
      y = "cells", title = "Cross nearest-neighbour distances") +
    ggplot2::theme_minimal(base_size = 11)
}

# --- Per-sample result bundle ------------------------------------------------

#' @export
print.phenoscapR_by_sample <- function(x, ...) {
  cat("<phenoscapR> per-sample results (", length(x), " samples)\n", sep = "")
  inner <- setdiff(class(x[[1L]]), c("data.frame", "list", "numeric"))[1L]
  if (!is.na(inner)) cat("  each element: ", inner, "\n", sep = "")
  for (nm in names(x)) cat("  - ", nm, "\n", sep = "")
  cat("Access a sample with result[[\"", names(x)[1L], "\"]].\n", sep = "")
  invisible(x)
}

# Null-coalescing helper.
`%||%` <- function(a, b) if (is.null(a)) b else a
