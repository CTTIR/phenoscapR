# SONG Embedding

Computes a 2-D SONG (Self-Organising Nebulous Growths) embedding via the
songR package and stores it under `"song"`. SONG is incremental,
noise-robust, and preserves global structure. By default the embedding
is computed on the top principal components (see `use_pca`).

## Usage

``` r
RunSONG(
  object,
  dims = 30L,
  use_pca = TRUE,
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

- slot:

  Character. `"data"` (default) or `"counts"`.

- markers:

  Character vector or `NULL`.

- seed:

  Integer or `NULL`. Random seed for reproducibility.

- ...:

  Passed to `songR::song()`.

## Value

The object with a `"song"` entry in its `reductions` slot.

## Details

songR is available from the CTTIR R-universe:
`install.packages("songR", repos = "https://cttir.r-universe.dev")`.

## Examples

``` r
# \donttest{
if (requireNamespace("songR", quietly = TRUE)) {
  counts <- matrix(rnorm(500), nrow = 50,
                   dimnames = list(NULL, paste0("M", 1:10)))
  coords <- data.frame(x = runif(50), y = runif(50))
  obj <- CreateSpatialObject(counts, coords)
  obj <- RunSONG(obj, seed = 1)
}
# }
```
