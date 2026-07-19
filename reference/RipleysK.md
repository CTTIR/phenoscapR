# Ripley's K Function

Computes Ripley's K function to assess spatial clustering or dispersion
at multiple scales.

## Usage

``` r
RipleysK(
  object,
  r_seq = NULL,
  target = NULL,
  correction = c("none", "border", "translation"),
  by_sample = FALSE
)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- r_seq:

  Numeric vector of radii, or `NULL` for automatic.

- target:

  Character or `NULL`. Restrict to a phenotype.

- correction:

  Character. Edge correction: `"none"` (default), `"border"`
  (reduced-sample), or `"translation"` (each pair weighted by the
  inverse window/translate overlap; rigorous for rectangular windows).

- by_sample:

  Logical. If `TRUE` and the object holds several samples, the statistic
  is computed per sample and returned as a named list (one entry per
  sample). Default `FALSE`; otherwise a single sample is required.

## Value

A data frame with columns `r`, `K`, `L`, and `expected`.

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 200), y = runif(50, 0, 200))
obj <- CreateSpatialObject(counts, coords)
RipleysK(obj)
#> <phenoscapR> Ripley's K / none correction
#>   50 radii from 0 to 48.1
#>   L(r) range: [-8.53, 0.188]  (>0 clustered, <0 dispersed)
#>           r        K          L  expected
#> 1 0.0000000  0.00000  0.0000000  0.000000
#> 2 0.9826464  0.00000 -0.9826464  3.033503
#> 3 1.9652927  0.00000 -1.9652927 12.134010
#> 4 2.9479391 30.43591  0.1646242 27.301523
```
