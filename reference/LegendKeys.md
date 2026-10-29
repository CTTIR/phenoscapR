# Legend Keys as a Grob

Draws a compact legend without a frame, in one row or several columns,
for placement with
[`FigureGrob()`](https://cttir.github.io/phenoscapR/reference/FigureGrob.md).
Text is measured when the legend is drawn. Keys are points, open
circles, crosses, squares, diamonds, patches (filled rectangles of the
key width), lines or point-and-line keys.

## Usage

``` r
LegendKeys(
  labels,
  colours,
  shape = "point",
  ncol = length(labels),
  size = NULL,
  key_mm = 2.2,
  marker_size = NULL,
  row_mm = NULL,
  text_gap_mm = 0.8,
  column_gap_mm = 0.8,
  byrow = TRUE,
  linewidth = NULL,
  typeset = TRUE,
  style = ManuscriptStyle()
)
```

## Arguments

- labels:

  Character labels, typeset with
  [`TypesetLabel()`](https://cttir.github.io/phenoscapR/reference/TypesetLabel.md).

- colours:

  Key colours, recycled.

- shape:

  One of `"point"`, `"open"` (open circle), `"cross"`, `"square"`,
  `"diamond"`, `"patch"`, `"line"` or `"pointline"`, recycled per key.

- ncol:

  Number of columns; default is one row.

- size:

  Text size in points; default is the style's legend size.

- key_mm:

  Key width in millimetres.

- marker_size:

  Optional marker diameter (square and diamond side) in points; by
  default it follows the text size.

- row_mm:

  Optional row pitch in millimetres (default 1.35 times the text size).

- text_gap_mm:

  Gap between key and label (mm).

- column_gap_mm:

  Gap after the widest label of a column (mm).

- byrow:

  Fill rows first (`TRUE`) or columns first (`FALSE`).

- linewidth:

  Optional line width (points) of line keys.

- typeset:

  If `FALSE`, labels are drawn as written.

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/reference/ManuscriptStyle.md)
  object.

## Value

A 'grid' grob.

## Details

The layout defaults suit short legends; legends of common plotting code
are reproduced with a marker diameter (`marker_size`), the row pitch
(`row_mm`), the gaps around the label and column-major filling
(`byrow = FALSE`, earlier columns take the extra rows).

## Examples

``` r
grid::grid.draw(LegendKeys(c("Untreated", "Responder"), c("#009E73", "#0072B2")))

grid::grid.newpage()
grid::grid.draw(LegendKeys(c("a", "b", "c"), "#7B2FBE", shape = c("point", "diamond", "patch"),
                           ncol = 2, byrow = FALSE, marker_size = 4))
```
