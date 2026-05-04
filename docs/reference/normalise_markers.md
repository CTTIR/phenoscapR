# Normalise Marker Intensities

Normalises marker intensity columns using one of several methods.

## Usage

``` r
normalise_markers(
  dt,
  method = c("zscore", "minmax", "quantile"),
  markers = NULL
)
```

## Arguments

- dt:

  A `data.table` as returned by
  [`read_spatial()`](https://r-heller.github.io/phenoscapR/reference/read_spatial.md).

- method:

  Character string. Normalisation method: `"zscore"` (default),
  `"minmax"`, or `"quantile"`.

- markers:

  Character vector or `NULL`. Marker columns to normalise. If `NULL`,
  all detected marker columns are normalised.

## Value

A `data.table` with normalised marker intensities.

## Examples

``` r
dt <- data.table::data.table(
  sample_id = "s1", cell_id = 1:20,
  x = runif(20), y = runif(20),
  CD3 = rnorm(20, 500, 100),
  CD8 = rnorm(20, 300, 80)
)
norm_dt <- normalise_markers(dt, method = "zscore")
head(norm_dt)
#>    sample_id cell_id         x         y         CD3        CD8
#>       <char>   <int>     <num>     <num>       <num>      <num>
#> 1:        s1       1 0.3351543 0.3481136  0.03769391  0.5723434
#> 2:        s1       2 0.9886092 0.5102482  0.13154239 -1.0675098
#> 3:        s1       3 0.9140789 0.7921957 -0.42751452 -0.3112361
#> 4:        s1       4 0.5350972 0.4412106 -0.51017714  1.7771047
#> 5:        s1       5 0.2468937 0.2862922  0.99118136 -0.1976915
#> 6:        s1       6 0.9223468 0.9335603  0.26338805 -0.4604396
```
