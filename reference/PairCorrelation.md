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
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
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
#> 1   1.000000 4.9628986
#> 2   1.946507 0.0000000
#> 3   2.893013 0.0000000
#> 4   3.839520 1.2925831
#> 5   4.786027 1.0369559
#> 6   5.732534 0.0000000
#> 7   6.679040 2.2291670
#> 8   7.625547 0.0000000
#> 9   8.572054 1.1579252
#> 10  9.518560 0.0000000
#> 11 10.465067 0.0000000
#> 12 11.411574 0.0000000
#> 13 12.358080 0.8031828
#> 14 13.304587 0.7460432
#> 15 14.251094 0.6964937
#> 16 15.197601 0.6531161
#> 17 16.144107 0.9222372
#> 18 17.090614 0.5807748
#> 19 18.037121 1.1005966
#> 20 18.983627 0.5228609
#> 21 19.930134 0.9960593
#> 22 20.876641 0.9508998
#> 23 21.823148 1.8193154
#> 24 22.769654 0.6538833
#> 25 23.716161 1.0463116
#> 26 24.662668 1.2073873
#> 27 25.609174 0.1937938
#> 28 26.555681 0.3737730
#> 29 27.502188 0.7218187
#> 30 28.448694 1.2211559
#> 31 29.395201 0.8441682
#> 32 30.341708 0.6542675
#> 33 31.288215 0.4758564
#> 34 32.234721 0.1539613
#> 35 33.181228 0.8974168
#> 36 34.127735 0.7271064
#> 37 35.074241 0.7074848
#> 38 36.020748 0.2755578
#> 39 36.967255 1.0740097
#> 40 37.913762 0.3926990
#> 41 38.860268 0.7662683
#> 42 39.806775 0.8727231
#> 43 40.753282 0.4871165
#> 44 41.699788 0.3570449
#> 45 42.646295 0.2327470
#> 46 43.592802 0.4553870
#> 47 44.539309 0.6685643
#> 48 45.485815 0.8728697
#> 49 46.432322 0.9619611
#> 50 47.378829 0.4189972
```
