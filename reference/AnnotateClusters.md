# Annotate Clusters by Their Top Markers

Labels each cluster (or any categorical grouping) by the markers most
enriched in it relative to the global mean, producing human-readable
names such as `"CD3+CD8"`.

## Usage

``` r
AnnotateClusters(
  object,
  group = "expr_cluster",
  slot = "data",
  n_markers = 2L,
  add_column = TRUE
)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- group:

  Character. Metadata column holding cluster labels. Default
  `"expr_cluster"`.

- slot:

  Character. `"data"` (default) or `"counts"`.

- n_markers:

  Integer. Number of top markers per cluster name. Default `2`.

- add_column:

  Logical. If `TRUE` (default) also store the names in a new
  `<group>_label` metadata column.

## Value

A named character vector mapping each group level to its marker label.
If `add_column` the object is returned instead, with the label column
added (access the mapping via `attr(., "labels")`).

## Examples

``` r
data(phenoscapR_example)
obj <- NormaliseData(phenoscapR_example, "zscore")
obj <- ExpressionClusters(obj, k = 6)
AnnotateClusters(obj, add_column = FALSE)
#>            1            2            3            4            5            6 
#>    "CD8CD3+"    "CD4CD3+"  "CD20Ki67+"      "CD68+" "PanCKKi67+"  "FoxP3CD4+" 
```
