# Normalise Marker Intensities (SpatialCellData)

Normalises marker intensities and stores the result in the `data` slot.
Raw counts remain unchanged.

## Usage

``` r
NormaliseData(
  object,
  method = c("zscore", "minmax", "quantile"),
  markers = NULL
)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- method:

  Character. `"zscore"` (default), `"minmax"`, or `"quantile"`.

- markers:

  Character vector or `NULL`. Markers to normalise. If `NULL`, all
  markers are normalised.

## Value

An
[`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
with updated `data` slot.

## Examples

``` r
counts <- matrix(rnorm(40, 500, 100), nrow = 20,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(20), y = runif(20))
obj <- CreateSpatialObject(counts, coords)
obj <- NormaliseData(obj, method = "zscore")
```
