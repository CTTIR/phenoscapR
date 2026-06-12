# ============================================================================
# differential.R -- Cross-condition differential abundance testing
# ============================================================================

#' Differential Abundance of Phenotypes Across Conditions
#'
#' Tests whether the proportion of each phenotype differs between experimental
#' conditions. Proportions are computed per sample (the unit of replication),
#' then compared across the condition groups, so the test respects the
#' sample-level design rather than treating individual cells as independent.
#'
#' @param object A \code{\link{SpatialCellData-class}} object with several
#'   samples.
#' @param condition Character. Metadata column giving each cell's condition
#'   (constant within a sample).
#' @param phenotype_col Character. Phenotype column. Default \code{"phenotype"}.
#' @param test Character. \code{"wilcox"} (default) or \code{"t"} for two groups;
#'   \code{"kruskal"} for more than two.
#'
#' @return A classed data frame (\code{phenoscapR_diffabund}) with one row per
#'   phenotype: per-condition mean proportions, the test \code{statistic},
#'   \code{p_value}, and BH-adjusted \code{p_adj}.
#'
#' @examples
#' data(phenoscapR_example)
#' obj <- phenoscapR_example
#' obj@meta_data$phenotype <- obj@meta_data$phenotype_true
#' # Toy condition: label the two sections as different arms.
#' obj@meta_data$arm <- ifelse(obj$sample_id == "tonsil_A", "ctrl", "treat")
#' DifferentialAbundance(obj, condition = "arm")
#'
#' @export
DifferentialAbundance <- function(object, condition,
                                  phenotype_col = "phenotype",
                                  test = c("wilcox", "t", "kruskal")) {
  test <- match.arg(test)
  md <- object@meta_data
  if (!condition %in% names(md)) {
    stop("Condition column '", condition, "' not found.", call. = FALSE)
  }
  if (!phenotype_col %in% names(md)) {
    stop("Phenotype column '", phenotype_col, "' not found.", call. = FALSE)
  }

  prop <- prop.table(table(md$sample_id, md[[phenotype_col]]), margin = 1L)
  prop <- as.matrix(prop)
  samp_cond <- tapply(as.character(md[[condition]]), md$sample_id,
                      function(z) z[[1L]])
  cond <- factor(samp_cond[rownames(prop)])
  groups <- levels(cond)

  if (nlevels(cond) < 2L) {
    stop("Need at least two conditions; found ", nlevels(cond), ".",
         call. = FALSE)
  }
  if (test %in% c("wilcox", "t") && nlevels(cond) > 2L) {
    stop("test = \"", test, "\" supports exactly two conditions; use ",
         "\"kruskal\" for more.", call. = FALSE)
  }
  n_per <- table(cond)
  if (any(n_per < 2L)) {
    warning("Some conditions have fewer than 2 samples; p-values are ",
            "unreliable.", call. = FALSE)
  }

  phenos <- colnames(prop)
  rows <- lapply(phenos, function(ph) {
    vals <- prop[, ph]
    means <- tapply(vals, cond, mean)
    tt <- tryCatch(switch(test,
      wilcox  = stats::wilcox.test(vals ~ cond),
      t       = stats::t.test(vals ~ cond),
      kruskal = stats::kruskal.test(vals, cond)
    ), error = function(e) list(statistic = NA_real_, p.value = NA_real_))
    data.frame(phenotype = ph,
               statistic = unname(tt$statistic),
               p_value = tt$p.value, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  mean_mat <- t(vapply(phenos, function(ph) tapply(prop[, ph], cond, mean),
                       numeric(nlevels(cond))))
  colnames(mean_mat) <- paste0("mean_", groups)
  out <- cbind(out[, "phenotype", drop = FALSE], mean_mat,
               out[, c("statistic", "p_value")])
  out$p_adj <- stats::p.adjust(out$p_value, method = "BH")
  out <- out[order(out$p_value), ]
  rownames(out) <- NULL
  attr(out, "conditions") <- groups
  attr(out, "test") <- test
  .as_result(out, "phenoscapR_diffabund")
}

#' @export
print.phenoscapR_diffabund <- function(x, ...) {
  cat("<phenoscapR> Differential abundance (", attr(x, "test"),
      " test)\n", sep = "")
  cat("  conditions: ", paste(attr(x, "conditions"), collapse = " vs "), "\n",
      sep = "")
  sig <- sum(x$p_adj < 0.05, na.rm = TRUE)
  cat("  ", sig, " of ", nrow(x),
      " phenotypes differ at p_adj < 0.05\n", sep = "")
  print(utils::head(as.data.frame(x), 6L), row.names = FALSE)
  invisible(x)
}
