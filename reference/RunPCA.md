# Principal Component Analysis

Computes a PCA embedding of the marker-expression matrix and stores it
in the `reductions` slot under the name `"pca"`. PCA uses only base R
and is always available; it is also the default input space for
[`RunUMAP`](https://cttir.github.io/phenoscapR/reference/RunUMAP.md),
[`RunTSNE`](https://cttir.github.io/phenoscapR/reference/RunTSNE.md),
and
[`RunSONG`](https://cttir.github.io/phenoscapR/reference/RunSONG.md).

## Usage

``` r
RunPCA(object, n_pcs = 30L, slot = "data", markers = NULL)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- n_pcs:

  Integer. Number of principal components to keep. Capped at the rank of
  the data. Default `30`.

- slot:

  Character. `"data"` (default) or `"counts"`.

- markers:

  Character vector or `NULL`. Markers to use; `NULL` uses all.

## Value

The object with a `"pca"` entry in its `reductions` slot.

## Examples

``` r
counts <- matrix(rnorm(500), nrow = 50,
                 dimnames = list(NULL, paste0("M", 1:10)))
coords <- data.frame(x = runif(50), y = runif(50))
obj <- CreateSpatialObject(counts, coords)
obj <- RunPCA(obj, n_pcs = 5)
Embeddings(obj, "pca")[1:3, ]
#>           PC_1      PC_2        PC_3        PC_4       PC_5
#> [1,] 1.1834873 0.9619901  1.91993862 -0.36182802 -0.1372251
#> [2,] 2.4232980 2.3592677 -0.03695406  0.08252908 -0.9682650
#> [3,] 0.9391263 0.1874751 -0.48463639 -0.53023728 -0.7288897
```
