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
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/dev/reference/SpatialCellData-class.md)
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
#>   50 radii from 0 to 45.2
#>   L(r) range: [-5.17, 1.96]  (>0 clustered, <0 dispersed)
#>           r K          L  expected
#> 1 0.0000000 0  0.0000000  0.000000
#> 2 0.9232469 0 -0.9232469  2.677846
#> 3 1.8464938 0 -1.8464938 10.711384
#> 4 2.7697408 0 -2.7697408 24.100614
```
