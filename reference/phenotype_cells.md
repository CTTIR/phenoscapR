# Phenotype Cells by Marker Thresholds

Assigns phenotype labels to cells based on marker intensity thresholds.
A cell is considered positive for a marker if its intensity exceeds the
given threshold.

## Usage

``` r
phenotype_cells(dt, thresholds, labels = NULL)
```

## Arguments

- dt:

  A `data.table` as returned by
  [`read_spatial()`](https://cttir.github.io/phenoscapR/reference/read_spatial.md)
  or
  [`normalise_markers()`](https://cttir.github.io/phenoscapR/reference/normalise_markers.md).

- thresholds:

  A named list where names are marker column names and values are
  numeric thresholds. Example: `list(CD3 = 0.5, CD8 = 0.3)`.

- labels:

  A named character vector mapping phenotype signatures to labels, or
  `NULL` for automatic labelling. When `NULL`, phenotypes are labelled
  by concatenating positive marker names with `"+"`.

## Value

The input `data.table` with an added `phenotype` column.

## Examples

``` r
dt <- data.table::data.table(
  sample_id = "s1", cell_id = 1:6,
  x = runif(6), y = runif(6),
  CD3 = c(0.8, 0.1, 0.9, 0.2, 0.7, 0.05),
  CD8 = c(0.1, 0.6, 0.7, 0.05, 0.8, 0.02)
)
result <- phenotype_cells(dt, thresholds = list(CD3 = 0.5, CD8 = 0.5))
table(result$phenotype)
#> 
#>      CD3+ CD3+/CD8+      CD8+  Negative 
#>         1         2         1         2 
```
