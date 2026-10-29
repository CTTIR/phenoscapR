# Read NanoString CosMx Cell Output

Convenience wrapper for CosMx: the `*_exprMat_file.csv` (cell-by-gene,
with `fov`/`cell_ID` columns) and `*_metadata_file.csv` (with
`CenterX_global_px`/`CenterY_global_px`). CosMx numbers cells within
each FOV, so cells are matched on `fov` and `cell_ID`; the `cell_ID`
becomes `cell_id` and `fov` is kept.

## Usage

``` r
ReadCosMx(expr_file, meta_file, sample_id = "sample1", project = "CosMx")
```

## Arguments

- expr_file:

  Path/data frame of the expression matrix.

- meta_file:

  Path/data frame of the cell metadata.

- sample_id, project:

  Passed to
  [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/dev/reference/ReadMatrixCoords.md).

## Value

A
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/dev/reference/SpatialCellData-class.md)
object.

## Examples

``` r
expr_file <- tempfile(fileext = ".csv")
meta_file <- tempfile(fileext = ".csv")
write.csv(data.frame(fov = c(1, 1, 2, 2), cell_ID = c(1, 2, 1, 2),
                     CD3E = c(3, 0, 1, 5), KRT8 = c(0, 9, 2, 0)),
          expr_file, row.names = FALSE)
write.csv(data.frame(fov = c(1, 1, 2, 2), cell_ID = c(1, 2, 1, 2),
                     CenterX_global_px = c(100, 140, 2100, 2160),
                     CenterY_global_px = c(50, 80, 60, 95)),
          meta_file, row.names = FALSE)
obj <- ReadCosMx(expr_file, meta_file)
obj
#> A SpatialCellData object
#>   4 cells across 1 sample
#>   Markers: CD3E, KRT8 
#>   Normalised: FALSE 
#>   Project: CosMx 
unlink(c(expr_file, meta_file))
```
