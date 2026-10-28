# Manuscript Figure Style

Returns the typography, colours, line widths and page settings of a
compact journal figure style: DejaVu Sans at 6 pt, 8 pt bold lower-case
panel letters, 6.4 pt bold panel headings, thin grey axes without top
and right lines, a 180 mm page width and 450 dpi raster output. Every
plot builder and
[`ComposeFigure()`](https://cttir.github.io/phenoscapR/dev/reference/ComposeFigure.md)
reads its settings from this object, so one change here restyles all
figures.

## Usage

``` r
ManuscriptStyle(...)
```

## Arguments

- ...:

  Named values replacing top-level entries or, for list entries,
  individual elements (for example `size = list(base = 7)`).

## Value

A list of class `phenoscapR_style` with elements `family`, `size`,
`colour`, `line`, `page` and `palettes`.

## Details

The family is used as named by devices that read system fonts
([`cairo_pdf()`](https://rdrr.io/r/grDevices/cairo.html), 'ragg', Cairo
PNG). For R's plain [`pdf()`](https://rdrr.io/r/grDevices/pdf.html) and
[`postscript()`](https://rdrr.io/r/grDevices/postscript.html) devices an
unknown family is registered with Helvetica metrics, so plots still draw
there (in Helvetica).

Sizes are in points, line widths in points (converted for 'ggplot2' with
[`PtLinewidth()`](https://cttir.github.io/phenoscapR/dev/reference/PtLinewidth.md))
and page dimensions in millimetres. Palettes hold generic names; map
study labels to them in study configuration, not in code.

## See also

[`ThemeManuscript()`](https://cttir.github.io/phenoscapR/dev/reference/ThemeManuscript.md),
[`ManuscriptPalettes()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptPalettes.md),
[`ComposeFigure()`](https://cttir.github.io/phenoscapR/dev/reference/ComposeFigure.md)

## Examples

``` r
style <- ManuscriptStyle()
style$size$letter
#> [1] 8
ManuscriptStyle(size = list(base = 7))$size$base
#> [1] 7
```
