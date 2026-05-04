# Plot Marker Heatmap

Heatmap of mean marker intensity per phenotype. Analogous to Seurat's
`DoHeatmap`.

## Usage

``` r
MarkerHeatmap(
  object,
  markers = NULL,
  slot = "data",
  palette = NULL,
  title = NULL
)
```

## Arguments

- object:

  An
  [`SpatialCellData`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object with a `phenotype` column.

- markers:

  Character vector or `NULL`. Markers to include. If `NULL`, all markers
  are shown.

- slot:

  Character. Data slot to use: `"data"` (default) or `"counts"`.

- palette:

  Character or character vector. Default `NULL` (global palette).

- title:

  Character or `NULL`.

## Value

A `ggplot` object.

## Examples

``` r
counts <- matrix(c(rnorm(30, 1), rnorm(30, 0), rnorm(30, 0),
                   rnorm(30, 1)), ncol = 2,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(60), y = runif(60))
meta <- data.frame(cell_id = 1:60, sample_id = "s1",
                   phenotype = rep(c("A", "B"), each = 30))
obj <- CreateSpatialObject(counts, coords, meta)
MarkerHeatmap(obj)

```
