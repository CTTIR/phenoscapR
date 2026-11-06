# Visualisation Gallery

![phenoscapR logo](figures/logo.svg)![phenoscapR
logo](figures/logo-dark.svg)

[![R-CMD-check](https://github.com/CTTIR/phenoscapR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CTTIR/phenoscapR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/CTTIR/phenoscapR/actions/workflows/pkgdown.yaml/badge.svg)](https://cttir.github.io/phenoscapR/)
[![Codecov test
coverage](https://codecov.io/gh/CTTIR/phenoscapR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/CTTIR/phenoscapR?branch=main)
[![License:
MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

## Overview

Every phenoscapR plotting function returns a **ggplot** object, so you
can add themes, facets, or annotations as usual, and they all draw from
the global palette system for consistent colours across a figure panel.
This gallery shows each one on the bundled example data.

``` r

library(phenoscapR)
library(ggplot2)
data(phenoscapR_example)

obj <- phenoscapR_example
obj@meta_data$phenotype <- obj@meta_data$phenotype_true
obj <- NormaliseData(obj, method = "zscore")

# A single tissue for the spatial maps.
a <- obj[obj$sample_id == "tonsil_A", ]
# Cell subsetting invalidates cached local density; compute it on this tissue.
a <- CellDensity(a, radius = 40)
markers <- c("CD20", "CD3", "CD8", "PanCK")
```

## Tissue maps

### `CellMap()` — phenotype map

``` r

CellMap(a)
```

![Synthetic tonsil A cell positions coloured by simulated
phenotype.](phenoscapR-04-visualisation_files/figure-html/cellmap-1.png)

### `FeaturePlot()` — marker intensity in space

``` r

FeaturePlot(a, features = markers)
```

![Spatial distributions of normalised CD20, CD3, CD8 and PanCK intensity
in synthetic tonsil
A.](phenoscapR-04-visualisation_files/figure-html/featureplot-1.png)

### `DensityPlot()` — local cell density

``` r

DensityPlot(a)
```

![Synthetic tonsil A cell positions coloured by local cell density
within radius
40.](phenoscapR-04-visualisation_files/figure-html/densityplot-1.png)

### `SpatialNetworkPlot()` — cell-contact graph

``` r

a_net <- DelaunayNetwork(a, max_edge = 60)
SpatialNetworkPlot(a_net)
```

![Delaunay network of synthetic tonsil A cells, retaining edges no
longer than
60.](phenoscapR-04-visualisation_files/figure-html/network-1.png)

## Marker distributions

### `ViolinPlot()` and `BoxPlot()`

``` r

ViolinPlot(a, features = markers, group_by = "phenotype")
```

![Violin distributions of four normalised marker intensities by
simulated
phenotype.](phenoscapR-04-visualisation_files/figure-html/violin-1.png)

``` r

BoxPlot(a, features = markers, group_by = "phenotype")
```

![Box plots of four normalised marker intensities by simulated
phenotype.](phenoscapR-04-visualisation_files/figure-html/box-1.png)

### `RidgePlot()` and `HistogramPlot()`

``` r

RidgePlot(a, features = markers, group_by = "phenotype")
```

![Distributions of four normalised marker intensities by simulated
phenotype.](phenoscapR-04-visualisation_files/figure-html/ridge-1.png)

``` r

HistogramPlot(a, feature = "CD20", group_by = "phenotype")
```

![Histograms of normalised CD20 intensity by simulated
phenotype.](phenoscapR-04-visualisation_files/figure-html/histogram-1.png)

### `DotPlot()` — mean expression × fraction expressing

``` r

DotPlot(a, features = c("CD3", "CD4", "CD8", "CD20", "CD68", "PanCK", "FoxP3"))
```

![Marker expression by simulated phenotype; dot colour shows mean
expression and size shows the expressing
fraction.](phenoscapR-04-visualisation_files/figure-html/dotplot-1.png)

## Summaries

### `MarkerHeatmap()` — phenotype signatures

``` r

MarkerHeatmap(obj)
```

![Mean normalised marker intensities for each simulated
phenotype.](phenoscapR-04-visualisation_files/figure-html/heatmap-1.png)

### `CompositionPlot()` — phenotype proportions

``` r

CompositionPlot(obj, group_by = "sample_id")
```

![Stacked simulated phenotype proportions in each synthetic
section.](phenoscapR-04-visualisation_files/figure-html/composition-1.png)

### `InteractionPlot()` — co-localisation scores

``` r

InteractionPlot(InteractionMatrix(obj, radius = 40))
```

![Pairwise simulated phenotype interaction scores within the synthetic
sections at radius
40.](phenoscapR-04-visualisation_files/figure-html/interactions-1.png)

### `QCPlot()` — any metadata pair

``` r

QCPlot(a, x = "cell_area", y = "density", colour_by = "phenotype")
```

![Cell area versus local density in synthetic tonsil A, coloured by
simulated
phenotype.](phenoscapR-04-visualisation_files/figure-html/qcplot-1.png)

## Dimensionality reductions

Reduce marker space and plot it with
[`DimPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md)
/
[`EmbeddingPlot()`](https://cttir.github.io/phenoscapR/reference/EmbeddingPlot.md).

``` r

obj <- RunPCA(obj, n_pcs = 10)
DimPlot(obj, reduction = "pca", colour_by = "phenotype")
```

![PCA embedding of synthetic cells coloured by simulated
phenotype.](phenoscapR-04-visualisation_files/figure-html/pca-1.png)

``` r

# Base SVD is sufficient for this small marker panel and avoids dependence
# on an optional truncated-SVD solver when disconnected groups need PCA init.
obj <- RunUMAP(obj, dims = 10, n_neighbors = 15, seed = 1,
               pca_method = "svd", n_threads = 1)
EmbeddingPlot(obj, reduction = "umap", colour_by = "phenotype")
```

![UMAP embedding of synthetic cells coloured by simulated
phenotype.](phenoscapR-04-visualisation_files/figure-html/umap-1.png)

## Theming and palettes

Because each plot is a plain ggplot, standard customisation just works:

``` r

CellMap(a) +
  labs(title = "Tonsil A — phenotype map") +
  theme(plot.title = element_text(face = "bold"))
```

![Synthetic tonsil A phenotype map with a customised
title.](phenoscapR-04-visualisation_files/figure-html/theme-1.png)

The package palette is global. Set it once and every plot follows. Any
viridis-family option works (`"viridis"`, `"inferno"`, `"plasma"`,
`"cividis"`, `"rocket"`, `"mako"`):

``` r

SetPalette("rocket")
CompositionPlot(obj, group_by = "sample_id")
```

![Stacked simulated phenotype proportions in each section using the
rocket
palette.](phenoscapR-04-visualisation_files/figure-html/palette-1.png)

[`PaletteDiscrete()`](https://cttir.github.io/phenoscapR/reference/PaletteDiscrete.md),
[`PaletteContinuous()`](https://cttir.github.io/phenoscapR/reference/PaletteContinuous.md),
and
[`CustomGradient()`](https://cttir.github.io/phenoscapR/reference/CustomGradient.md)
expose the same colours for use in bespoke plots.

``` r

PaletteDiscrete(5)
#> [1] "#4B0055" "#00588B" "#009B95" "#53CC67" "#FDE333"
```

## See also

- **[Getting
  Started](https://cttir.github.io/phenoscapR/articles/phenoscapR.md)**
  — the end-to-end workflow
- **[Advanced Spatial
  Analysis](https://cttir.github.io/phenoscapR/articles/phenoscapR-03-spatial-analysis.md)**
  — the statistics behind these plots
