# Convert a SpatialCellData to a SpatialExperiment Object

Builds a SpatialExperiment with `counts` and `logcounts` assays (markers
x cells), the metadata as `colData`, and the coordinates as
`spatialCoords`.

## Usage

``` r
as_SpatialExperiment(object)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

A `SpatialExperiment` object.

## Examples

``` r
# \donttest{
if (requireNamespace("SpatialExperiment", quietly = TRUE)) {
  data(phenoscapR_example)
  spe <- as_SpatialExperiment(phenoscapR_example)
}
# }
```
