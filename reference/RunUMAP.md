# UMAP Embedding

Computes a 2-D UMAP embedding via the uwot package and stores it under
`"umap"`. By default the embedding is computed on the top principal
components (see `use_pca`).

## Usage

``` r
RunUMAP(
  object,
  dims = 30L,
  use_pca = TRUE,
  n_neighbors = 15L,
  densmap = FALSE,
  slot = "data",
  markers = NULL,
  seed = NULL,
  ...
)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- dims:

  Integer. Number of PCs (or markers) to embed. Default `30`.

- use_pca:

  Logical. Embed on PCA space (default `TRUE`) or directly on the marker
  matrix.

- n_neighbors:

  Integer. UMAP neighbourhood size. Default `15`.

- densmap:

  Logical. Use density-preserving densMAP instead of UMAP. Default
  `FALSE`. Requires a recent uwot.

- slot:

  Character. `"data"` (default) or `"counts"`.

- markers:

  Character vector or `NULL`.

- seed:

  Integer or `NULL`. Random seed for reproducibility.

- ...:

  Passed to
  [`uwot::umap()`](https://jlmelville.github.io/uwot/reference/umap.html)
  / `uwot::densmap()`.

## Value

The object with a `"umap"` entry in its `reductions` slot.

## Examples

``` r
# \donttest{
if (requireNamespace("uwot", quietly = TRUE)) {
  counts <- matrix(rnorm(500), nrow = 50,
                   dimnames = list(NULL, paste0("M", 1:10)))
  coords <- data.frame(x = runif(50), y = runif(50))
  obj <- CreateSpatialObject(counts, coords)
  obj <- RunUMAP(obj, seed = 1)
}
# }
```
