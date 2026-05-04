# Find Nearest Neighbours (SpatialCellData)

For each cell, computes the distance to the `k` nearest neighbours.

## Usage

``` r
FindNeighbours(object, k = 1L, target = NULL)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- k:

  Integer. Number of nearest neighbours. Default `1`.

- target:

  Character or `NULL`. Restrict to a specific phenotype.

## Value

An
[`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
with `nn_distance` added to `meta_data` and stored in the `spatial`
slot.

## Examples

``` r
counts <- matrix(rnorm(40), nrow = 20,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(20, 0, 100), y = runif(20, 0, 100))
obj <- CreateSpatialObject(counts, coords)
obj <- FindNeighbours(obj, k = 3)
```
