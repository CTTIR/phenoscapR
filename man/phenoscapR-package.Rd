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
FeaturePlot(obj, features = c("CD3", "CD8"))
}
}
\section{Data import}{
\code{\link{ReadAkoya}}, \code{\link{CreateAkoyaObject}}
}
\section{Processing}{
\code{\link{QCFilter}}, \code{\link{NormaliseData}},
\code{\link{PhenotypeCells}}, \code{\link{PhenotypeSummary}}
}
\section{Spatial analysis}{
\code{\link{FindNeighbours}}, \code{\link{CellDensity}},
\code{\link{InteractionMatrix}}, \code{\link{SpatialClusters}},
\code{\link{DelaunayNetwork}}, \code{\link{NeighbourhoodEnrichment}},
\code{\link{RipleysK}}, \code{\link{MoransI}},
\code{\link{QuadratAnalysis}}, \code{\link{PairCorrelation}},
\code{\link{CrossNNDistance}}, \code{\link{ExpressionClusters}}
}
\section{Colour palettes}{
\code{\link{SetPalette}}, \code{\link{GetPalette}},
\code{\link{PaletteContinuous}}, \code{\link{PaletteDiscrete}},
\code{\link{CustomGradient}}
}
\section{Visualisation}{
\code{\link{CellMap}}, \code{\link{FeaturePlot}},
\code{\link{DensityPlot}}, \code{\link{InteractionPlot}},
\code{\link{MarkerHeatmap}}, \code{\link{ViolinPlot}},
\code{\link{BoxPlot}}, \code{\link{DotPlot}},
\code{\link{CompositionPlot}}, \code{\link{RidgePlot}},
\code{\link{SpatialNetworkPlot}}, \code{\link{HistogramPlot}},
\code{\link{QCPlot}}
}
\seealso{
\code{\link{AkoyaExperiment}}, \code{\link{ReadAkoya}},
\code{\link{CreateAkoyaObject}}, \code{\link{QCFilter}},
\code{\link{NormaliseData}}, \code{\link{PhenotypeCells}},
\code{\link{PhenotypeSummary}}, \code{\link{FindNeighbours}},
\code{\link{CellDensity}}, \code{\link{InteractionMatrix}},
\code{\link{SpatialClusters}}, \code{\link{CellMap}},
\code{\link{DensityPlot}}, \code{\link{InteractionPlot}},
\code{\link{MarkerHeatmap}}, \code{\link{SetPalette}},
\code{\link{PaletteContinuous}}, \code{\link{PaletteDiscrete}},
\code{\link{CustomGradient}}, \code{\link{FeaturePlot}},
\code{\link{ViolinPlot}}, \code{\link{BoxPlot}},
\code{\link{DotPlot}}, \code{\link{CompositionPlot}},
\code{\link{RidgePlot}}, \code{\link{SpatialNetworkPlot}},
\code{\link{HistogramPlot}}, \code{\link{QCPlot}},
\code{\link{DelaunayNetwork}}, \code{\link{NeighbourhoodEnrichment}},
\code{\link{RipleysK}}, \code{\link{MoransI}},
\code{\link{QuadratAnalysis}}, \code{\link{PairCorrelation}},
\code{\link{CrossNNDistance}}, \code{\link{ExpressionClusters}}
}
\keyword{internal}
