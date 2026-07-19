# Read Vizgen MERSCOPE Cell Output

Convenience wrapper for MERSCOPE: `cell_by_gene.csv` (cell-by-gene,
first column the cell id) and `cell_metadata.csv` (with
`center_x`/`center_y`).

## Usage

``` r
ReadMERSCOPE(
  matrix_file,
  metadata_file,
  sample_id = "sample1",
  project = "MERSCOPE"
)
```

## Arguments

- matrix_file:

  Path/data frame of the cell-by-gene matrix.

- metadata_file:

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
obj <- ReadMERSCOPE("cell_by_gene.csv", "cell_metadata.csv")
} # }
```
