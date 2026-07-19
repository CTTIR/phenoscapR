# Pair Correlation Function

Computes the pair correlation function g(r), the derivative of Ripley's
K, measuring clustering/inhibition at specific distances.

## Usage

``` r
PairCorrelation(
  object,
  r_seq = NULL,
  dr = NULL,
  target = NULL,
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

- dr:

  Numeric or `NULL`. Ring width. Default is derived from `r_seq`.

- target:

  Character or `NULL`. Restrict to a phenotype.

- by_sample:

  Logical. If `TRUE` and the object holds several samples, the statistic
  is computed per sample and returned as a named list. Default `FALSE`;
  otherwise a single sample is required.

## Value

A data frame with columns `r` and `g`.

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 200), y = runif(50, 0, 200))
obj <- CreateSpatialObject(counts, coords)
PairCorrelation(obj)
#> <phenoscapR> Pair correlation function g(r)
#>   50 radii from 1 to 47.4; peak g = 4.96 at r = 1
#>          r        g
#> 1 1.000000 4.962899
#> 2 1.946507 0.000000
#> 3 2.893013 0.000000
#> 4 3.839520 1.292583
```
