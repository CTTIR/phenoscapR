# Package index

## The SpatialCellData Object

S4 class representing a single-cell spatial biology experiment. Stores
raw and normalised expression matrices, spatial coordinates, cell
metadata, and spatial analysis results. Accessor methods let you
interrogate and subset the object without touching slots directly.

- [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/dev/reference/SpatialCellData-class.md)
  : The SpatialCellData Class
- [`CreateSpatialObject()`](https://cttir.github.io/phenoscapR/dev/reference/CreateSpatialObject.md)
  : Create a SpatialCellData Object from Existing Data
- [`ReadSpatial()`](https://cttir.github.io/phenoscapR/dev/reference/ReadSpatial.md)
  : Read Cell Segmentation Data into a SpatialCellData Object
- [`NCells()`](https://cttir.github.io/phenoscapR/dev/reference/NCells.md)
  : Get the Number of Cells
- [`NMarkers()`](https://cttir.github.io/phenoscapR/dev/reference/NMarkers.md)
  : Get the Number of Markers
- [`Markers()`](https://cttir.github.io/phenoscapR/dev/reference/Markers.md)
  : Get Marker Names
- [`Coords()`](https://cttir.github.io/phenoscapR/dev/reference/Coords.md)
  : Get Spatial Coordinates
- [`Meta()`](https://cttir.github.io/phenoscapR/dev/reference/Meta.md) :
  Get or Set Cell Metadata
- [`GetData()`](https://cttir.github.io/phenoscapR/dev/reference/GetData.md)
  : Get Expression Data
- [`Idents()`](https://cttir.github.io/phenoscapR/dev/reference/Idents.md)
  : Get Active Cell Identities
- [`Embeddings()`](https://cttir.github.io/phenoscapR/dev/reference/Embeddings.md)
  : Get a Dimensionality-Reduction Embedding
- [`Reductions()`](https://cttir.github.io/phenoscapR/dev/reference/Reductions.md)
  : List Available Reductions
- [`` `$`( ``*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/dev/reference/cash-SpatialCellData-method.md)
  : Access Metadata Columns with \$
- [`dim(`*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/dev/reference/dim-SpatialCellData-method.md)
  : Get Dimensions of a SpatialCellData Object
- [`show(`*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/dev/reference/show-SpatialCellData-method.md)
  : Show a SpatialCellData Object
- [`` `[`( ``*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/dev/reference/sub-SpatialCellData-method.md)
  : Subset a SpatialCellData Object
- [`` `[[`( ``*`<SpatialCellData>`*`)`](https://cttir.github.io/phenoscapR/dev/reference/sub-sub-SpatialCellData-method.md)
  : Access Metadata Columns with \[\[

## Data Import

Read cell segmentation CSV files from spatial imaging platforms and
image analysis software. Three formats are auto-detected: QuPath Full
Export, QuPath Minimal, and flat segmentation format.

- [`read_spatial()`](https://cttir.github.io/phenoscapR/dev/reference/read_spatial.md)
  : Read Single-Cell Spatial Biology Data
- [`FromCellspec()`](https://cttir.github.io/phenoscapR/dev/reference/FromCellspec.md)
  : Import a Canonical Cell Table Without Losing Spatial Identity

## Quality Control & Preprocessing

Filter cells by area and intensity thresholds, normalise marker
intensities, and inspect QC distributions before downstream analysis.

- [`qc_filter()`](https://cttir.github.io/phenoscapR/dev/reference/qc_filter.md)
  : Quality Control Filter
- [`QCFilter()`](https://cttir.github.io/phenoscapR/dev/reference/QCFilter.md)
  : Quality Control Filter (SpatialCellData)
- [`normalise_markers()`](https://cttir.github.io/phenoscapR/dev/reference/normalise_markers.md)
  : Normalise Marker Intensities
- [`NormaliseData()`](https://cttir.github.io/phenoscapR/dev/reference/NormaliseData.md)
  : Normalise Marker Intensities (SpatialCellData)
- [`QCPlot()`](https://cttir.github.io/phenoscapR/dev/reference/QCPlot.md)
  : QC Scatter Plot

## Phenotyping

Assign discrete phenotype labels to cells based on marker intensity
thresholds and summarise phenotype composition per sample.

- [`phenotype_cells()`](https://cttir.github.io/phenoscapR/dev/reference/phenotype_cells.md)
  : Phenotype Cells by Marker Thresholds
- [`PhenotypeCells()`](https://cttir.github.io/phenoscapR/dev/reference/PhenotypeCells.md)
  : Phenotype Cells (SpatialCellData)
- [`summarise_phenotypes()`](https://cttir.github.io/phenoscapR/dev/reference/summarise_phenotypes.md)
  : Summarise Phenotype Proportions
- [`PhenotypeSummary()`](https://cttir.github.io/phenoscapR/dev/reference/PhenotypeSummary.md)
  : Phenotype Summary (SpatialCellData)

## Spatial Analysis

Compute spatial statistics including nearest-neighbour distances, local
cell density, pairwise interaction matrices, spatial clustering,
Delaunay networks, neighbourhood enrichment, Ripley’s K, Moran’s I,
quadrat analysis, pair correlation, cross-nearest-neighbour distances,
and expression-based clustering.

- [`nearest_neighbours()`](https://cttir.github.io/phenoscapR/dev/reference/nearest_neighbours.md)
  : Compute Nearest Neighbour Distances
- [`FindNeighbours()`](https://cttir.github.io/phenoscapR/dev/reference/FindNeighbours.md)
  : Find Nearest Neighbours (SpatialCellData)
- [`cell_density()`](https://cttir.github.io/phenoscapR/dev/reference/cell_density.md)
  : Compute Cell Density
- [`CellDensity()`](https://cttir.github.io/phenoscapR/dev/reference/CellDensity.md)
  : Cell Density (SpatialCellData)
- [`interaction_matrix()`](https://cttir.github.io/phenoscapR/dev/reference/interaction_matrix.md)
  : Spatial Interaction Matrix
- [`InteractionMatrix()`](https://cttir.github.io/phenoscapR/dev/reference/InteractionMatrix.md)
  : Interaction Matrix (SpatialCellData)
- [`spatial_clusters()`](https://cttir.github.io/phenoscapR/dev/reference/spatial_clusters.md)
  : Spatial Cell Clustering
- [`SpatialClusters()`](https://cttir.github.io/phenoscapR/dev/reference/SpatialClusters.md)
  : Spatial Clusters (SpatialCellData)
- [`DelaunayNetwork()`](https://cttir.github.io/phenoscapR/dev/reference/DelaunayNetwork.md)
  : Delaunay Triangulation Network
- [`NeighbourhoodEnrichment()`](https://cttir.github.io/phenoscapR/dev/reference/NeighbourhoodEnrichment.md)
  : Neighbourhood Enrichment Analysis
- [`RipleysK()`](https://cttir.github.io/phenoscapR/dev/reference/RipleysK.md)
  : Ripley's K Function
- [`MoransI()`](https://cttir.github.io/phenoscapR/dev/reference/MoransI.md)
  : Moran's I Spatial Autocorrelation
- [`QuadratAnalysis()`](https://cttir.github.io/phenoscapR/dev/reference/QuadratAnalysis.md)
  : Quadrat Analysis
- [`AssignFixedGrid()`](https://cttir.github.io/phenoscapR/dev/reference/AssignFixedGrid.md)
  : Assign Physical Cell Coordinates to Fixed Square Grids
- [`SummarizeFixedGrid()`](https://cttir.github.io/phenoscapR/dev/reference/SummarizeFixedGrid.md)
  : Summarize Cell Annotations Within Fixed Grids
- [`SummarizeGroupedCountFractions()`](https://cttir.github.io/phenoscapR/dev/reference/SummarizeGroupedCountFractions.md)
  : Summarize Grouped Subset Counts as Fractions
- [`CompleteRegisteredValues()`](https://cttir.github.io/phenoscapR/dev/reference/CompleteRegisteredValues.md)
  : Complete Numeric Observations Against an Explicit Registry
- [`ProjectSpatialTable()`](https://cttir.github.io/phenoscapR/dev/reference/ProjectSpatialTable.md)
  : Project Spatial Tables Without Changing Column Metadata
- [`ApplyGroupedThresholds()`](https://cttir.github.io/phenoscapR/dev/reference/ApplyGroupedThresholds.md)
  : Apply Supplied Group Thresholds to Observations
- [`SummarizeGroupedValues()`](https://cttir.github.io/phenoscapR/dev/reference/SummarizeGroupedValues.md)
  : Summarize Continuous Observations in Explicit Groups
- [`AssemblePairedSummaries()`](https://cttir.github.io/phenoscapR/dev/reference/AssemblePairedSummaries.md)
  : Assemble Registered Paired Summaries
- [`CorrelateGroupedRanks()`](https://cttir.github.io/phenoscapR/dev/reference/CorrelateGroupedRanks.md)
  : Correlate Paired Ranks Within Explicit Groups
- [`ContrastGroupedRanks()`](https://cttir.github.io/phenoscapR/dev/reference/ContrastGroupedRanks.md)
  : Compare Two Distributions Within Explicit Groups
- [`CountDisjointEdges()`](https://cttir.github.io/phenoscapR/dev/reference/CountDisjointEdges.md)
  : Count Undirected Edges Between Disjoint Node Sets
- [`CountRadiusSets()`](https://cttir.github.io/phenoscapR/dev/reference/CountRadiusSets.md)
  : Count Reference Sets Within Explicit Euclidean Radii
- [`BuildExactDelaunayEdges()`](https://cttir.github.io/phenoscapR/dev/reference/BuildExactDelaunayEdges.md)
  : Build Explicitly Ordered Delaunay Graphs
- [`PlanExactDelaunayWorkspace()`](https://cttir.github.io/phenoscapR/dev/reference/PlanExactDelaunayWorkspace.md)
  : Preflight Integer Workspace Bounds for Exact Delaunay Construction
- [`ContrastGroupedOverlap()`](https://cttir.github.io/phenoscapR/dev/reference/ContrastGroupedOverlap.md)
  : Contrast Explicit Groups Within Finite-Metric Overlap Strata
- [`PairCorrelation()`](https://cttir.github.io/phenoscapR/dev/reference/PairCorrelation.md)
  : Pair Correlation Function
- [`CrossNNDistance()`](https://cttir.github.io/phenoscapR/dev/reference/CrossNNDistance.md)
  : Cross Nearest Neighbour Distance
- [`ExpressionClusters()`](https://cttir.github.io/phenoscapR/dev/reference/ExpressionClusters.md)
  : Expression-Based Cell Clustering

## Cellular Neighbourhoods & Domains

Higher-order spatial structure: group cells into cellular neighbourhoods
(niches) by the phenotype composition of their local neighbourhood, or
into spatial domains by their spatially smoothed expression. Annotate
unsupervised clusters by their most enriched markers.

- [`CellularNeighbourhoods()`](https://cttir.github.io/phenoscapR/dev/reference/CellularNeighbourhoods.md)
  : Cellular Neighbourhoods (Niches)
- [`SpatialDomains()`](https://cttir.github.io/phenoscapR/dev/reference/SpatialDomains.md)
  : Spatial Domains
- [`AnnotateClusters()`](https://cttir.github.io/phenoscapR/dev/reference/AnnotateClusters.md)
  : Annotate Clusters by Their Top Markers

## Differential Testing

Compare phenotype composition across experimental conditions, using the
sample as the unit of replication.

- [`DifferentialAbundance()`](https://cttir.github.io/phenoscapR/dev/reference/DifferentialAbundance.md)
  : Differential Abundance of Phenotypes Across Conditions
- [`ExactPatientTests()`](https://cttir.github.io/phenoscapR/dev/reference/ExactPatientTests.md)
  : Exact Allocation Tests of Independent Patient Endpoints
- [`LeaveOnePatientOut()`](https://cttir.github.io/phenoscapR/dev/reference/LeaveOnePatientOut.md)
  : Exact Patient Omission Diagnostics for Declared Hypotheses
- [`AdjustPatientFamilies()`](https://cttir.github.io/phenoscapR/dev/reference/AdjustPatientFamilies.md)
  : Adjust Explicitly Declared Patient-Test Families
- [`ContrastPatientEndpoints()`](https://cttir.github.io/phenoscapR/dev/reference/ContrastPatientEndpoints.md)
  : Exact Two-Group Contrasts for a Registry of Patient Endpoints
- [`ExactPairedTests()`](https://cttir.github.io/phenoscapR/dev/reference/ExactPairedTests.md)
  : Exact Paired Sign-Flip Tests of Within-Subject Differences
- [`PairedDifferences()`](https://cttir.github.io/phenoscapR/dev/reference/PairedDifferences.md)
  : Build Paired Differences from Wide Subject Tables
- [`BootstrapMedianInterval()`](https://cttir.github.io/phenoscapR/dev/reference/BootstrapMedianInterval.md)
  : Bootstrap Percentile Interval of a Median
- [`PermutationCorrelation()`](https://cttir.github.io/phenoscapR/dev/reference/PermutationCorrelation.md)
  : Permutation Test of a Rank or Linear Correlation

## Section Summaries and Parity Checks

Read cell tables from NumPy archives, summarise sections (nearest-target
distances, composition, densities, Delaunay neighbour types) and compare
recomputed tables or arrays with reference results by key and tolerance.

- [`SummarizeNearestDistances()`](https://cttir.github.io/phenoscapR/dev/reference/SummarizeNearestDistances.md)
  : Nearest-Target Distances Summarised per Cell Set
- [`SummarizeCellComposition()`](https://cttir.github.io/phenoscapR/dev/reference/SummarizeCellComposition.md)
  : Cell-Type Composition, Densities and Declared State Fractions of a
  Section
- [`NeighbourTypeCounts()`](https://cttir.github.io/phenoscapR/dev/reference/NeighbourTypeCounts.md)
  : Count Neighbour Types over a Delaunay Graph with an Edge-Length Cut
- [`CompareTables()`](https://cttir.github.io/phenoscapR/dev/reference/CompareTables.md)
  : Compare a Recomputed Table with a Reference Table by Key
- [`CompareArrays()`](https://cttir.github.io/phenoscapR/dev/reference/CompareArrays.md)
  : Compare Table Columns or Arrays with Arrays of a NumPy Archive
- [`SummarizeComparisons()`](https://cttir.github.io/phenoscapR/dev/reference/SummarizeComparisons.md)
  : Summarise Comparison Results into Pass/Fail Checks

## Platform Readers

Import cell-level exports from imaging platforms. A general
expression-plus-coordinates reader underlies per-vendor convenience
wrappers for Xenium, CosMx, and MERSCOPE.

- [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/dev/reference/ReadMatrixCoords.md)
  : Read an Expression Matrix and a Coordinate/Metadata Table
- [`ReadXenium()`](https://cttir.github.io/phenoscapR/dev/reference/ReadXenium.md)
  : Read 10x Xenium Cell Output
- [`ReadCosMx()`](https://cttir.github.io/phenoscapR/dev/reference/ReadCosMx.md)
  : Read NanoString CosMx Cell Output
- [`ReadMERSCOPE()`](https://cttir.github.io/phenoscapR/dev/reference/ReadMERSCOPE.md)
  : Read Vizgen MERSCOPE Cell Output

## Interoperability

Convert to and from the wider single-cell ecosystem (Seurat and
SpatialExperiment).

- [`as_Seurat()`](https://cttir.github.io/phenoscapR/dev/reference/as_Seurat.md)
  : Convert a SpatialCellData to a Seurat Object
- [`as_SpatialExperiment()`](https://cttir.github.io/phenoscapR/dev/reference/as_SpatialExperiment.md)
  : Convert a SpatialCellData to a SpatialExperiment Object
- [`as_SpatialCellData()`](https://cttir.github.io/phenoscapR/dev/reference/as_SpatialCellData.md)
  : Convert a Seurat or SpatialExperiment Object to SpatialCellData

## Dimensionality Reduction

Embed cells from their marker-expression profiles for visualisation. PCA
uses base R and is always available; UMAP, t-SNE, and SONG are optional
backends (uwot, Rtsne, and the CTTIR songR package). UMAP, t-SNE, and
SONG run on the top principal components by default.

- [`RunPCA()`](https://cttir.github.io/phenoscapR/dev/reference/RunPCA.md)
  : Principal Component Analysis
- [`RunUMAP()`](https://cttir.github.io/phenoscapR/dev/reference/RunUMAP.md)
  : UMAP Embedding
- [`RunTSNE()`](https://cttir.github.io/phenoscapR/dev/reference/RunTSNE.md)
  : t-SNE Embedding
- [`RunSONG()`](https://cttir.github.io/phenoscapR/dev/reference/RunSONG.md)
  : SONG Embedding
- [`Embeddings()`](https://cttir.github.io/phenoscapR/dev/reference/Embeddings.md)
  : Get a Dimensionality-Reduction Embedding
- [`Reductions()`](https://cttir.github.io/phenoscapR/dev/reference/Reductions.md)
  : List Available Reductions
- [`VarianceExplained()`](https://cttir.github.io/phenoscapR/dev/reference/VarianceExplained.md)
  : Variance Explained by Principal Components
- [`EmbeddingPlot()`](https://cttir.github.io/phenoscapR/dev/reference/EmbeddingPlot.md)
  [`DimPlot()`](https://cttir.github.io/phenoscapR/dev/reference/EmbeddingPlot.md)
  : Plot a Dimensionality-Reduction Embedding
- [`ScreePlot()`](https://cttir.github.io/phenoscapR/dev/reference/ScreePlot.md)
  : Scree Plot of PCA Variance

## Visualisation

Publication-ready ggplot2 visualisations for cell maps, marker
intensities, phenotype composition, spatial networks, and interaction
heatmaps. High-level S4 methods work directly on a SpatialCellData
object; lower-level helpers accept data.tables.

- [`CellMap()`](https://cttir.github.io/phenoscapR/dev/reference/CellMap.md)
  : Plot Cell Map
- [`FeaturePlot()`](https://cttir.github.io/phenoscapR/dev/reference/FeaturePlot.md)
  : Feature Plot in Tissue Space
- [`DensityPlot()`](https://cttir.github.io/phenoscapR/dev/reference/DensityPlot.md)
  : Plot Cell Density
- [`SpatialNetworkPlot()`](https://cttir.github.io/phenoscapR/dev/reference/SpatialNetworkPlot.md)
  : Plot Spatial Network
- [`InteractionPlot()`](https://cttir.github.io/phenoscapR/dev/reference/InteractionPlot.md)
  : Plot Spatial Interaction Heatmap
- [`MarkerHeatmap()`](https://cttir.github.io/phenoscapR/dev/reference/MarkerHeatmap.md)
  : Plot Marker Heatmap
- [`ViolinPlot()`](https://cttir.github.io/phenoscapR/dev/reference/ViolinPlot.md)
  : Violin Plot of Marker Expression
- [`BoxPlot()`](https://cttir.github.io/phenoscapR/dev/reference/BoxPlot.md)
  : Box Plot of Marker Expression
- [`DotPlot()`](https://cttir.github.io/phenoscapR/dev/reference/DotPlot.md)
  : Dot Plot of Marker Expression
- [`CompositionPlot()`](https://cttir.github.io/phenoscapR/dev/reference/CompositionPlot.md)
  : Stacked Bar Plot of Phenotype Composition
- [`RidgePlot()`](https://cttir.github.io/phenoscapR/dev/reference/RidgePlot.md)
  : Ridge Plot of Marker Expression
- [`HistogramPlot()`](https://cttir.github.io/phenoscapR/dev/reference/HistogramPlot.md)
  : Histogram of Marker Expression
- [`QCPlot()`](https://cttir.github.io/phenoscapR/dev/reference/QCPlot.md)
  : QC Scatter Plot
- [`plot_cell_map()`](https://cttir.github.io/phenoscapR/dev/reference/plot_cell_map.md)
  : Plot Cell Map
- [`plot_density()`](https://cttir.github.io/phenoscapR/dev/reference/plot_density.md)
  : Plot Density Map
- [`plot_heatmap()`](https://cttir.github.io/phenoscapR/dev/reference/plot_heatmap.md)
  : Plot Marker Heatmap
- [`plot_interactions()`](https://cttir.github.io/phenoscapR/dev/reference/plot_interactions.md)
  : Plot Interaction Heatmap

## Manuscript Figures: Style and Composition

A compact journal figure style (typography, colours, line widths, tick
placement and typesetting), page composition in millimetres with panel
letters, headings, texts and legends, and figures rendered from
declarative specifications.

- [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptStyle.md)
  : Manuscript Figure Style
- [`ManuscriptPalettes()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptPalettes.md)
  : Manuscript Palettes
- [`ThemeManuscript()`](https://cttir.github.io/phenoscapR/dev/reference/ThemeManuscript.md)
  : Manuscript 'ggplot2' Theme
- [`PtLinewidth()`](https://cttir.github.io/phenoscapR/dev/reference/PtLinewidth.md)
  : Convert Points to a 'ggplot2' Line Width
- [`NiceBreaks()`](https://cttir.github.io/phenoscapR/dev/reference/NiceBreaks.md)
  : Tick Breaks of Common Plotting Code
- [`FormatP()`](https://cttir.github.io/phenoscapR/dev/reference/FormatP.md)
  : Format P Values for Figures
- [`FormatStatistic()`](https://cttir.github.io/phenoscapR/dev/reference/FormatStatistic.md)
  : Format a Patient-Level Statistic Line
- [`TypesetLabel()`](https://cttir.github.io/phenoscapR/dev/reference/TypesetLabel.md)
  : Typeset Figure Text
- [`FormatTemplate()`](https://cttir.github.io/phenoscapR/dev/reference/FormatTemplate.md)
  : Fill Text Templates from Table Rows
- [`ComposeFigure()`](https://cttir.github.io/phenoscapR/dev/reference/ComposeFigure.md)
  : Compose a Multi-Panel Figure
- [`FigurePanel()`](https://cttir.github.io/phenoscapR/dev/reference/FigurePanel.md)
  : Describe One Figure Panel
- [`FigureText()`](https://cttir.github.io/phenoscapR/dev/reference/FigureText.md)
  : Place Text on a Figure Page
- [`FigureGrob()`](https://cttir.github.io/phenoscapR/dev/reference/FigureGrob.md)
  : Place a Grob on a Figure Page
- [`LegendKeys()`](https://cttir.github.io/phenoscapR/dev/reference/LegendKeys.md)
  : Legend Keys as a Grob
- [`SaveFigure()`](https://cttir.github.io/phenoscapR/dev/reference/SaveFigure.md)
  : Save a Composed Figure as PDF and PNG
- [`FigureGrammars()`](https://cttir.github.io/phenoscapR/dev/reference/FigureGrammars.md)
  : Figure Plot Builders Available to Figure Specifications
- [`RenderFigure()`](https://cttir.github.io/phenoscapR/dev/reference/RenderFigure.md)
  : Render a Figure from a Specification
- [`ReadFigureSpec()`](https://cttir.github.io/phenoscapR/dev/reference/ReadFigureSpec.md)
  : Read a Figure Specification
- [`WriteFigure()`](https://cttir.github.io/phenoscapR/dev/reference/WriteFigure.md)
  : Write a Figure from a Specification
- [`ReadPlotTable()`](https://cttir.github.io/phenoscapR/dev/reference/ReadPlotTable.md)
  : Read a Plot Data Table

## Manuscript Figures: Plot Grammars

Panel builders registered in FigureGrammars(): patient-level displays,
matrices, bars, embeddings, cell maps, territories and image fields.

- [`PlotPairedPatients()`](https://cttir.github.io/phenoscapR/dev/reference/PlotPairedPatients.md)
  : Paired Patient Lines
- [`PlotQuantileCurves()`](https://cttir.github.io/phenoscapR/dev/reference/PlotQuantileCurves.md)
  : Summary Curves with Quantile Bands
- [`PlotBandProfiles()`](https://cttir.github.io/phenoscapR/dev/reference/PlotBandProfiles.md)
  : Profiles over Ordered Categories
- [`PlotIntervalForest()`](https://cttir.github.io/phenoscapR/dev/reference/PlotIntervalForest.md)
  : Interval Forest with Unit Values
- [`PlotGroupDifferences()`](https://cttir.github.io/phenoscapR/dev/reference/PlotGroupDifferences.md)
  : Differences Between Groups as Segments
- [`PlotVolcano()`](https://cttir.github.io/phenoscapR/dev/reference/PlotVolcano.md)
  : Volcano Plot of Exact Group Tests
- [`PlotGroupStrip()`](https://cttir.github.io/phenoscapR/dev/reference/PlotGroupStrip.md)
  : Unit Values by Group
- [`PlotScatterGroups()`](https://cttir.github.io/phenoscapR/dev/reference/PlotScatterGroups.md)
  : Scatter or Dot Rows Coloured by Group
- [`PlotBars()`](https://cttir.github.io/phenoscapR/dev/reference/PlotBars.md)
  : Bars per Unit
- [`PlotTextBlock()`](https://cttir.github.io/phenoscapR/dev/reference/PlotTextBlock.md)
  : Text Block or Text Table
- [`PlotStackedBars()`](https://cttir.github.io/phenoscapR/dev/reference/PlotStackedBars.md)
  : Stacked Bars
- [`PlotAnnotatedHeatmap()`](https://cttir.github.io/phenoscapR/dev/reference/PlotAnnotatedHeatmap.md)
  : Annotated Heatmap
- [`PlotDotMatrix()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDotMatrix.md)
  : Dot Matrix
- [`PlotAlterationMatrix()`](https://cttir.github.io/phenoscapR/dev/reference/PlotAlterationMatrix.md)
  : Alteration Matrix
- [`PlotEmbedding()`](https://cttir.github.io/phenoscapR/dev/reference/PlotEmbedding.md)
  : Embedding Scatter
- [`PlotDensityOutlines()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDensityOutlines.md)
  : Density Outlines on an Embedding
- [`PlotCellMap()`](https://cttir.github.io/phenoscapR/dev/reference/PlotCellMap.md)
  : Cell Map
- [`PlotTerritories()`](https://cttir.github.io/phenoscapR/dev/reference/PlotTerritories.md)
  : Cell Territory Map
- [`PlotFluorescenceField()`](https://cttir.github.io/phenoscapR/dev/reference/PlotFluorescenceField.md)
  : Multichannel Fluorescence Field
- [`PlotImage()`](https://cttir.github.io/phenoscapR/dev/reference/PlotImage.md)
  : Image, Image Gallery or Schematic

## Manuscript Figures: Plot Data

Generic table helpers (PlotData\*) that select, reshape, join, recode,
count and summarise tables for the grammars, and builders for
embeddings, annotated matrices, families of tests and image panels.

- [`PlotDataBindRows()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataBindRows.md)
  [`PlotDataBindColumns()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataBindRows.md)
  : Bind Plot Data Tables
- [`PlotDataConstant()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataConstant.md)
  : Add a Constant Column
- [`PlotDataContrastSummary()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataContrastSummary.md)
  : Summary of a Family of Two-Group Tests
- [`PlotDataCount()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCount.md)
  : Counts and Shares by Group
- [`PlotDataCrossShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataCrossShares.md)
  : Shares of One Category within Another
- [`PlotDataDirection()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataDirection.md)
  : Count of Units in the Direction of an Estimate
- [`PlotDataDominant()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataDominant.md)
  : Order Groups by Their Dominant Category
- [`PlotDataFromArrays()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataFromArrays.md)
  : Table from a List of Arrays
- [`PlotDataJoin()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataJoin.md)
  : Join Columns of Another Table
- [`PlotDataKeyColours()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataKeyColours.md)
  : Key Colours from a Categorical Palette
- [`PlotDataLabels()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataLabels.md)
  [`PlotDataCollapse()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataLabels.md)
  : Text Labels from Table Rows
- [`PlotDataLonger()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataLonger.md)
  : Reshape Wide Columns into Long Plot Data
- [`PlotDataMembership()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataMembership.md)
  : Flag Rows Whose Key Occurs in Another Table
- [`PlotDataPairRatio()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataPairRatio.md)
  : Ratios Between Two Levels of a Key Column
- [`PlotDataProduct()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataProduct.md)
  : Product of Columns
- [`PlotDataQuantiles()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataQuantiles.md)
  : Quantile Summaries of Plot Data
- [`PlotDataRankRows()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRankRows.md)
  : Rank Rows by the Sum of Selected Columns
- [`PlotDataRatio()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRatio.md)
  : Ratios Between Columns
- [`PlotDataRecode()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRecode.md)
  : Recode the Values of a Column
- [`PlotDataRelative()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataRelative.md)
  : Scale a Column to a Reference Row
- [`PlotDataSelect()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSelect.md)
  : Select Rows and Columns of Plot Data
- [`PlotDataShares()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataShares.md)
  : Shares of a Total in Several Columns
- [`PlotDataSummarise()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataSummarise.md)
  : Summarise Columns by Group
- [`PlotDataTableCells()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataTableCells.md)
  : Text-Table Cells from a Per-Unit Table
- [`PlotDataUnite()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataUnite.md)
  : Paste Columns into a Key Column
- [`ExactPermutationBound()`](https://cttir.github.io/phenoscapR/dev/reference/ExactPermutationBound.md)
  : Lower Bound of an Exact Two-Sided Permutation P Value
- [`EmbeddingLimits()`](https://cttir.github.io/phenoscapR/dev/reference/EmbeddingLimits.md)
  : Display Limits of an Embedding
- [`EmbeddingLayers()`](https://cttir.github.io/phenoscapR/dev/reference/EmbeddingLayers.md)
  : Layered Point Data for an Embedding
- [`ClusterLabelPositions()`](https://cttir.github.io/phenoscapR/dev/reference/ClusterLabelPositions.md)
  : Label Positions of Clusters on an Embedding
- [`DensityLevelContour()`](https://cttir.github.io/phenoscapR/dev/reference/DensityLevelContour.md)
  : Density Level Region of Each Group on an Embedding
- [`LookupNestedRows()`](https://cttir.github.io/phenoscapR/dev/reference/LookupNestedRows.md)
  : Look Up Values Stored on Nested Row Subsets
- [`AnnotationTracks()`](https://cttir.github.io/phenoscapR/dev/reference/AnnotationTracks.md)
  : Coloured Annotation Tracks
- [`AlterationMatrixData()`](https://cttir.github.io/phenoscapR/dev/reference/AlterationMatrixData.md)
  : Alteration Classes for an Alteration Matrix
- [`NearestLabelDistance()`](https://cttir.github.io/phenoscapR/dev/reference/NearestLabelDistance.md)
  : Distance to the Nearest Cell of Given Labels
- [`CellMapData()`](https://cttir.github.io/phenoscapR/dev/reference/CellMapData.md)
  : Cells of a Map Field or Whole Section
- [`FieldCentre()`](https://cttir.github.io/phenoscapR/dev/reference/FieldCentre.md)
  : Field Centre as Plot Data
- [`DensestGridWindow()`](https://cttir.github.io/phenoscapR/dev/reference/DensestGridWindow.md)
  : Centre of the Densest Grid Window
- [`NearestPartnerPairs()`](https://cttir.github.io/phenoscapR/dev/reference/NearestPartnerPairs.md)
  : Cells Paired with Their Nearest Partner Cell
- [`FieldCellsRanked()`](https://cttir.github.io/phenoscapR/dev/reference/FieldCellsRanked.md)
  : Cells of One Type inside a Field, Ranked
- [`TerritoryTiles()`](https://cttir.github.io/phenoscapR/dev/reference/TerritoryTiles.md)
  : Voronoi Territory Tiles of the Cells in a Field
- [`BestSubWindow()`](https://cttir.github.io/phenoscapR/dev/reference/BestSubWindow.md)
  : Sub-Window with the Most Cells of a Kind
- [`CompositeFields()`](https://cttir.github.io/phenoscapR/dev/reference/CompositeFields.md)
  : Composite Fluorescence Images from Channel Fields
- [`SchematicShapes()`](https://cttir.github.io/phenoscapR/dev/reference/SchematicShapes.md)
  : Schematic Shapes from a Specification
- [`CellPositionsFor()`](https://cttir.github.io/phenoscapR/dev/reference/CellPositionsFor.md)
  : Attach Cell Positions to a Table of Cell References

## Colour Palettes

Manage the global colour palette used by all plotting functions.
Supports viridis options and custom gradients defined by 2-3 anchor
colours.

- [`SetPalette()`](https://cttir.github.io/phenoscapR/dev/reference/SetPalette.md)
  [`GetPalette()`](https://cttir.github.io/phenoscapR/dev/reference/SetPalette.md)
  : Set or Get the Default Colour Palette
- [`PaletteContinuous()`](https://cttir.github.io/phenoscapR/dev/reference/PaletteContinuous.md)
  : Generate a Continuous Colour Palette Function
- [`PaletteDiscrete()`](https://cttir.github.io/phenoscapR/dev/reference/PaletteDiscrete.md)
  : Generate Discrete Colours
- [`CustomGradient()`](https://cttir.github.io/phenoscapR/dev/reference/CustomGradient.md)
  : Create a Custom Gradient Palette from Anchor Colours

## Shiny Application

Launch the interactive phenoscapR Shiny interface to run the full
analysis workflow and explore results with live plots and tables.

- [`run_app()`](https://cttir.github.io/phenoscapR/dev/reference/run_app.md)
  : Launch the phenoscapR Shiny Application

## Datasets

Bundled example data used throughout the documentation and vignettes.

- [`phenoscapR_example`](https://cttir.github.io/phenoscapR/dev/reference/phenoscapR_example.md)
  : Synthetic multiplexed-imaging example dataset
