# Subset a SpatialCellData Object

Subset a SpatialCellData Object

## Usage

``` r
# S4 method for class 'SpatialCellData'
x[i, j, drop = FALSE]
```

## Arguments

- x:

  A
  [`SpatialCellData`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- i:

  Cell indices (integer or logical).

- j:

  Marker indices (integer, logical, or character).

- drop:

  Ignored.

## Value

A subsetted `SpatialCellData` object.
