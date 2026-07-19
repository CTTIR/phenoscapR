# t-SNE Embedding

Computes a 2-D t-SNE embedding via the Rtsne package and stores it under
`"tsne"`. By default the embedding is computed on the top principal
components (see `use_pca`).

## Usage

``` r
RunTSNE(
  object,
  dims = 30L,
  use_pca = TRUE,
  perplexity = 30,
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

- perplexity:

  Numeric. t-SNE perplexity. Automatically capped at `(n - 1) / 3`.
  Default `30`.

- slot:

  Character. `"data"` (default) or `"counts"`.

- markers:

  Character vector or `NULL`.

- seed:

  Integer or `NULL`. Random seed for reproducibility.

- ...:

  Passed to
  [`Rtsne::Rtsne()`](https://rdrr.io/pkg/Rtsne/man/Rtsne.html).

## Value

The object with a `"tsne"` entry in its `reductions` slot.

## Examples

``` r
# \donttest{
if (requireNamespace("Rtsne", quietly = TRUE)) {
  counts <- matrix(rnorm(500), nrow = 50,
                   dimnames = list(NULL, paste0("M", 1:10)))
  coords <- data.frame(x = runif(50), y = runif(50))
  obj <- CreateSpatialObject(counts, coords)
  obj <- RunTSNE(obj, seed = 1)
}
# }
```
