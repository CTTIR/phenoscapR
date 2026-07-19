# The SpatialCellData Object

[![R-CMD-check](https://github.com/CTTIR/phenoscapR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CTTIR/phenoscapR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/CTTIR/phenoscapR/actions/workflows/pkgdown.yaml/badge.svg)](https://cttir.github.io/phenoscapR/)
[![CRAN
status](https://www.r-pkg.org/badges/version/phenoscapR)](https://CRAN.R-project.org/package=phenoscapR)
[![Codecov test
coverage](https://codecov.io/gh/CTTIR/phenoscapR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/CTTIR/phenoscapR?branch=main)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/phenoscapR)](https://cran.r-project.org/package=phenoscapR)
[![CRAN downloads
total](https://cranlogs.r-pkg.org/badges/grand-total/phenoscapR)](https://cran.r-project.org/package=phenoscapR)
[![License:
MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

![phenoscapR hex logo](../reference/figures/logo.svg)

## Overview

The **`SpatialCellData`** S4 class is the central data container in
phenoscapR. It keeps everything about an experiment in one object:

| Slot | Type | Contents |
|----|----|----|
| `counts` | numeric matrix | Raw marker intensities (cells × markers) |
| `data` | numeric matrix | Normalised intensities (filled by [`NormaliseData()`](https://cttir.github.io/phenoscapR/reference/NormaliseData.md)) |
| `coords` | data.frame | Spatial coordinates (`x`, `y`) |
| `meta_data` | data.frame | Per-cell metadata (`cell_id`, `sample_id`, phenotype, …) |
| `project` | character | Project / experiment name |
| `spatial` | list | Stored spatial results (neighbour distances, Delaunay edges, …) |
| `reductions` | list | Embeddings from [`RunPCA()`](https://cttir.github.io/phenoscapR/reference/RunPCA.md), [`RunUMAP()`](https://cttir.github.io/phenoscapR/reference/RunUMAP.md), … |

A validity method guarantees the matrices, coordinates, and metadata
always describe the same set of cells in the same order.

## Construction

### From raw matrices

Use
[`CreateSpatialObject()`](https://cttir.github.io/phenoscapR/reference/CreateSpatialObject.md)
when you already have a counts matrix and a coordinate table:

``` r

library(phenoscapR)

set.seed(1)
n <- 200
counts <- matrix(
  abs(rnorm(n * 4, mean = 500, sd = 200)),
  nrow = n,
  dimnames = list(NULL, c("CD3", "CD8", "CD20", "PanCK"))
)
coords <- data.frame(x = runif(n, 0, 1000), y = runif(n, 0, 1000))

obj <- CreateSpatialObject(counts, coords, project = "demo")
obj
#> A SpatialCellData object
#>   200 cells across 1 sample
#>   Markers: CD3, CD8, CD20, PanCK 
#>   Normalised: FALSE 
#>   Project: demo
```

### From CSV files

[`ReadSpatial()`](https://cttir.github.io/phenoscapR/reference/ReadSpatial.md)
reads one or more segmentation CSVs and returns a `SpatialCellData`
directly. It auto-detects the delimiter, byte-order marks, and three
common layouts (QuPath full export, QuPath minimal, and flat
segmentation tables), and parses a `sample_id` per file.

``` r

# A single file
obj <- ReadSpatial("path/to/segmentation.csv", sample_id = "sample1")

# A whole directory (sample_id defaults to each file's name)
obj <- ReadSpatial("path/to/csv_dir/")
```

## A worked object

The rest of this vignette uses the bundled two-sample example so every
line runs:

``` r

data(phenoscapR_example)
spe <- phenoscapR_example
spe
#> A SpatialCellData object
#>   640 cells across 2 samples
#>   Markers: CD3, CD4, CD8, CD20, CD68, ... (8 total) 
#>   Normalised: FALSE 
#>   Project: phenoscapR example (tonsil, simulated)
```

## Inspecting the object

``` r

dim(spe)        # cells × markers
#> [1] 640   8
NCells(spe)
#> [1] 640
NMarkers(spe)
#> [1] 8
Markers(spe)
#> [1] "CD3"   "CD4"   "CD8"   "CD20"  "CD68"  "PanCK" "FoxP3" "Ki67"
head(Meta(spe))
#>      cell_id sample_id cell_area phenotype_true
#> 1 tonsil_A_1  tonsil_A       123         B cell
#> 2 tonsil_A_2  tonsil_A       115    T cytotoxic
#> 3 tonsil_A_3  tonsil_A       112     Epithelial
#> 4 tonsil_A_4  tonsil_A        63         B cell
#> 5 tonsil_A_5  tonsil_A       124    T cytotoxic
#> 6 tonsil_A_6  tonsil_A        86     Macrophage
head(Coords(spe))
#>          x        y
#> 1 415.2129 760.4836
#> 2 674.0587 434.7913
#> 3 747.2101 353.3104
#> 4 379.1923 620.3793
#> 5 626.6378 308.7950
#> 6 223.4583 590.1055
```

## Accessing expression data

``` r

# Raw counts
GetData(spe, slot = "counts")[1:3, ]
#>            CD3      CD4       CD8       CD20      CD68     PanCK     FoxP3
#> [1,]  1.232687 1.929555  1.886467 12.8077449 0.9628334  1.030865 0.9204028
#> [2,] 29.873100 2.292387 23.131630  1.4714869 0.9444263  1.081335 1.4091575
#> [3,]  1.076436 1.117645  1.282085  0.7691188 0.8374219 16.982042 0.8732379
#>          Ki67
#> [1,] 2.443624
#> [2,] 1.486877
#> [3,] 5.307441

# Normalised values live in the "data" slot
spe <- NormaliseData(spe, method = "zscore")
round(GetData(spe, slot = "data")[1:3, ], 2)
#>        CD3   CD4   CD8  CD20  CD68 PanCK FoxP3  Ki67
#> [1,] -0.66 -0.36 -0.27  0.56 -0.36 -0.58 -0.28  0.31
#> [2,]  2.02 -0.30  2.96 -0.51 -0.36 -0.58 -0.10 -0.63
#> [3,] -0.67 -0.49 -0.37 -0.58 -0.38  0.72 -0.30  3.14
```

## Working with metadata

Metadata columns are reachable with `$` and `[[`:

``` r

head(spe$sample_id)
#> [1] "tonsil_A" "tonsil_A" "tonsil_A" "tonsil_A" "tonsil_A" "tonsil_A"
head(spe[["phenotype_true"]])
#> [1] "B cell"      "T cytotoxic" "Epithelial"  "B cell"      "T cytotoxic"
#> [6] "Macrophage"
```

[`Idents()`](https://cttir.github.io/phenoscapR/reference/Idents.md)
returns the active identity — phenotype labels when present, otherwise
sample identities. Here we promote the ground-truth populations to the
active phenotype:

``` r

spe@meta_data$phenotype <- spe@meta_data$phenotype_true
table(Idents(spe))
#> 
#>      B cell  Epithelial  Macrophage T cytotoxic    T helper       T reg 
#>         160         180          76          90         110          24
```

## Subsetting

`SpatialCellData` follows matrix-style `[cells, markers]` subsetting.
Both indices are optional.

``` r

# By cells: keep one sample
a <- spe[spe$sample_id == "tonsil_A", ]
dim(a)
#> [1] 320   8

# By cells: keep just the B-cell follicle
follicle <- spe[spe$phenotype == "B cell", ]
NCells(follicle)
#> [1] 160

# By markers: keep two channels
spe[, c("CD3", "CD20")]
#> A SpatialCellData object
#>   640 cells across 2 samples
#>   Markers: CD3, CD20 
#>   Normalised: TRUE 
#>   Phenotypes: 6 
#>   Project: phenoscapR example (tonsil, simulated)
```

Subsetting carries every slot — counts, normalised data, coordinates,
metadata, and any reductions — along together, so downstream analysis on
a subset is always self-consistent.

## Next steps

- **[Getting
  Started](https://cttir.github.io/phenoscapR/articles/phenoscapR.md)**
  — the end-to-end workflow
- **[Advanced Spatial
  Analysis](https://cttir.github.io/phenoscapR/articles/phenoscapR-03-spatial-analysis.md)**
  — Ripley’s K, Moran’s I, neighbourhood enrichment, and choosing a
  statistic
- **[Visualisation
  Gallery](https://cttir.github.io/phenoscapR/articles/phenoscapR-04-visualisation.md)**
  — every plot
