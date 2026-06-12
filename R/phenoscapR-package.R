#' @keywords internal
"_PACKAGE"

#' @importFrom data.table data.table as.data.table fread setnames := .SD .N .I
#' @importFrom data.table .GRP .BY .EACHI .NGRP melt setcolorder copy
#' @importFrom ggplot2 ggplot aes geom_point geom_tile labs theme theme_minimal
#' @importFrom ggplot2 coord_fixed scale_colour_manual scale_fill_gradient2
#' @importFrom ggplot2 scale_size_continuous element_blank .data
#' @importFrom stats dist hclust kmeans median quantile sd cutree pnorm pchisq var
#' @importFrom grDevices colorRampPalette
#' @importFrom utils head
NULL

# Suppress R CMD check NOTEs for data.table columns used in NSE
utils::globalVariables(c(
  "cell_id", "classification", "cluster", "count", "density", "expected",
  "feature", "interaction_score", "mean_intensity", "nn_distance",
  "observed", "phenotype", "proportion", "sample_id"
))
