\name{phenoscapR-package}
\alias{phenoscapR-package}
\alias{phenoscapR}
\docType{package}
\title{phenoscapR: Read, Analyse, and Visualise Akoya Spatial Biology Data}
\description{
Tools for reading, processing, analysing, and visualising multiplexed
spatial biology data produced by Akoya Biosciences platforms
(PhenoCycler, CODEX, PhenoImager).

The package centres on the \code{\link{AkoyaExperiment}} S4 class, which stores
raw and normalised marker intensities, spatial coordinates, and cell
metadata in a single object. All analysis functions accept and return
this object, enabling a pipe-friendly workflow.
}
\section{Typical workflow}{
\preformatted{
obj <- ReadAkoya("segmentation.csv") |>
  QCFilter(min_area = 50, max_area = 500) |>
  NormaliseData(method = "zscore") |>
  PhenotypeCells(thresholds = list(CD3 = 0.5, CD8 = 0.3)) |>
  FindNeighbours(k = 5) |>
  CellDensity(radius = 50)

CellMap(obj)
}
}
\seealso{
\code{\link{AkoyaExperiment}}, \code{\link{ReadAkoya}},
\code{\link{CreateAkoyaObject}}, \code{\link{QCFilter}},
\code{\link{NormaliseData}}, \code{\link{PhenotypeCells}},
\code{\link{PhenotypeSummary}}, \code{\link{FindNeighbours}},
\code{\link{CellDensity}}, \code{\link{InteractionMatrix}},
\code{\link{SpatialClusters}}, \code{\link{CellMap}},
\code{\link{DensityPlot}}, \code{\link{InteractionPlot}},
\code{\link{MarkerHeatmap}}
}
\keyword{internal}
