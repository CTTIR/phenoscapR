# Read NanoString CosMx Cell Output

Convenience wrapper for CosMx: the `*_exprMat_file.csv` (cell-by-gene,
with `fov`/`cell_ID` columns) and `*_metadata_file.csv` (with
`CenterX_global_px`/`CenterY_global_px`).

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
  [`ReadMatrixCoords()`](https://cttir.github.io/phenoscapR/reference/ReadMatrixCoords.md).

## Value

A
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
object.

## Examples

``` r
if (FALSE) { # \dontrun{
obj <- ReadCosMx("sample_exprMat_file.csv", "sample_metadata_file.csv")
} # }
```
