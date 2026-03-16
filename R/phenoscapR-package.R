#' @keywords internal
"_PACKAGE"

#' @importFrom data.table data.table as.data.table fread setnames := .SD .N
#'   .I .GRP .BY .EACHI .NGRP
#' @importFrom ggplot2 ggplot aes geom_point geom_tile labs theme theme_minimal
#'   coord_fixed scale_colour_manual scale_colour_viridis_c
#'   scale_fill_gradient2 scale_fill_viridis_c
#'   scale_size_continuous element_blank .data
#' @importFrom data.table melt setcolorder copy
#' @importFrom stats dist hclust kmeans median quantile sd cutree
#' @importFrom grDevices colorRampPalette
#' @importFrom stats pnorm pchisq var
#' @importFrom utils head
NULL

# Suppress R CMD check NOTEs for data.table columns used in NSE
utils::globalVariables(c(
  "cell_id", "cluster", "count", "density", "expected",
  "interaction_score", "nn_distance", "observed", "phenotype",
  "proportion", "sample_id"
))
