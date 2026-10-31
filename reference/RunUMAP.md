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
  n_threads = 1L,
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

  Logical. Preserve local densities with the approximation of densMAP in
  uwot (`dens_scale = 1` in
  [`uwot::umap()`](https://jlmelville.github.io/uwot/reference/umap.html))
  instead of plain UMAP. Default `FALSE`. For partial density
  preservation, pass `dens_scale` through `...` instead.

- slot:

  Character. `"data"` (default) or `"counts"`.

- markers:

  Character vector or `NULL`.

- seed:

  Integer or `NULL`. Random seed for reproducibility. The random number
  stream of the caller is restored afterwards.

- n_threads:

  Integer. Number of worker threads for UMAP neighbour search. Defaults
  to `1`; increase explicitly for larger analyses.

- ...:

  Passed to
  [`uwot::umap()`](https://jlmelville.github.io/uwot/reference/umap.html).

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
