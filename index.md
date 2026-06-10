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
  [`NCells()`](https://cttir.github.io/phenoscapR/reference/NCells.md),
  [`Markers()`](https://cttir.github.io/phenoscapR/reference/Markers.md),
  [`Coords()`](https://cttir.github.io/phenoscapR/reference/Coords.md),
  [`Meta()`](https://cttir.github.io/phenoscapR/reference/Meta.md),
  [`GetData()`](https://cttir.github.io/phenoscapR/reference/GetData.md),
  [`Idents()`](https://cttir.github.io/phenoscapR/reference/Idents.md),
  `[`, `[[`, `$`

### Quality Control & Preprocessing

- Filter cells by area and intensity range
  ([`qc_filter()`](https://cttir.github.io/phenoscapR/reference/qc_filter.md)
  /
  [`QCFilter()`](https://cttir.github.io/phenoscapR/reference/QCFilter.md))
- Three normalisation methods: z-score, min-max, quantile
  ([`normalise_markers()`](https://cttir.github.io/phenoscapR/reference/normalise_markers.md)
  /
  [`NormaliseData()`](https://cttir.github.io/phenoscapR/reference/NormaliseData.md))
- QC scatter plots
  ([`QCPlot()`](https://cttir.github.io/phenoscapR/reference/QCPlot.md))

### Phenotyping

- Marker-threshold-based cell phenotyping
  ([`phenotype_cells()`](https://cttir.github.io/phenoscapR/reference/phenotype_cells.md)
  /
  [`PhenotypeCells()`](https://cttir.github.io/phenoscapR/reference/PhenotypeCells.md))
- Per-sample phenotype proportion summaries
  ([`summarise_phenotypes()`](https://cttir.github.io/phenoscapR/reference/summarise_phenotypes.md)
  /
  [`PhenotypeSummary()`](https://cttir.github.io/phenoscapR/reference/PhenotypeSummary.md))

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
pak::pak("cttir/phenoscapR")

# Or with remotes
# install.packages("remotes")
remotes::install_github("cttir/phenoscapR")
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
**<https://cttir.github.io/phenoscapR/>**

| Vignette | Description |
|----|----|
| [Getting Started](https://cttir.github.io/phenoscapR/articles/phenoscapR.html) | End-to-end workflow with simulated data |
| [The SpatialCellData Object](https://cttir.github.io/phenoscapR/articles/phenoscapR-02-object-model.html) | S4 class internals, accessors, and subsetting |
| [Advanced Spatial Analysis](https://cttir.github.io/phenoscapR/articles/phenoscapR-03-spatial-analysis.html) | Ripley’s K, Moran’s I, neighbourhood enrichment, and more |

## Contributing

Bug reports and feature requests are welcome at
<https://github.com/cttir/phenoscapR/issues>.

## Use of LLM tools

Portions of this package were prepared with assistance from large
language model tooling for narrowly defined, non-authorial tasks:
copyediting, prose smoothing, Markdown/LaTeX formatting, scaffolding of
boilerplate files (CI configs, build scripts), code refactoring. The
tools used were [Chat
AI](https://kisski.gwdg.de/leistungen/2-02-llm-service/), the LLM
service of KISSKI (GWDG), and a self-hosted **Mistral Small (24B,
Apache-2.0)** run locally via [Ollama](https://ollama.com/) and the
`ollamar` R package — local inference only, with no data sent to third
parties for the self-hosted model.

All scientific claims, methodological choices, analyses,
interpretations, and conclusions are the author’s own. No LLM-generated
text was incorporated without review and revision, and every reference
was verified against its DOI, arXiv ID, or ISBN.

## License

MIT © Raban Heller
