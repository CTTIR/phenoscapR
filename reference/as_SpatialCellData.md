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
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
object.

## Examples

``` r
if (FALSE) { # \dontrun{
obj <- as_SpatialCellData(seurat_object)
} # }
```
