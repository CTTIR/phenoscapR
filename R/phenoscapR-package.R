#' phenoscapR: Read, Analyse, and Visualise Akoya Spatial Biology Data
#'
#' @description
#' Tools for reading, processing, analysing, and visualising multiplexed
#' spatial biology data produced by Akoya Biosciences platforms
#' (PhenoCycler, CODEX, PhenoImager) and QuPath.
#'
#' The package centres on the [AkoyaExperiment] S4 class, which stores
#' raw and normalised marker intensities, spatial coordinates, and cell
#' metadata in a single object. All analysis functions accept and return
#' this object, enabling a pipe-friendly workflow.
#'
#' @section Data input:
#' \itemize{
#'   \item [ReadAkoya()] -- reads CSV files with auto-detection or
#'     explicit format (\code{processor}, \code{inform}, \code{qupath})
#'   \item [CreateAkoyaObject()] -- constructs from existing matrices
#' }
#'
#' @section Processing:
#' \itemize{
#'   \item [QCFilter()] -- quality control by area/intensity
#'   \item [NormaliseData()] -- zscore, minmax, or quantile normalisation
#'   \item [PhenotypeCells()] -- threshold-based cell phenotyping
#'   \item [PhenotypeSummary()] -- composition summary by sample
#' }
#'
#' @section Spatial analysis:
#' \itemize{
#'   \item [FindNeighbours()] -- nearest neighbour distances
#'   \item [CellDensity()] -- local cell density
#'   \item [InteractionMatrix()] -- pairwise phenotype interaction scores
#'   \item [NeighbourhoodEnrichment()] -- permutation-based enrichment test
#'   \item [RipleysK()] -- Ripley's K and Besag's L functions
#'   \item [PairCorrelation()] -- pair correlation function g(r)
#'   \item [MoransI()] -- spatial autocorrelation statistic
#'   \item [QuadratAnalysis()] -- quadrat-based CSR test
#'   \item [CrossNNDistance()] -- cross-type nearest neighbour distances
#'   \item [DelaunayNetwork()] -- Delaunay triangulation graph
#'   \item [SpatialClusters()] -- coordinate-based clustering
#'   \item [ExpressionClusters()] -- marker expression-based clustering
#' }
#'
#' @section Visualisation:
#' \itemize{
#'   \item [CellMap()] -- spatial scatter plot by metadata
#'   \item [FeaturePlot()] -- marker expression in tissue space
#'   \item [DensityPlot()] -- density-coloured spatial plot
#'   \item [SpatialNetworkPlot()] -- Delaunay/graph network on tissue
#'   \item [ViolinPlot()] -- marker expression distributions
#'   \item [BoxPlot()] -- marker expression box plots
#'   \item [RidgePlot()] -- ridge/joy plots
#'   \item [DotPlot()] -- dot plot (pct expressing + mean expression)
#'   \item [CompositionPlot()] -- stacked bar composition plot
#'   \item [MarkerHeatmap()] -- mean intensity heatmap
#'   \item [InteractionPlot()] -- interaction score heatmap
#'   \item [HistogramPlot()] -- expression histograms
#'   \item [QCPlot()] -- QC scatter plots
#' }
#'
#' @section Colour palettes:
#' \itemize{
#'   \item [SetPalette()] / [GetPalette()] -- global palette setting
#'   \item [PaletteContinuous()] / [PaletteDiscrete()] -- generate colours
#'   \item [CustomGradient()] -- custom 2-3 colour gradient function
#' }
#'
#' @section Typical workflow:
#' \preformatted{
#' obj <- ReadAkoya("segmentation.csv", type = "qupath") |>
#'   QCFilter(min_area = 50, max_area = 500) |>
#'   NormaliseData(method = "zscore") |>
#'   PhenotypeCells(thresholds = list(CD3 = 0.5, CD8 = 0.3)) |>
#'   FindNeighbours(k = 5) |>
#'   CellDensity(radius = 50) |>
#'   DelaunayNetwork()
#'
#' SetPalette("viridis")
#' CellMap(obj)
#' FeaturePlot(obj, features = c("CD3", "CD8"))
#' ViolinPlot(obj, features = c("CD3", "CD8"))
#' DotPlot(obj, features = Markers(obj))
#' CompositionPlot(obj)
#' SpatialNetworkPlot(obj)
#' }
#'
#' @docType package
#' @name phenoscapR-package
#' @aliases phenoscapR
#' @keywords internal
"_PACKAGE"
