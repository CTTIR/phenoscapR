# Cross Nearest Neighbour Distance

Computes the nearest neighbour distance from each cell of one phenotype
to cells of another phenotype.

## Usage

``` r
CrossNNDistance(object, from, to, by_sample = FALSE)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- from:

  Character. Source phenotype.

- to:

  Character. Target phenotype.

- by_sample:

  Logical. If `TRUE` and the object holds several samples, the statistic
  is computed per sample and returned as a named list. Default `FALSE`;
  otherwise a single sample is required.

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
#> <phenoscapR> Cross nearest-neighbour distances
#>   A -> B : 10 cells
#>   median 11.3, mean 13, range [6.36, 28]
```
