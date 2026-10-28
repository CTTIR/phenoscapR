# Save a Composed Figure as PDF and PNG

Writes the page at its exact size: PDF through the Cairo device with
embedded TrueType fonts, PNG through 'ragg' at the style's resolution
(falling back to the 'png' Cairo device when 'ragg' is absent).

## Usage

``` r
SaveFigure(figure, pdf = NULL, png = NULL, dpi = NULL)
```

## Arguments

- figure:

  A
  [`ComposeFigure()`](https://cttir.github.io/phenoscapR/dev/reference/ComposeFigure.md)
  result.

- pdf:

  Output PDF path, or `NULL`.

- png:

  Output PNG path, or `NULL`.

- dpi:

  Raster resolution; defaults to the style's.

## Value

The output paths, invisibly.
