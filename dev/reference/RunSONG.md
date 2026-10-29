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
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/dev/reference/SpatialCellData-class.md)
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

  Integer or `NULL`. Random seed for reproducibility. The random number
  stream of the caller is restored afterwards.

- ...:

  Passed to
  [`songR::song()`](https://cttir.github.io/songR/reference/song.html).

## Value

The object with a `"song"` entry in its `reductions` slot.

## Details

The optional songR package (<https://github.com/CTTIR/songR>) is
available from the CTTIR R-universe; install it with
`install.packages("songR", repos = c("https://cttir.r-universe.dev", getOption("repos")))`.
This function reports a missing dependency without installing software
or changing the input object.

## Examples

``` r
if (FALSE) { # \dontrun{
if (requireNamespace("songR", quietly = TRUE)) {
  counts <- matrix(rnorm(500), nrow = 50,
                   dimnames = list(NULL, paste0("M", 1:10)))
  coords <- data.frame(x = runif(50), y = runif(50))
  obj <- CreateSpatialObject(counts, coords)
  obj <- RunSONG(obj, seed = 1, verbose = FALSE)
}
} # }
```
