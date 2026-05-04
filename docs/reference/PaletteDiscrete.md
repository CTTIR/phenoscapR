# Generate Discrete Colours

Generates `n` evenly spaced colours from the current or specified
palette. Useful for colouring phenotypes, clusters, or samples.

## Usage

``` r
PaletteDiscrete(n, palette = NULL)
```

## Arguments

- n:

  Integer. Number of distinct colours needed.

- palette:

  Character or character vector. Palette specification (see
  [`SetPalette`](https://r-heller.github.io/phenoscapR/reference/SetPalette.md)).
  If `NULL`, uses the global palette.

## Value

A character vector of `n` hex colours.

## Examples

``` r
cols <- PaletteDiscrete(5)
barplot(rep(1, 5), col = cols)


cols <- PaletteDiscrete(8, palette = c("#1b9e77", "#ffffff", "#d95f02"))
barplot(rep(1, 8), col = cols)

```
