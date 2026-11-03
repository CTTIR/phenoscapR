# Moran's I Spatial Autocorrelation

Computes Moran's I statistic for a numeric variable.

## Usage

``` r
MoransI(
  object,
  feature,
  radius,
  slot = "data",
  weights = c("binary", "row", "idw"),
  n_perm = 0L,
  seed = NULL,
  by_sample = FALSE
)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- feature:

  Character. Name of the marker or metadata column.

- radius:

  Numeric. Neighbourhood radius for spatial weights.

- slot:

  Character. `"data"` (default) or `"counts"`.

- weights:

  Character. Spatial weighting within the radius: `"binary"` (default; 1
  for every neighbour), `"row"` (row-standardised, each cell's weights
  sum to 1), or `"idw"` (inverse-distance, `1 / d`).

- n_perm:

  Integer. Number of label permutations for the p-value. `0` (default)
  uses the analytic normal approximation, which is exact only for
  `"binary"` weights; any other weighting auto-enables a permutation
  test.

- seed:

  Integer or `NULL`. Random seed for the permutation test.

- by_sample:

  Logical. If `TRUE` and the object holds several samples, the statistic
  is computed per sample and returned as a named list. Default `FALSE`;
  otherwise a single sample is required.

## Value

A list with `I`, `expected`, `variance`, `z_score`, `p_value`, and
`method` (`"analytic"` or `"permutation"`).

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
obj <- CreateSpatialObject(counts, coords)
MoransI(obj, feature = "CD3", radius = 30)
#> <phenoscapR> Moran's I spatial autocorrelation
#>   I = -0.0460   (expected -0.0204 under no autocorrelation)
#>   z = -0.514, p = 0.607
#>   no significant spatial autocorrelation
MoransI(obj, feature = "CD3", radius = 30, weights = "idw", n_perm = 199)
#> <phenoscapR> Moran's I spatial autocorrelation
#>   I = -0.0699   (expected -0.0204 under no autocorrelation)
#>   z = -0.721, p = 0.46
#>   no significant spatial autocorrelation
```
