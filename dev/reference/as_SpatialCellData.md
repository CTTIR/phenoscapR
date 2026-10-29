# Convert a Seurat or SpatialExperiment Object to SpatialCellData

Imports an object from the wider ecosystem. Coordinates are taken from
`spatialCoords` (SpatialExperiment) or from `x`/`y` metadata columns or
a `"spatial"` reduction (Seurat).

## Usage

``` r
as_SpatialCellData(x, ...)
```

## Arguments

- x:

  A `Seurat` or `SpatialExperiment` object.

- ...:

  Unused.

## Value

A
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/dev/reference/SpatialCellData-class.md)
object.

## Examples

``` r
# \donttest{
if (requireNamespace("Seurat", quietly = TRUE)) {
  counts <- matrix(c(5, 0, 3, 1, 2, 7, 0, 4, 6, 1, 2, 3), nrow = 4,
                   dimnames = list(NULL, c("CD3", "CD8", "CD20")))
  obj <- CreateSpatialObject(counts, data.frame(x = c(1, 5, 9, 4), y = c(2, 8, 3, 6)))
  seurat_object <- as_Seurat(obj)
  as_SpatialCellData(seurat_object)
}
#> A SpatialCellData object
#>   4 cells across 1 sample
#>   Markers: CD3, CD8, CD20 
#>   Normalised: FALSE 
#>   Project: SpatialProject 
# }
```
