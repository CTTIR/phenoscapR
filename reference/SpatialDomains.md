# Spatial Domains

Partitions the tissue into spatial domains (regions of coherent marker
expression) by clustering cells on their spatially smoothed expression:
each cell's profile is averaged with its `k` nearest neighbours before
clustering, so neighbouring cells tend to share a domain.

## Usage

``` r
SpatialDomains(
  object,
  n_domains = 6L,
  k = 20L,
  slot = "data",
  markers = NULL,
  seed = NULL
)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- n_domains:

  Integer. Number of domains. Default `6`.

- k:

  Integer. Number of neighbours to smooth over. Default `20`.

- slot:

  Character. `"data"` (default) or `"counts"`.

- markers:

  Character vector or `NULL`. Markers to use; `NULL` uses all.

- seed:

  Integer or `NULL`. Random seed for k-means.

## Value

The object with a `domain` column in `meta_data`.

## Examples

``` r
data(phenoscapR_example)
obj <- NormaliseData(phenoscapR_example, "zscore")
obj <- SpatialDomains(obj, n_domains = 4, k = 15, seed = 1)
table(obj$domain)
#> 
#>  D1  D2  D3  D4 
#> 177  57 186 220 
```
