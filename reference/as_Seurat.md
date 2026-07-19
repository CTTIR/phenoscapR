# Convert a SpatialCellData to a Seurat Object

Builds a Seurat object with raw counts, normalised data, cell metadata,
and the spatial coordinates stored both in metadata (`x`, `y`) and as a
`"spatial"` dimensional reduction.

## Usage

``` r
as_Seurat(object)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

A `Seurat` object.

## Examples

``` r
# \donttest{
if (requireNamespace("Seurat", quietly = TRUE)) {
  data(phenoscapR_example)
  se <- as_Seurat(phenoscapR_example)
}
# }
```
