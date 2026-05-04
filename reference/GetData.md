# Get Expression Data

Retrieve raw counts or normalised data from a SpatialCellData object.

## Usage

``` r
GetData(object, slot = "data")

# S4 method for class 'SpatialCellData'
GetData(object, slot = "data")
```

## Arguments

- object:

  A
  [`SpatialCellData`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- slot:

  Character. `"counts"` for raw data or `"data"` (default) for
  normalised data.

## Value

A numeric matrix (cells x markers).
