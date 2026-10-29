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
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/dev/reference/SpatialCellData-class.md)
  object.

## Value

A `SpatialExperiment` object.

## Examples

``` r
# \donttest{
if (requireNamespace("SpatialExperiment", quietly = TRUE)) {
  counts <- matrix(c(5, 0, 3, 1, 2, 7, 0, 4, 6, 1, 2, 3), nrow = 4,
                   dimnames = list(NULL, c("CD3", "CD8", "CD20")))
  obj <- CreateSpatialObject(counts, data.frame(x = c(1, 5, 9, 4), y = c(2, 8, 3, 6)))
  spe <- as_SpatialExperiment(obj)
}
#> Warning: replacing previous import ‘S4Arrays::makeNindexFromArrayViewport’ by ‘DelayedArray::makeNindexFromArrayViewport’ when loading ‘SummarizedExperiment’
# }
```
