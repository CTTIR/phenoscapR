# Plot a Dimensionality-Reduction Embedding

Scatter plot of cells in an embedding (PCA, UMAP, t-SNE, or SONG),
coloured by a metadata column. Analogous to Seurat's `DimPlot`.

## Usage

``` r
EmbeddingPlot(
  object,
  reduction = "umap",
  colour_by = "phenotype",
  colours = NULL,
  pt_size = 1,
  title = NULL,
  dark_theme = FALSE
)

DimPlot(
  object,
  reduction = "umap",
  colour_by = "phenotype",
  colours = NULL,
  pt_size = 1,
  title = NULL,
  dark_theme = FALSE
)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- reduction:

  Character. Reduction to plot. Default `"umap"`.

- colour_by:

  Character. Metadata column for colour. Default `"phenotype"`.

- colours:

  Named character vector or `NULL`.

- pt_size:

  Numeric. Point size. Default `1`.

- title:

  Character or `NULL`.

- dark_theme:

  Logical. Dark background. Default `FALSE`.

## Value

A `ggplot` object.

## Examples

``` r
counts <- matrix(rnorm(500), nrow = 50,
                 dimnames = list(NULL, paste0("M", 1:10)))
coords <- data.frame(x = runif(50), y = runif(50))
obj <- CreateSpatialObject(counts, coords)
obj <- RunPCA(obj, n_pcs = 5)
obj <- PhenotypeCells(obj, thresholds = list(M1 = 0))
EmbeddingPlot(obj, reduction = "pca")

```
