# Pair Correlation Function

Computes the pair correlation function g(r), the derivative of Ripley's
K, measuring clustering/inhibition at specific distances.

## Usage

``` r
PairCorrelation(object, r_seq = NULL, dr = NULL, target = NULL)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- r_seq:

  Numeric vector of radii, or `NULL` for automatic.

- dr:

  Numeric or `NULL`. Ring width. Default is derived from `r_seq`.

- target:

  Character or `NULL`. Restrict to a phenotype.

## Value

A data frame with columns `r` and `g`.

## Examples

``` r
counts <- matrix(rnorm(100), nrow = 50,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(50, 0, 200), y = runif(50, 0, 200))
obj <- CreateSpatialObject(counts, coords)
PairCorrelation(obj)
#>            r         g
#> 1   1.000000 0.0000000
#> 2   1.906672 2.5764235
#> 3   2.813344 0.0000000
#> 4   3.720016 0.0000000
#> 5   4.626687 0.0000000
#> 6   5.533359 0.0000000
#> 7   6.440031 0.0000000
#> 8   7.346703 0.0000000
#> 9   8.253375 0.0000000
#> 10  9.160047 1.0725697
#> 11 10.066718 0.4879837
#> 12 10.973390 0.0000000
#> 13 11.880062 1.2404971
#> 14 12.786734 2.3050738
#> 15 13.693406 1.4349664
#> 16 14.600078 0.6729271
#> 17 15.506749 0.6335814
#> 18 16.413421 1.4964565
#> 19 17.320093 1.1344960
#> 20 18.226765 0.2695154
#> 21 19.133437 0.7702318
#> 22 20.040109 0.4902562
#> 23 20.946780 0.9380714
#> 24 21.853452 0.6743640
#> 25 22.760124 0.6475001
#> 26 23.666796 1.2453889
#> 27 24.573468 0.5997193
#> 28 25.480140 0.9639653
#> 29 26.386811 0.3723371
#> 30 27.293483 0.7199366
#> 31 28.200155 0.6967897
#> 32 29.106827 1.0126272
#> 33 30.013499 0.4910185
#> 34 30.920171 1.2709876
#> 35 31.826842 0.7717376
#> 36 32.733514 0.9004339
#> 37 33.640186 0.2920551
#> 38 34.546858 0.2843902
#> 39 35.453530 1.1084694
#> 40 36.360202 0.4053108
#> 41 37.266873 1.0545331
#> 42 38.173545 0.5147433
#> 43 39.080217 0.5028011
#> 44 39.986889 0.6142506
#> 45 40.893561 0.7207581
#> 46 41.800233 0.9401659
#> 47 42.706904 1.1502576
#> 48 43.613576 0.3379036
#> 49 44.520248 0.4413627
#> 50 45.426920 0.7569687
```
