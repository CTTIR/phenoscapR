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
#>            PC_1      PC_2       PC_3        PC_4       PC_5
#> [1,]  0.4658463 0.7265218 -0.3898209  0.01082705  1.7196712
#> [2,] -2.2076999 0.1298319  1.5234266 -0.59315080  0.5258849
#> [3,] -0.4715254 1.1038190  1.4924632  0.43173440 -0.7453641
```
