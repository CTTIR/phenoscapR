# phenoscapR <img src="man/figures/logo.svg" align="right" height="139" alt="phenoscapR hex logo"/>

<!-- badges: start -->
[![R-CMD-check](https://github.com/cttir/phenoscapR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/cttir/phenoscapR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/cttir/phenoscapR/actions/workflows/pkgdown.yaml/badge.svg)](https://cttir.github.io/phenoscapR/)
[![Codecov test coverage](https://codecov.io/gh/cttir/phenoscapR/graph/badge.svg)](https://codecov.io/gh/cttir/phenoscapR)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**phenoscapR** provides a complete toolkit for reading, processing, analysing,
and visualising single-cell spatial biology data from multiplexed imaging
platforms. It handles the full workflow from raw cell segmentation CSV files
through quality control, marker normalisation, cell phenotyping, spatial
statistics, and publication-ready visualisation — using an efficient
`data.table` backend and a clean S4 object model (`SpatialCellData`).

## Features

### Data Import & Object Model
- Auto-detect and parse **three CSV formats**: QuPath Full Export, QuPath
  Minimal, and flat segmentation output
- `SpatialCellData` S4 class stores counts, normalised data, coordinates,
  metadata, and spatial results in one object
- Familiar accessors: `NCells()`, `Markers()`, `Coords()`, `Meta()`,
  `GetData()`, `Idents()`, `[`, `[[`, `$`

### Quality Control & Preprocessing
- Filter cells by area and intensity range (`qc_filter()` / `QCFilter()`)
- Three normalisation methods: z-score, min-max, quantile
  (`normalise_markers()` / `NormaliseData()`)
- QC scatter plots (`QCPlot()`)

### Phenotyping
- Marker-threshold-based cell phenotyping (`phenotype_cells()` /
  `PhenotypeCells()`)
- Per-sample phenotype proportion summaries (`summarise_phenotypes()` /
  `PhenotypeSummary()`)

### Spatial Analysis
- Nearest-neighbour distances, local cell density, interaction matrices,
  spatial clustering
- Advanced statistics: **Neighbourhood Enrichment**, **Ripley's K**, **Moran's I**,
  **Quadrat Analysis**, **Pair Correlation Function**, **Cross Nearest-Neighbour
  Distance**, **Delaunay Networks**, **Expression Clustering**

### Visualisation
- Tissue cell maps, feature plots, density maps, spatial network plots
- Distribution plots: violin, box, ridge, histogram, dot plot
- Heatmaps: marker intensity, spatial interactions
- Phenotype composition bar charts
- Dark-theme support for tissue image overlays

## Installation

```r
# Install the development version from GitHub
# install.packages("pak")
pak::pak("cttir/phenoscapR")

# Or with remotes
# install.packages("remotes")
remotes::install_github("cttir/phenoscapR")
```

## Quick Start

```r
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
|---|---|
| [Getting Started](https://cttir.github.io/phenoscapR/articles/phenoscapR.html) | End-to-end workflow with simulated data |
| [The SpatialCellData Object](https://cttir.github.io/phenoscapR/articles/phenoscapR-02-object-model.html) | S4 class internals, accessors, and subsetting |
| [Advanced Spatial Analysis](https://cttir.github.io/phenoscapR/articles/phenoscapR-03-spatial-analysis.html) | Ripley's K, Moran's I, neighbourhood enrichment, and more |

## Contributing

Bug reports and feature requests are welcome at
<https://github.com/cttir/phenoscapR/issues>.

## Use of LLM tools

Portions of this package were prepared with assistance from large language model tooling for
narrowly defined, non-authorial tasks: copyediting, prose smoothing, Markdown/LaTeX formatting,
scaffolding of boilerplate files (CI configs, build scripts), code refactoring. The tools used were [Chat AI](https://kisski.gwdg.de/leistungen/2-02-llm-service/),
the LLM service of KISSKI (GWDG), and a self-hosted **Mistral Small (24B, Apache-2.0)** run locally via
[Ollama](https://ollama.com/) and the `ollamar` R package — local inference only, with no data sent to
third parties for the self-hosted model.

All scientific claims, methodological choices, analyses, interpretations, and conclusions are the
author's own. No LLM-generated text was incorporated without review and revision, and every reference
was verified against its DOI, arXiv ID, or ISBN.

## License

MIT © Raban Heller
