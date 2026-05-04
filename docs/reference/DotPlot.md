# Dot Plot of Marker Expression

Dot plot where dot size represents the percentage of cells expressing a
marker (above a threshold) and colour represents the mean expression.
Analogous to Seurat's `DotPlot`.

## Usage

``` r
DotPlot(
  object,
  features,
  group_by = "phenotype",
  slot = "data",
  threshold = 0,
  palette = NULL
)
```

## Arguments

- object:

  An
  [`SpatialCellData`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- features:

  Character vector. Marker names to plot.

- group_by:

  Character. Metadata column to group by. Default `"phenotype"`.

- slot:

  Character. `"data"` or `"counts"`.

- threshold:

  Numeric. Expression threshold to call a cell "expressing". Default
  `0`.

- palette:

  Character or character vector. Colour palette for mean expression.
  Default `NULL` (global palette).

## Value

A `ggplot` object.

## Examples

``` r
counts <- matrix(c(rnorm(60, 5), rnorm(60, 0)), ncol = 4,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "PanCK")))
coords <- data.frame(x = runif(30), y = runif(30))
meta <- data.frame(cell_id = 1:30, sample_id = "s1",
                   phenotype = rep(c("T cell", "B cell", "Other"), each = 10))
obj <- CreateSpatialObject(counts, coords, meta)
DotPlot(obj, features = c("CD3", "CD8", "CD20", "PanCK"))

```
