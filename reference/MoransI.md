# Moran's I Spatial Autocorrelation

Computes Moran's I statistic for a numeric variable.

## Usage

``` r
MoransI(object, feature, radius, slot = "data")
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- feature:

  Character. Name of the marker or metadata column.

- radius:

  Numeric. Neighbourhood radius for spatial weights.

- slot:

  Character. `"data"` (default) or `"counts"`.

## Value

A list with `I`, `expected`, `variance`, `z_score`, and `p_value`.

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
obj <- CreateSpatialObject(counts, coords)
MoransI(obj, feature = "CD3", radius = 30)
#> $I
#> [1] -0.04597222
#> 
#> $expected
#> [1] -0.02040816
#> 
#> $variance
#> [1] 0.002476229
#> 
#> $z_score
#> [1] -0.5137293
#> 
#> $p_value
#> [1] 0.6074413
#> 
```
