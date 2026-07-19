# Get a Dimensionality-Reduction Embedding

Get a Dimensionality-Reduction Embedding

## Usage

``` r
Embeddings(object, reduction = "pca")

# S4 method for class 'SpatialCellData'
Embeddings(object, reduction = "pca")
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- reduction:

  Character. Name of the reduction (e.g. `"pca"`, `"umap"`).

## Value

A numeric matrix (cells x dimensions).

## Examples

``` r
data(phenoscapR_example)
Embeddings(RunPCA(phenoscapR_example, n_pcs = 5), "pca")[1:3, ]
#>             PC_1       PC_2       PC_3         PC_4      PC_5
#> [1,]  -0.1069744 -11.106001  0.1218824  -0.03604904 -5.134441
#> [2,]  21.9576292  12.324227  6.1825788 -15.84605883  3.208067
#> [3,] -11.9758869   5.021583 -0.3349569  -0.06596407 -4.431969
```
