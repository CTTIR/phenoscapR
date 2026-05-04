# Cell Density (SpatialCellData)

Estimates local cell density by counting neighbours within a radius.

## Usage

``` r
CellDensity(object, radius, target = NULL)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- radius:

  Numeric. Radius of the neighbourhood.

- target:

  Character or `NULL`. Restrict to a specific phenotype.

## Value

An
[`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
with `density` added to `meta_data`.

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
obj <- CreateSpatialObject(counts, coords)
obj <- CellDensity(obj, radius = 20)
```
