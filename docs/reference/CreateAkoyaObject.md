# Create an AkoyaExperiment from Existing Data

Constructs an
[`AkoyaExperiment-class`](https://r-heller.github.io/phenoscapR/reference/AkoyaExperiment-class.md)
from a counts matrix, coordinate data frame, and optional metadata.

## Usage

``` r
CreateAkoyaObject(
  counts,
  coords,
  meta_data = NULL,
  sample_id = "sample1",
  project = "AkoyaProject"
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

  Character. Project name. Default `"AkoyaProject"`.

## Value

An
[`AkoyaExperiment-class`](https://r-heller.github.io/phenoscapR/reference/AkoyaExperiment-class.md)
object.

## Examples

``` r
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10, 0, 500), y = runif(10, 0, 500))
obj <- CreateAkoyaObject(counts, coords, sample_id = "mysample")
obj
#> An AkoyaExperiment object
#>   10 cells across 1 sample
#>   Markers: CD3, CD8, CD20, DAPI, PanCK 
#>   Normalised: FALSE 
#>   Project: AkoyaProject 
```
