# Cross Nearest Neighbour Distance

Computes the nearest neighbour distance from each cell of one phenotype
to cells of another phenotype.

## Usage

``` r
CrossNNDistance(object, from, to)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- from:

  Character. Source phenotype.

- to:

  Character. Target phenotype.

## Value

A numeric vector of distances (one per cell of the `from` phenotype).

## Examples

``` r
counts <- matrix(rnorm(60), nrow = 30,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(30, 0, 100), y = runif(30, 0, 100))
meta <- data.frame(cell_id = 1:30, sample_id = "s1",
  phenotype = rep(c("A", "B", "C"), each = 10))
obj <- CreateSpatialObject(counts, coords, meta)
CrossNNDistance(obj, from = "A", to = "B")
#>  [1] 44.260797 15.592192 33.997372 40.314488 28.982696 14.430704  4.522267
#>  [8] 21.991067 14.004335 11.933756
```
