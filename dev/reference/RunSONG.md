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

  Integer or `NULL`. Random seed for reproducibility.

- ...:

  Passed to
  [`songR::song()`](https://cttir.github.io/songR/reference/song.html).

## Value

The object with a `"song"` entry in its `reductions` slot.

## Details

The optional songR package is available from
<https://github.com/CTTIR/songR>. After installing remotes, use
`remotes::install_github("CTTIR/songR")`. This function reports a
missing dependency without installing software or changing the input
object.

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
#> Epoch 1/50 | CVs: 3 | QE: 3.5719 | so_lr: 1.0000 | lr: 1.0000
#> Epoch 2/50 | CVs: 5 | QE: 3.3475 | so_lr: 0.9980 | lr: 0.9800
#> Epoch 3/50 | CVs: 10 | QE: 3.1504 | so_lr: 0.9920 | lr: 0.9600
#> Epoch 4/50 | CVs: 13 | QE: 3.0667 | so_lr: 0.9822 | lr: 0.9400
#> Epoch 5/50 | CVs: 13 | QE: 3.0495 | so_lr: 0.9685 | lr: 0.9200
#> Epoch 6/50 | CVs: 13 | QE: 3.1723 | so_lr: 0.9512 | lr: 0.9000
#> Epoch 7/50 | CVs: 13 | QE: 3.0793 | so_lr: 0.9305 | lr: 0.8800
#> Epoch 8/50 | CVs: 13 | QE: 3.0320 | so_lr: 0.9066 | lr: 0.8600
#> Epoch 9/50 | CVs: 13 | QE: 2.9826 | so_lr: 0.8799 | lr: 0.8400
#> Epoch 10/50 | CVs: 13 | QE: 3.0420 | so_lr: 0.8504 | lr: 0.8200
#> Epoch 11/50 | CVs: 13 | QE: 3.0072 | so_lr: 0.8187 | lr: 0.8000
#> Epoch 12/50 | CVs: 13 | QE: 3.1007 | so_lr: 0.7851 | lr: 0.7800
#> Epoch 13/50 | CVs: 13 | QE: 2.9710 | so_lr: 0.7498 | lr: 0.7600
#> Epoch 14/50 | CVs: 13 | QE: 2.9411 | so_lr: 0.7132 | lr: 0.7400
#> Epoch 15/50 | CVs: 13 | QE: 3.0285 | so_lr: 0.6757 | lr: 0.7200
#> Epoch 16/50 | CVs: 13 | QE: 3.0239 | so_lr: 0.6376 | lr: 0.7000
#> Epoch 17/50 | CVs: 13 | QE: 3.0376 | so_lr: 0.5993 | lr: 0.6800
#> Epoch 18/50 | CVs: 13 | QE: 2.9813 | so_lr: 0.5610 | lr: 0.6600
#> Epoch 19/50 | CVs: 13 | QE: 2.9446 | so_lr: 0.5231 | lr: 0.6400
#> Epoch 20/50 | CVs: 13 | QE: 2.9891 | so_lr: 0.4858 | lr: 0.6200
#> Epoch 21/50 | CVs: 13 | QE: 2.9250 | so_lr: 0.4493 | lr: 0.6000
#> Epoch 22/50 | CVs: 13 | QE: 2.8853 | so_lr: 0.4140 | lr: 0.5800
#> Epoch 23/50 | CVs: 13 | QE: 2.8472 | so_lr: 0.3798 | lr: 0.5600
#> Epoch 24/50 | CVs: 13 | QE: 2.8136 | so_lr: 0.3471 | lr: 0.5400
#> Epoch 25/50 | CVs: 13 | QE: 2.7363 | so_lr: 0.3160 | lr: 0.5200
#> Epoch 26/50 | CVs: 13 | QE: 2.7147 | so_lr: 0.2865 | lr: 0.5000
#> Epoch 27/50 | CVs: 13 | QE: 2.7125 | so_lr: 0.2587 | lr: 0.4800
#> Epoch 28/50 | CVs: 13 | QE: 2.6968 | so_lr: 0.2327 | lr: 0.4600
#> Epoch 29/50 | CVs: 13 | QE: 2.6601 | so_lr: 0.2085 | lr: 0.4400
#> Epoch 30/50 | CVs: 13 | QE: 2.6337 | so_lr: 0.1860 | lr: 0.4200
#> Epoch 31/50 | CVs: 13 | QE: 2.5951 | so_lr: 0.1653 | lr: 0.4000
#> Epoch 32/50 | CVs: 13 | QE: 2.5969 | so_lr: 0.1463 | lr: 0.3800
#> Epoch 33/50 | CVs: 13 | QE: 2.5576 | so_lr: 0.1290 | lr: 0.3600
#> Epoch 34/50 | CVs: 13 | QE: 2.5421 | so_lr: 0.1133 | lr: 0.3400
#> Epoch 35/50 | CVs: 13 | QE: 2.5245 | so_lr: 0.0991 | lr: 0.3200
#> Epoch 36/50 | CVs: 13 | QE: 2.5285 | so_lr: 0.0863 | lr: 0.3000
#> Epoch 37/50 | CVs: 13 | QE: 2.5191 | so_lr: 0.0749 | lr: 0.2800
#> Epoch 38/50 | CVs: 13 | QE: 2.5096 | so_lr: 0.0647 | lr: 0.2600
#> Epoch 39/50 | CVs: 13 | QE: 2.4930 | so_lr: 0.0557 | lr: 0.2400
#> Epoch 40/50 | CVs: 13 | QE: 2.4878 | so_lr: 0.0477 | lr: 0.2200
#> Epoch 41/50 | CVs: 13 | QE: 2.4743 | so_lr: 0.0408 | lr: 0.2000
#> Epoch 42/50 | CVs: 13 | QE: 2.4730 | so_lr: 0.0347 | lr: 0.1800
#> Epoch 43/50 | CVs: 13 | QE: 2.4631 | so_lr: 0.0294 | lr: 0.1600
#> Epoch 44/50 | CVs: 13 | QE: 2.4585 | so_lr: 0.0248 | lr: 0.1400
#> Epoch 45/50 | CVs: 13 | QE: 2.4560 | so_lr: 0.0208 | lr: 0.1200
#> Epoch 46/50 | CVs: 13 | QE: 2.4525 | so_lr: 0.0174 | lr: 0.1000
#> Epoch 47/50 | CVs: 13 | QE: 2.4505 | so_lr: 0.0145 | lr: 0.0800
#> Epoch 48/50 | CVs: 13 | QE: 2.4477 | so_lr: 0.0121 | lr: 0.0600
#> Epoch 49/50 | CVs: 13 | QE: 2.4449 | so_lr: 0.0100 | lr: 0.0400
#> Epoch 50/50 | CVs: 13 | QE: 2.4434 | so_lr: 0.0082 | lr: 0.0200
#> Running UMAP dispersion step...
# }
```
