# Manuscript 'ggplot2' Theme

A compact theme for multi-panel figures: no panel title (headings are
placed by
[`ComposeFigure()`](https://cttir.github.io/phenoscapR/dev/reference/ComposeFigure.md)),
thin grey left and bottom axis lines, short ticks, light horizontal grid
lines when `grid = "y"`, no legend background and zero outer margins.
When the optional packages 'ggtext' and 'gridtext' are installed, axis
titles and tick labels accept the rich text produced by
[`TypesetLabel()`](https://cttir.github.io/phenoscapR/dev/reference/TypesetLabel.md).

## Usage

``` r
ThemeManuscript(
  style = ManuscriptStyle(),
  grid = c("y", "x", "both", "none"),
  axes = c("xy", "x", "y", "none")
)
```

## Arguments

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptStyle.md)
  object.

- grid:

  One of `"y"`, `"x"`, `"both"` or `"none"`.

- axes:

  One of `"xy"` (left and bottom lines), `"x"`, `"y"` or `"none"`.

## Value

A 'ggplot2' theme.

## Examples

``` r
library(ggplot2)
ggplot(data.frame(x = 1:3, y = c(2, 4, 3)), aes(x, y)) +
  geom_point() +
  ThemeManuscript()
```
