# phenoscapR

**phenoscapR** provides a complete toolkit for reading, processing,
analysing, and visualising single-cell spatial biology data from
multiplexed imaging platforms. It handles the full workflow from raw
cell segmentation CSV files through quality control, marker
normalisation, cell phenotyping, spatial statistics, and
publication-ready visualisation — using an efficient `data.table`
backend and a clean S4 object model (`SpatialCellData`).

## Features

### Data Import & Object Model

- Auto-detect and parse **three CSV formats**: QuPath Full Export,
  QuPath Minimal, and flat segmentation output
- `SpatialCellData` S4 class stores counts, normalised data,
  coordinates, metadata, and spatial results in one object
- Familiar accessors:
  [`NCells()`](https://r-heller.github.io/phenoscapR/reference/NCells.md),
  [`Markers()`](https://r-heller.github.io/phenoscapR/reference/Markers.md),
  [`Coords()`](https://r-heller.github.io/phenoscapR/reference/Coords.md),
  [`Meta()`](https://r-heller.github.io/phenoscapR/reference/Meta.md),
  [`GetData()`](https://r-heller.github.io/phenoscapR/reference/GetData.md),
  [`Idents()`](https://r-heller.github.io/phenoscapR/reference/Idents.md),
  `[`, `[[`, `$`

### Quality Control & Preprocessing

- Filter cells by area and intensity range
  ([`qc_filter()`](https://r-heller.github.io/phenoscapR/reference/qc_filter.md)
  /
  [`QCFilter()`](https://r-heller.github.io/phenoscapR/reference/QCFilter.md))
- Three normalisation methods: z-score, min-max, quantile
  ([`normalise_markers()`](https://r-heller.github.io/phenoscapR/reference/normalise_markers.md)
  /
  [`NormaliseData()`](https://r-heller.github.io/phenoscapR/reference/NormaliseData.md))
- QC scatter plots
  ([`QCPlot()`](https://r-heller.github.io/phenoscapR/reference/QCPlot.md))

### Phenotyping

- Marker-threshold-based cell phenotyping
  ([`phenotype_cells()`](https://r-heller.github.io/phenoscapR/reference/phenotype_cells.md)
  /
  [`PhenotypeCells()`](https://r-heller.github.io/phenoscapR/reference/PhenotypeCells.md))
- Per-sample phenotype proportion summaries
  ([`summarise_phenotypes()`](https://r-heller.github.io/phenoscapR/reference/summarise_phenotypes.md)
  /
  [`PhenotypeSummary()`](https://r-heller.github.io/phenoscapR/reference/PhenotypeSummary.md))

### Spatial Analysis

- Nearest-neighbour distances, local cell density, interaction matrices,
  spatial clustering
- Advanced statistics: **Neighbourhood Enrichment**, **Ripley’s K**,
  **Moran’s I**, **Quadrat Analysis**, **Pair Correlation Function**,
  **Cross Nearest-Neighbour Distance**, **Delaunay Networks**,
  **Expression Clustering**

### Visualisation

- Tissue cell maps, feature plots, density maps, spatial network plots
- Distribution plots: violin, box, ridge, histogram, dot plot
- Heatmaps: marker intensity, spatial interactions
- Phenotype composition bar charts
- Dark-theme support for tissue image overlays

## Installation

``` r
# Install the development version from GitHub
# install.packages("pak")
pak::pak("r-heller/phenoscapR")

# Or with remotes
# install.packages("remotes")
remotes::install_github("r-heller/phenoscapR")
```

## Quick Start

``` r
library(phenoscapR)

# 1. Read cell segmentation CSV
obj <- ReadSpatial("path/to/segmentation.csv", sample_id = "sample1")

# 2. Quality control
obj <- QCFilter(obj, min_area = 50, max_area = 500)

# 3. Normalise marker intensities
obj <- NormaliseData(obj, method = "zscore")

# 4. Assign phenotypes by marker thresholds
obj <- PhenotypeCells(obj, thresholds = list(CD3 = 0.5, CD8 = 0.3,
                                              CD20 = 0.4, PanCK = 0.6))

# 5. Spatial analysis
obj <- FindNeighbours(obj, k = 5)
obj <- CellDensity(obj, radius = 50)
obj <- DelaunayNetwork(obj)
ne  <- NeighbourhoodEnrichment(obj, radius = 50, n_perm = 100)

# 6. Visualise
CellMap(obj)
FeaturePlot(obj, features = c("CD3", "CD8"))
MarkerHeatmap(obj)
InteractionPlot(InteractionMatrix(obj, radius = 50))
SpatialNetworkPlot(obj)
```

## Documentation

Full documentation and vignettes are available at
**<https://r-heller.github.io/phenoscapR/>**

| Vignette | Description |
|----|----|
| [Getting Started](https://r-heller.github.io/phenoscapR/articles/phenoscapR.html) | End-to-end workflow with simulated data |
| [The SpatialCellData Object](https://r-heller.github.io/phenoscapR/articles/phenoscapR-02-object-model.html) | S4 class internals, accessors, and subsetting |
| [Advanced Spatial Analysis](https://r-heller.github.io/phenoscapR/articles/phenoscapR-03-spatial-analysis.html) | Ripley’s K, Moran’s I, neighbourhood enrichment, and more |

## Contributing

Bug reports and feature requests are welcome at
<https://github.com/r-heller/phenoscapR/issues>.

## License

MIT © Raban Heller
