# Plot Cell Density

Scatter plot with colour scaled by local cell density. Requires
[`CellDensity`](https://cttir.github.io/phenoscapR/reference/CellDensity.md)
to have been run.

## Usage

``` r
DensityPlot(object, pt_size = 1, title = NULL, palette = NULL)
```

## Arguments

- object:

  An
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object with a `density` column.

- pt_size:

  Numeric. Point size. Default `1`.

- title:

  Character or `NULL`.

- palette:

  Character or character vector. Default `NULL` (global palette).

## Value

A `ggplot` object.

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
obj <- CreateSpatialObject(counts, coords)
obj <- CellDensity(obj, radius = 20)
DensityPlot(obj)

```
