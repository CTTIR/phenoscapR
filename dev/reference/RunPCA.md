# Principal Component Analysis

Computes a PCA embedding of the marker-expression matrix and stores it
in the `reductions` slot under the name `"pca"`. PCA uses only base R
and is always available; it is also the default input space for
[`RunUMAP`](https://cttir.github.io/phenoscapR/dev/reference/RunUMAP.md),
[`RunTSNE`](https://cttir.github.io/phenoscapR/dev/reference/RunTSNE.md),
and
[`RunSONG`](https://cttir.github.io/phenoscapR/dev/reference/RunSONG.md).

## Usage

``` r
RunPCA(object, n_pcs = 30L, slot = "data", markers = NULL)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/dev/reference/SpatialCellData-class.md)
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
#>            PC_1       PC_2       PC_3       PC_4       PC_5
#> [1,] -1.1539268 -1.2203557  0.4983374 -0.5073602 -0.2345001
#> [2,]  1.5521673  0.2219916 -2.8967164 -0.6902106  0.4927744
#> [3,]  0.1409613 -0.5429483 -0.1782084 -1.1172067  1.8737288
```
