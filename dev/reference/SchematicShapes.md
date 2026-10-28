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
