# Quadrat Analysis

Divides the tissue area into a grid and counts cells per quadrat. Tests
for Complete Spatial Randomness using a chi-squared test.

## Usage

``` r
QuadratAnalysis(object, nx = 5L, ny = 5L, target = NULL)
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
#> $counts
#>      [,1] [,2] [,3]
#> [1,]    5    3    5
#> [2,]    5    5    6
#> [3,]    8    2   11
#> 
#> $chi_sq
#> [1] 10.12
#> 
#> $p_value
#> [1] 0.2567043
#> 
#> $VMR
#> [1] 1.265
#> 
```
