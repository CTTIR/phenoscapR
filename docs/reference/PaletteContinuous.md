# Generate a Continuous Colour Palette Function

Returns a function that maps numeric values to colours based on the
current or specified palette. Works with `ggplot2` via
`scale_colour_gradientn` / `scale_fill_gradientn`.

## Usage

``` r
PaletteContinuous(n = 256L, palette = NULL)
```

## Arguments

- n:

  Integer. Number of colours to generate. Default `256`.

- palette:

  Character or character vector. Palette specification (see
  [`SetPalette`](https://r-heller.github.io/phenoscapR/reference/SetPalette.md)).
  If `NULL`, uses the global palette.

## Value

A character vector of `n` hex colours.

## Examples

``` r
cols <- PaletteContinuous(10)
plot(1:10, col = cols, pch = 19, cex = 3)


cols <- PaletteContinuous(10, palette = c("blue", "white", "red"))
plot(1:10, col = cols, pch = 19, cex = 3)

```
