# phenoscapR

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21889952.svg)](https://doi.org/10.5281/zenodo.21889952)

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

The package ships a synthetic two-sample example dataset, so you can run
the whole workflow without any files of your own:

``` r

library(phenoscapR)
data(phenoscapR_example)

obj <- phenoscapR_example
obj <- NormaliseData(obj, method = "zscore")
obj <- PhenotypeCells(obj, thresholds = list(CD20 = 1, CD3 = 1, CD8 = 1,
                                             CD68 = 1, PanCK = 1, FoxP3 = 1))

# Per-sample spatial structure
im <- InteractionMatrix(obj, radius = 40)
InteractionPlot(im)

# Single-tissue point-pattern statistics
a <- obj[obj$sample_id == "tonsil_A", ]
RipleysK(a, correction = "border")
NeighbourhoodEnrichment(a, radius = 40, n_perm = 199)

CellMap(a)
```

A typical real analysis starts from your own segmentation output:

``` r

# 1. Read cell segmentation CSV (or a directory of them)
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
ne  <- NeighbourhoodEnrichment(obj[obj$sample_id == "sample1", ],
                               radius = 50, n_perm = 100)

# 6. Visualise
CellMap(obj)
FeaturePlot(obj, features = c("CD3", "CD8"))
MarkerHeatmap(obj)
InteractionPlot(InteractionMatrix(obj, radius = 50))
SpatialNetworkPlot(obj)
```

### Performance

All neighbour-based statistics route through a kd-tree search engine
(`RANN` when installed, with an exact base-R fallback otherwise), so a
20,000-cell section runs each statistic in seconds instead of building a
multi-gigabyte distance matrix.

## Interactive app

phenoscapR ships a **Hugo Coder–themed Shiny app** that drives the
package’s analysis functions interactively — load the bundled data, run
QC and phenotyping, explore spatial statistics, cellular neighbourhoods,
spatial domains, dimensionality reductions, and differential abundance,
with a light/dark colour-mode toggle. The app is a thin UI over the
exported functions; the heavy lifting is the package.

``` r

# one-time: install the optional app dependencies
install.packages(c("shiny", "bslib", "sass", "thematic", "reactable",
                   "bsicons", "brand.yml"))

phenoscapR::run_app()
```

The app’s visual design is adapted from the [Hugo
Coder](https://github.com/luizdepra/hugo-coder) theme (MIT) — colour
tokens and flat aesthetic only, no source copied.

## Documentation

Full documentation and vignettes are available at
**<https://cttir.github.io/phenoscapR/>**

| Vignette | Description |
|----|----|
| [Getting Started](https://cttir.github.io/phenoscapR/articles/phenoscapR.html) | End-to-end workflow with simulated data |
| [The SpatialCellData Object](https://cttir.github.io/phenoscapR/articles/phenoscapR-02-object-model.html) | S4 class internals, accessors, and subsetting |
| [Advanced Spatial Analysis](https://cttir.github.io/phenoscapR/articles/phenoscapR-03-spatial-analysis.html) | Ripley’s K, Moran’s I, neighbourhood enrichment, and choosing a statistic |
| [Visualisation Gallery](https://cttir.github.io/phenoscapR/articles/phenoscapR-04-visualisation.html) | Every plotting function, demonstrated on the example data |

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

## Authors

- **R. Heller** (maintainer, author) — [ORCID
  0000-0001-8006-9742](https://orcid.org/0000-0001-8006-9742)
- **Hanno Witte** (author)

## Citation

``` r

citation("phenoscapR")
```

> Heller, R. & Witte, H. (2026). phenoscapR: Read, Analyse, and
> Visualise Single-Cell Spatial Biology Data.
> <https://cttir.github.io/phenoscapR/>

## License

MIT © R. Heller and Hanno Witte
