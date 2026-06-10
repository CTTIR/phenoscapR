# Create a SpatialCellData Object from Existing Data

Constructs a
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
object from a counts matrix, coordinate data frame, and optional
metadata.

## Usage

``` r
CreateSpatialObject(
  counts,
  coords,
  meta_data = NULL,
  sample_id = "sample1",
  project = "SpatialProject"
)
```

## Arguments

- counts:

  Numeric matrix (cells x markers). Row names are optional.

- coords:

  Data frame with columns `x` and `y`.

- meta_data:

  Data frame of per-cell metadata, or `NULL`.

- sample_id:

  Character. Sample identifier. Default `"sample1"`.

- project:

  Character. Project name. Default `"SpatialProject"`.

## Value

A
[`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
object.

## Examples

``` r
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10, 0, 500), y = runif(10, 0, 500))
obj <- CreateSpatialObject(counts, coords, sample_id = "mysample")
obj
#> A SpatialCellData object
#>   10 cells across 1 sample
#>   Markers: CD3, CD8, CD20, DAPI, PanCK 
#>   Normalised: FALSE 
#>   Project: SpatialProject 
```
