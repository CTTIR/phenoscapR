# phenoscapR

<!-- badges: start -->
<!-- badges: end -->

**phenoscapR** provides tools for reading, processing, analysing, and
visualising multiplexed spatial biology data produced by Akoya Biosciences
platforms (PhenoCycler, CODEX, PhenoImager).

## Installation

Install the development version from GitHub:

```r
# install.packages("remotes")
remotes::install_github("r-heller/phenoscapR")
```

## Quick Start

```r
library(phenoscapR)

# Read Akoya cell segmentation data
cells <- read_akoya("path/to/segmentation.csv", sample_id = "sample1")

# Quality control
cells <- qc_filter(cells, min_area = 50, max_area = 500)

# Normalise marker intensities
cells <- normalise_markers(cells, method = "zscore")

# Assign phenotypes based on marker thresholds
cells <- phenotype_cells(cells, thresholds = list(CD3 = 0.5, CD8 = 0.3))

# Spatial analysis
cells <- nearest_neighbours(cells, k = 5)
cells <- cell_density(cells, radius = 50)
interactions <- interaction_matrix(cells, radius = 50)

# Visualise
plot_cell_map(cells)
plot_density(cells)
plot_heatmap(cells)
plot_interactions(interactions)
```

## Core Functions

| Function | Description |
|---|---|
| `read_akoya()` | Read Akoya cell segmentation CSV files |
| `qc_filter()` | Quality control filtering by area and intensity |
| `normalise_markers()` | Normalise marker intensities (z-score, min-max, quantile) |
| `phenotype_cells()` | Assign phenotype labels by marker thresholds |
| `summarise_phenotypes()` | Summarise phenotype proportions per sample |
| `nearest_neighbours()` | Compute nearest neighbour distances |
| `cell_density()` | Estimate local cell density |
| `interaction_matrix()` | Pairwise spatial interaction scores |
| `spatial_clusters()` | Spatial clustering (k-means or hierarchical) |
| `plot_cell_map()` | Scatter plot of cell positions by phenotype |
| `plot_density()` | Density map visualisation |
| `plot_heatmap()` | Marker intensity heatmap by phenotype |
| `plot_interactions()` | Spatial interaction heatmap |

## License

MIT
