# Compose a Multi-Panel Figure

Lays out panels, page-level texts and legend keys on a page of fixed
size in millimetres, with bold panel letters and headings in the
manuscript style. The result can be drawn on any device or written with
[`SaveFigure()`](https://cttir.github.io/phenoscapR/dev/reference/SaveFigure.md).

## Usage

``` r
ComposeFigure(
  panels,
  height_mm,
  width_mm = NULL,
  texts = list(),
  style = ManuscriptStyle()
)
```

## Arguments

- panels:

  List of
  [`FigurePanel()`](https://cttir.github.io/phenoscapR/dev/reference/FigurePanel.md)
  objects.

- height_mm:

  Page height in millimetres.

- width_mm:

  Page width; defaults to the style's page width.

- texts:

  Optional list of
  [`FigureText()`](https://cttir.github.io/phenoscapR/dev/reference/FigureText.md)
  objects and grobs placed with
  [`FigureGrob()`](https://cttir.github.io/phenoscapR/dev/reference/FigureGrob.md).

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptStyle.md)
  object.

## Value

An object of class `phenoscapR_figure`;
[`print()`](https://rdrr.io/r/base/print.html) draws it on the current
device.

## Examples

``` r
library(ggplot2)
p <- ggplot(data.frame(x = 1:3, y = 1:3), aes(x, y)) + geom_point() +
  ThemeManuscript()
fig <- ComposeFigure(list(FigurePanel(p, c(12, 10, 50, 30), letter = "a",
                                      heading = "Example")), height_mm = 50)
```
