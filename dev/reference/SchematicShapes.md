# Schematic Shapes from a Specification

Builds the shape table drawn by
[`PlotImage()`](https://cttir.github.io/phenoscapR/dev/reference/PlotImage.md)
for a schematic: fixed shapes (rectangles, rounded boxes, ellipses,
circles, segments, arrows and text) and, optionally, clouds of dots
placed at random inside ellipses (`seed` makes them reproducible).

## Usage

``` r
SchematicShapes(
  shapes = list(),
  clouds = list(),
  flow = NULL,
  values = NULL,
  fill = list(),
  xlim = c(0, 1),
  ylim = c(0, 1),
  seed = 1,
  equal = TRUE
)
```

## Arguments

- shapes:

  List of shapes; each a list with `type` (`"rect"`, `"roundrect"`,
  `"ellipse"`, `"circle"`, `"segment"`, `"arrow"`, `"text"`), position
  fields (`x`, `y`, and `w`, `h`, `r`, `xend`, `yend`, `angle` as
  needed), `fill`, `colour`, `linewidth` (points), `label`, `size`
  (points), `hjust`, `vjust`, `z` (drawing order).

- clouds:

  List of dot clouds: `n`, `x`, `y` (ellipse centre), `rx`, `ry`
  (ellipse radii), `r` (dot radius), `fill`, optional `colour` and
  `linewidth` (outline), `z`.

- flow:

  Optional list describing a row of boxes joined by arrows: `labels`,
  `x0`, `width`, `gap`, `y`, `height`, `fill`, `colour`, `text_size`,
  `arrow_colour`.

- values:

  Optional data frame used to fill `{name}` placeholders in labels; see
  `fill`.

- fill:

  Named list: placeholder to a list with `column`, `fun` (`"sum"`,
  `"mean"`, `"median"`, `"n"`), `scale`, `format` (sprintf) and an
  optional `filter` (named list of column to values).

- xlim, ylim:

  Drawing limits.

- seed:

  Random seed for the clouds.

- equal:

  Keep equal x and y scales (centred in the panel box); with `FALSE` the
  limits fill the box.

## Value

A list of class `phenoscapR_shapes` with `shapes`, `xlim`, `ylim` and
`equal`. Rounded-box radii (`r` of `"roundrect"`) are millimetres.

## Examples

``` r
s <- SchematicShapes(
  shapes = list(list(type = "roundrect", x = 0.5, y = 0.6, w = 0.6, h = 0.3,
                     fill = "#EEEEEE", colour = "#999999", r = 1),
                list(type = "text", x = 0.5, y = 0.6, label = "{n} cells")),
  clouds = list(list(n = 20, x = 0.5, y = 0.2, rx = 0.3, ry = 0.1, r = 0.01, fill = "#7B2FBE")),
  values = data.frame(count = c(120, 80)),
  fill = list(n = list(column = "count", fun = "sum", format = "%.0f"))
)
head(s$shapes)
#>        type         x         y   w   h    r xend yend angle    fill  colour
#> 1 roundrect 0.5000000 0.6000000 0.6 0.3 1.00   NA   NA     0 #EEEEEE #999999
#> 2      text 0.5000000 0.6000000  NA  NA   NA   NA   NA     0    <NA>    <NA>
#> 3    circle 0.4717821 0.2962215  NA  NA 0.01   NA   NA     0 #7B2FBE    <NA>
#> 4    circle 0.4040758 0.2331518  NA  NA 0.01   NA   NA     0 #7B2FBE    <NA>
#> 5    circle 0.2827537 0.1643245  NA  NA 0.01   NA   NA     0 #7B2FBE    <NA>
#> 6    circle 0.5891060 0.1806780  NA  NA 0.01   NA   NA     0 #7B2FBE    <NA>
#>   linewidth     label size hjust vjust head lineheight z
#> 1       0.5      <NA>    5   0.5   0.5    6       1.15 1
#> 2       0.5 200 cells    5   0.5   0.5    6       1.15 1
#> 3       0.5      <NA>    5   0.5   0.5    6       1.15 1
#> 4       0.5      <NA>    5   0.5   0.5    6       1.15 1
#> 5       0.5      <NA>    5   0.5   0.5    6       1.15 1
#> 6       0.5      <NA>    5   0.5   0.5    6       1.15 1
```
