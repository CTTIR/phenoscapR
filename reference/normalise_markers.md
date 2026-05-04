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
#>    sample_id cell_id          x          y        CD3        CD8
#>       <char>   <int>      <num>      <num>      <num>      <num>
#> 1:        s1       1 0.61587103 0.09783228  2.1441755 -1.3573112
#> 2:        s1       2 0.92514029 0.96368953 -1.2434396  0.4955469
#> 3:        s1       3 0.39002290 0.16873644 -1.0206421 -0.2502830
#> 4:        s1       4 0.28791969 0.08608341 -0.5819260  0.6036380
#> 5:        s1       5 0.09073596 0.86121070 -0.9252166 -0.3250005
#> 6:        s1       6 0.32203390 0.52479060 -0.5227012 -0.8501387
```
