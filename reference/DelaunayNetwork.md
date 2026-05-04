# Delaunay Triangulation Network

Computes a Delaunay triangulation of cell positions and stores edges in
the `spatial` slot.

## Usage

``` r
DelaunayNetwork(object, max_edge = NULL)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- max_edge:

  Numeric or `NULL`. Maximum edge length to retain.

## Value

An
[`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
with `delaunay_edges` stored in the `spatial` slot.

## Examples

``` r
counts <- matrix(rnorm(40), nrow = 20,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(20, 0, 100), y = runif(20, 0, 100))
obj <- CreateSpatialObject(counts, coords)
obj <- DelaunayNetwork(obj, max_edge = 30)
```
