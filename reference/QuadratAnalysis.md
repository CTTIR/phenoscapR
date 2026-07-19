# Quadrat Analysis

Divides the tissue area into a grid and counts cells per quadrat. Tests
for Complete Spatial Randomness using a chi-squared test.

## Usage

``` r
QuadratAnalysis(object, nx = 5L, ny = 5L, target = NULL, by_sample = FALSE)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- nx:

  Integer. Number of columns in the grid. Default `5`.

- ny:

  Integer. Number of rows in the grid. Default `5`.

- target:

  Character or `NULL`. Restrict to a phenotype.

- by_sample:

  Logical. If `TRUE` and the object holds several samples, the statistic
  is computed per sample and returned as a named list. Default `FALSE`;
  otherwise a single sample is required.

## Value

A list with `counts`, `chi_sq`, `p_value`, and `VMR` (variance-to-mean
ratio).

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 100), y = runif(50, 0, 100))
obj <- CreateSpatialObject(counts, coords)
QuadratAnalysis(obj, nx = 3, ny = 3)
#> <phenoscapR> Quadrat analysis (chi-squared test of CSR)
#>   grid 3 x 3; chi-sq = 10.1, p = 0.257; VMR = 1.27
#>   clustered (VMR > 1)
```
