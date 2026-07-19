# Package index

## The SpatialCellData Object

S4 class representing a single-cell spatial biology experiment. Stores
raw and normalised expression matrices, spatial coordinates, cell
metadata, and spatial analysis results. Accessor methods let you
interrogate and subset the object without touching slots directly.

- [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  : The SpatialCellData Class
- [`CreateSpatialObject()`](https://cttir.github.io/phenoscapR/reference/CreateSpatialObject.md)
  : Create a SpatialCellData Object from Existing Data
- [`ReadSpatial()`](https://cttir.github.io/phenoscapR/reference/ReadSpatial.md)
  : Read Cell Segmentation Data into a SpatialCellData Object
- [`NCells()`](https://cttir.github.io/phenoscapR/reference/NCells.md) :
  Get the Number of Cells
- [`NMarkers()`](https://cttir.github.io/phenoscapR/reference/NMarkers.md)
  : Get the Number of Markers
- [`Markers()`](https://cttir.github.io/phenoscapR/reference/Markers.md)
  : Get Marker Names
- [`Coords()`](https://cttir.github.io/phenoscapR/reference/Coords.md) :
  Get Spatial Coordinates
- [`Meta()`](https://cttir.github.io/phenoscapR/reference/Meta.md) : Get
  or Set Cell Metadata
- [`GetData()`](https://cttir.github.io/phenoscapR/reference/GetData.md)
  : Get Expression Data
- [`Idents()`](https://cttir.github.io/phenoscapR/reference/Idents.md) :
  Get Active Cell Identities
- [`Embeddings()`](https://cttir.github.io/phenoscapR/reference/Embeddings.md)
  : Get a Dimensionality-Reduction Embedding
- [`Reductions()`](https://cttir.github.io/phenoscapR/reference/Reductions.md)
  : List Available Reductions
- [`` `$`( ``*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/reference/cash-SpatialCellData-method.md)
  : Access Metadata Columns with \$
- [`dim(`*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/reference/dim-SpatialCellData-method.md)
  : Get Dimensions of a SpatialCellData Object
- [`show(`*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/reference/show-SpatialCellData-method.md)
  : Show a SpatialCellData Object
- [`` `[`( ``*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/reference/sub-SpatialCellData-method.md)
  : Subset a SpatialCellData Object
- [`` `[[`( ``*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/reference/sub-sub-SpatialCellData-method.md)
  : Access Metadata Columns with \[\[

## Data Import

Read cell segmentation CSV files from spatial imaging platforms and
image analysis software. Three formats are auto-detected: QuPath Full
Export, QuPath Minimal, and flat segmentation format.

- [`read_spatial()`](https://cttir.github.io/phenoscapR/reference/read_spatial.md)
  : Read Single-Cell Spatial Biology Data

## Quality Control & Preprocessing

Filter cells by area and intensity thresholds, normalise marker
intensities, and inspect QC distributions before downstream analysis.

- [`qc_filter()`](https://cttir.github.io/phenoscapR/reference/qc_filter.md)
  : Quality Control Filter
- [`QCFilter()`](https://cttir.github.io/phenoscapR/reference/QCFilter.md)
  : Quality Control Filter (SpatialCellData)
- [`normalise_markers()`](https://cttir.github.io/phenoscapR/reference/normalise_markers.md)
  : Normalise Marker Intensities
- [`NormaliseData()`](https://cttir.github.io/phenoscapR/reference/NormaliseData.md)
  : Normalise Marker Intensities (SpatialCellData)
- [`QCPlot()`](https://cttir.github.io/phenoscapR/reference/QCPlot.md) :
  QC Scatter Plot

## Phenotyping

Assign discrete phenotype labels to cells based on marker intensity
thresholds and summarise phenotype composition per sample.

- [`phenotype_cells()`](https://cttir.github.io/phenoscapR/reference/phenotype_cells.md)
  : Phenotype Cells by Marker Thresholds
- [`PhenotypeCells()`](https://cttir.github.io/phenoscapR/reference/PhenotypeCells.md)
  : Phenotype Cells (SpatialCellData)
- [`summarise_phenotypes()`](https://cttir.github.io/phenoscapR/reference/summarise_phenotypes.md)
  : Summarise Phenotype Proportions
- [`PhenotypeSummary()`](https://cttir.github.io/phenoscapR/reference/PhenotypeSummary.md)
  : Phenotype Summary (SpatialCellData)

## Spatial Analysis

Compute spatial statistics including nearest-neighbour distances, local
cell density, pairwise interaction matrices, spatial clustering,
Delaunay networks, neighbourhood enrichment, Ripley’s K, Moran’s I,
quadrat analysis, pair correlation, cross-nearest-neighbour distances,
and expression-based clustering.

- [`nearest_neighbours()`](https://cttir.github.io/phenoscapR/reference/nearest_neighbours.md)
  : Compute Nearest Neighbour Distances
- [`FindNeighbours()`](https://cttir.github.io/phenoscapR/reference/FindNeighbours.md)
  : Find Nearest Neighbours (SpatialCellData)
- [`cell_density()`](https://cttir.github.io/phenoscapR/reference/cell_density.md)
  : Compute Cell Density
- [`CellDensity()`](https://cttir.github.io/phenoscapR/reference/CellDensity.md)
  : Cell Density (SpatialCellData)
- [`interaction_matrix()`](https://cttir.github.io/phenoscapR/reference/interaction_matrix.md)
  : Spatial Interaction Matrix
- [`InteractionMatrix()`](https://cttir.github.io/phenoscapR/reference/InteractionMatrix.md)
  : Interaction Matrix (SpatialCellData)
- [`spatial_clusters()`](https://cttir.github.io/phenoscapR/reference/spatial_clusters.md)
  : Spatial Cell Clustering
- [`SpatialClusters()`](https://cttir.github.io/phenoscapR/reference/SpatialClusters.md)
  : Spatial Clusters (SpatialCellData)
- [`DelaunayNetwork()`](https://cttir.github.io/phenoscapR/reference/DelaunayNetwork.md)
  : Delaunay Triangulation Network
- [`NeighbourhoodEnrichment()`](https://cttir.github.io/phenoscapR/reference/NeighbourhoodEnrichment.md)
  : Neighbourhood Enrichment Analysis
- [`RipleysK()`](https://cttir.github.io/phenoscapR/reference/RipleysK.md)
  : Ripley's K Function
- [`MoransI()`](https://cttir.github.io/phenoscapR/reference/MoransI.md)
  : Moran's I Spatial Autocorrelation
- [`QuadratAnalysis()`](https://cttir.github.io/phenoscapR/reference/QuadratAnalysis.md)
  : Quadrat Analysis
- [`PairCorrelation()`](https://cttir.github.io/phenoscapR/reference/PairCorrelation.md)
  : Pair Correlation Function
- [`CrossNNDistance()`](https://cttir.github.io/phenoscapR/reference/CrossNNDistance.md)
  : Cross Nearest Neighbour Distance
- [`ExpressionClusters()`](https://cttir.github.io/phenoscapR/reference/ExpressionClusters.md)
  : Expression-Based Cell Clustering

## Cellular Neighbourhoods & Domains

Higher-order spatial structure: group cells into cellular neighbourhoods
(niches) by the phenotype composition of their local neighbourhood, or
into spatial domains by their spatially smoothed expression. Annotate
unsupervised clusters by their most enriched markers.

- [`CellularNeighbourhoods()`](https://cttir.github.io/phenoscapR/reference/CellularNeighbourhoods.md)
  : Cellular Neighbourhoods (Niches)
- [`SpatialDomains()`](https://cttir.github.io/phenoscapR/reference/SpatialDomains.md)
  : Spatial Domains
- [`AnnotateClusters()`](https://cttir.github.io/phenoscapR/reference/AnnotateClusters.md)
  : Annotate Clusters by Their Top Markers

## Differential Testing

Compare phenotype composition across experimental conditions, using the
sample as the unit of replication.

- [`DifferentialAbundance()`](https://cttir.github.io/phenoscapR/reference/DifferentialAbundance.md)
  : Differential Abundance of Phenotypes Across Conditions

## Platform Readers

Import cell-level exports from imaging platforms. A general
expression-plus-coordinates reader underlies per-vendor convenience
wrappers for Xenium, CosMx, and MERSCOPE.

- [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/reference/ReadMatrixCoords.md)
  : Read an Expression Matrix and a Coordinate/Metadata Table
- [`ReadXenium()`](https://cttir.github.io/phenoscapR/reference/ReadXenium.md)
  : Read 10x Xenium Cell Output
- [`ReadCosMx()`](https://cttir.github.io/phenoscapR/reference/ReadCosMx.md)
  : Read NanoString CosMx Cell Output
- [`ReadMERSCOPE()`](https://cttir.github.io/phenoscapR/reference/ReadMERSCOPE.md)
  : Read Vizgen MERSCOPE Cell Output

## Interoperability

Convert to and from the wider single-cell ecosystem (Seurat and
SpatialExperiment).

- [`as_Seurat()`](https://cttir.github.io/phenoscapR/reference/as_Seurat.md)
  : Convert a SpatialCellData to a Seurat Object
- [`as_SpatialExperiment()`](https://cttir.github.io/phenoscapR/reference/as_SpatialExperiment.md)
  : Convert a SpatialCellData to a SpatialExperiment Object
- [`as_SpatialCellData()`](https://cttir.github.io/phenoscapR/reference/as_SpatialCellData.md)
  : Convert a Seurat or SpatialExperiment Object to SpatialCellData

## Dimensionality Reduction

Embed cells from their marker-expression profiles for visualisation. PCA
uses base R and is always available; UMAP, t-SNE, and SONG are optional
backends (uwot, Rtsne, and the CTTIR songR package). UMAP, t-SNE, and
SONG run on the top principal components by default.

- [`RunPCA()`](https://cttir.github.io/phenoscapR/reference/RunPCA.md) :
  Principal Component Analysis
- [`RunUMAP()`](https://cttir.github.io/phenoscapR/reference/RunUMAP.md)
  : UMAP Embedding
- [`RunTSNE()`](https://cttir.github.io/phenoscapR/reference/RunTSNE.md)
  : t-SNE Embedding
- [`RunSONG()`](https://cttir.github.io/phenoscapR/reference/RunSONG.md)
  : SONG Embedding
- [`Embeddings()`](https://cttir.github.io/phenoscapR/reference/Embeddings.md)
  : Get a Dimensionality-Reduction Embedding
- [`Reductions()`](https://cttir.github.io/phenoscapR/reference/Reductions.md)
  : List Available Reductions
- [`VarianceExplained()`](https://cttir.github.io/phenoscapR/reference/VarianceExplained.md)
  : Variance Explained by Principal Components
- [`EmbeddingPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md)
  [`DimPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md)
  : Plot a Dimensionality-Reduction Embedding
- [`ScreePlot()`](https://cttir.github.io/phenoscapR/reference/ScreePlot.md)
  : Scree Plot of PCA Variance

## Visualisation

Publication-ready ggplot2 visualisations for cell maps, marker
intensities, phenotype composition, spatial networks, and interaction
heatmaps. High-level S4 methods work directly on a SpatialCellData
object; lower-level helpers accept data.tables.

- [`CellMap()`](https://cttir.github.io/phenoscapR/reference/CellMap.md)
  : Plot Cell Map
- [`FeaturePlot()`](https://cttir.github.io/phenoscapR/reference/FeaturePlot.md)
  : Feature Plot in Tissue Space
- [`DensityPlot()`](https://cttir.github.io/phenoscapR/reference/DensityPlot.md)
  : Plot Cell Density
- [`SpatialNetworkPlot()`](https://cttir.github.io/phenoscapR/reference/SpatialNetworkPlot.md)
  : Plot Spatial Network
- [`InteractionPlot()`](https://cttir.github.io/phenoscapR/reference/InteractionPlot.md)
  : Plot Spatial Interaction Heatmap
- [`MarkerHeatmap()`](https://cttir.github.io/phenoscapR/reference/MarkerHeatmap.md)
  : Plot Marker Heatmap
- [`ViolinPlot()`](https://cttir.github.io/phenoscapR/reference/ViolinPlot.md)
  : Violin Plot of Marker Expression
- [`BoxPlot()`](https://cttir.github.io/phenoscapR/reference/BoxPlot.md)
  : Box Plot of Marker Expression
- [`DotPlot()`](https://cttir.github.io/phenoscapR/reference/DotPlot.md)
  : Dot Plot of Marker Expression
- [`CompositionPlot()`](https://cttir.github.io/phenoscapR/reference/CompositionPlot.md)
  : Stacked Bar Plot of Phenotype Composition
- [`RidgePlot()`](https://cttir.github.io/phenoscapR/reference/RidgePlot.md)
  : Ridge Plot of Marker Expression
- [`HistogramPlot()`](https://cttir.github.io/phenoscapR/reference/HistogramPlot.md)
  : Histogram of Marker Expression
- [`QCPlot()`](https://cttir.github.io/phenoscapR/reference/QCPlot.md) :
  QC Scatter Plot
- [`plot_cell_map()`](https://cttir.github.io/phenoscapR/reference/plot_cell_map.md)
  : Plot Cell Map
- [`plot_density()`](https://cttir.github.io/phenoscapR/reference/plot_density.md)
  : Plot Density Map
- [`plot_heatmap()`](https://cttir.github.io/phenoscapR/reference/plot_heatmap.md)
  : Plot Marker Heatmap
- [`plot_interactions()`](https://cttir.github.io/phenoscapR/reference/plot_interactions.md)
  : Plot Interaction Heatmap

## Colour Palettes

Manage the global colour palette used by all plotting functions.
Supports viridis options and custom gradients defined by 2-3 anchor
colours.

- [`SetPalette()`](https://cttir.github.io/phenoscapR/reference/SetPalette.md)
  [`GetPalette()`](https://cttir.github.io/phenoscapR/reference/SetPalette.md)
  : Set or Get the Default Colour Palette
- [`PaletteContinuous()`](https://cttir.github.io/phenoscapR/reference/PaletteContinuous.md)
  : Generate a Continuous Colour Palette Function
- [`PaletteDiscrete()`](https://cttir.github.io/phenoscapR/reference/PaletteDiscrete.md)
  : Generate Discrete Colours
- [`CustomGradient()`](https://cttir.github.io/phenoscapR/reference/CustomGradient.md)
  : Create a Custom Gradient Palette from Anchor Colours

## Shiny Application

Launch the interactive phenoscapR Shiny interface to run the full
analysis workflow and explore results with live plots and tables.

- [`run_app()`](https://cttir.github.io/phenoscapR/reference/run_app.md)
  : Launch the phenoscapR Shiny Application

## Datasets

Bundled example data used throughout the documentation and vignettes.

- [`phenoscapR_example`](https://cttir.github.io/phenoscapR/reference/phenoscapR_example.md)
  : Synthetic multiplexed-imaging example dataset
