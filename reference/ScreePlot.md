# Scree Plot of PCA Variance

Bar-and-line plot of the percent variance explained by each principal
component – the standard tool for choosing how many PCs to retain.

## Usage

``` r
ScreePlot(object, n_pcs = NULL)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- n_pcs:

  Integer or `NULL`. Number of PCs to show. Default all.

## Value

A `ggplot` object.

## Examples

``` r
counts <- matrix(rnorm(500), nrow = 50,
                 dimnames = list(NULL, paste0("M", 1:10)))
coords <- data.frame(x = runif(50), y = runif(50))
obj <- RunPCA(CreateSpatialObject(counts, coords), n_pcs = 8)
ScreePlot(obj)

```
