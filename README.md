# phenoscapR

<!-- badges: start -->
<!-- badges: end -->

**phenoscapR** provides an S4 class (`AkoyaExperiment`) and a
pipe-friendly workflow for reading, processing, analysing, and visualising
multiplexed spatial biology data from Akoya Biosciences platforms
(PhenoCycler, CODEX, PhenoImager).

Inspired by [Seurat](https://satijalab.org/seurat/), all data lives in a
single object and every analysis function takes and returns that object.

## Installation

```r
# install.packages("remotes")
remotes::install_github("r-heller/phenoscapR")
```

## Quick Start

```r
library(phenoscapR)

# Read → QC → Normalise → Phenotype → Spatial analysis (R 4.1+ pipe)
obj <- ReadAkoya("segmentation.csv") |>
  QCFilter(min_area = 50, max_area = 500) |>
  NormaliseData(method = "zscore") |>
  PhenotypeCells(thresholds = list(CD3 = 0.5, CD8 = 0.3)) |>
  FindNeighbours(k = 5) |>
  CellDensity(radius = 50)

# Visualise
CellMap(obj)
DensityPlot(obj)
MarkerHeatmap(obj)
InteractionPlot(InteractionMatrix(obj, radius = 50))
```

## The AkoyaExperiment Object

```r
obj
# An AkoyaExperiment object
#   10000 cells across 1 sample
#   Markers: CD3, CD8, CD20, PanCK, DAPI
#   Normalised: TRUE
#   Phenotypes: 4
#   Project: AkoyaProject
```

## Core API

| Category | Functions |
|---|---|
| **I/O** | `ReadAkoya()`, `CreateAkoyaObject()` |
| **Processing** | `QCFilter()`, `NormaliseData()`, `PhenotypeCells()`, `PhenotypeSummary()` |
| **Spatial** | `FindNeighbours()`, `CellDensity()`, `InteractionMatrix()`, `SpatialClusters()` |
| **Visualisation** | `CellMap()`, `DensityPlot()`, `MarkerHeatmap()`, `InteractionPlot()` |
| **Accessors** | `NCells()`, `NMarkers()`, `Markers()`, `Coords()`, `Meta()`, `GetData()`, `Idents()` |

## Dependencies

Only CRAN packages with no system requirements:

- **methods** (base R) — S4 classes
- **data.table** — fast CSV reading
- **ggplot2** — visualisation
- **stats**, **utils**, **grDevices** (base R)

## License

MIT
