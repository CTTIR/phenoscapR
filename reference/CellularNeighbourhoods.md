# Cellular Neighbourhoods (Niches)

Assigns each cell to a cellular neighbourhood ("niche") by clustering
cells on the phenotype composition of their local spatial neighbourhood.
This is the windowed-neighbourhood approach popularised for multiplexed
imaging: for every cell the phenotype frequencies among its `k` nearest
neighbours form a composition vector, and those vectors are clustered.

## Usage

``` r
CellularNeighbourhoods(
  object,
  n_neighbourhoods = 8L,
  k = 20L,
  phenotype_col = "phenotype",
  seed = NULL
)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object with a phenotype column.

- n_neighbourhoods:

  Integer. Number of neighbourhoods to find. Default `8`.

- k:

  Integer. Neighbourhood size (nearest neighbours per cell). Default
  `20`.

- phenotype_col:

  Character. Metadata column of phenotype labels. Default `"phenotype"`.

- seed:

  Integer or `NULL`. Random seed for k-means.

## Value

The object with a `neighbourhood` column in `meta_data`; the
neighbourhood-by-phenotype composition matrix is stored in
`object@spatial$neighbourhood_composition`.

## Examples

``` r
data(phenoscapR_example)
obj <- phenoscapR_example
obj@meta_data$phenotype <- obj@meta_data$phenotype_true
obj <- CellularNeighbourhoods(obj, n_neighbourhoods = 5, k = 15, seed = 1)
table(obj$neighbourhood)
#> 
#> CN1 CN2 CN3 CN4 CN5 
#> 177 103 181  48 131 
```
