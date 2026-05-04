# Subset an AkoyaExperiment

Subset an AkoyaExperiment

## Usage

``` r
# S4 method for class 'AkoyaExperiment'
x[i, j, drop = FALSE]
```

## Arguments

- x:

  An
  [`AkoyaExperiment`](https://r-heller.github.io/phenoscapR/reference/AkoyaExperiment-class.md)
  object.

- i:

  Cell indices (integer or logical).

- j:

  Marker indices (integer, logical, or character).

- drop:

  Ignored.

## Value

A subsetted `AkoyaExperiment`.
