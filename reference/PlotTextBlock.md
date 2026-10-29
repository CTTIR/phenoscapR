# Text Block or Text Table

A panel of text placed in its figure box: lines written from templates
and data (statistic lines, headings that contain numbers, notes) or,
with `layout = "table"`, a small table of text cells as produced by
[`PlotDataTableCells()`](https://cttir.github.io/phenoscapR/reference/PlotDataTableCells.md).

## Usage

``` r
PlotTextBlock(
  data = NULL,
  template = NULL,
  text = NULL,
  size = NULL,
  colour = "muted",
  bold = FALSE,
  hjust = 0,
  vjust = 0,
  x = NULL,
  y = NULL,
  lineheight = 1.1,
  angle = 0,
  layout = c("lines", "table"),
  widths = NULL,
  header_fill = "#F3F3F3",
  highlight_fill = "#FFF2D6",
  border_colour = "#D9D9D9",
  border_linewidth = 0.4,
  key_colours = NULL,
  table_size = 5.5,
  first_pad = 0.02,
  borders = c("cells", "rules"),
  align = c("centre", "left"),
  style = ManuscriptStyle()
)
```

## Arguments

- data:

  Optional data frame.

- template:

  Optional templates.

- text:

  Optional fixed lines (placed before the template lines).

- size:

  Font size(s) in points; default the style's statistic size.

- colour:

  Colour(s); style names allowed.

- bold:

  Bold face per line.

- hjust, vjust:

  Justification of the block.

- x, y:

  Anchor in fractions of the box (default `hjust`, `vjust`).

- lineheight:

  Line height multiplier.

- angle:

  Rotation in degrees.

- layout:

  `"lines"` or `"table"`.

- widths:

  Relative column widths of a table (default: first column 0.23, others
  equal).

- header_fill, highlight_fill, border_colour:

  Table colours.

- border_linewidth:

  Cell border width in points.

- key_colours:

  Named colours for header text by `key`.

- table_size:

  Table font size.

- first_pad:

  Left padding of first-column text (fraction of width).

- borders:

  `"cells"` (a frame around every cell, with fills) or `"rules"` (only
  horizontal rules between rows, no fills).

- align:

  Alignment of the columns after the first: `"centre"` or `"left"` (at
  `first_pad` from the column edge).

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/reference/ManuscriptStyle.md)
  object.

## Value

A 'grid' grob.

## Details

Lines: `text` gives fixed lines; `template` is filled from `data` with
[`FormatTemplate()`](https://cttir.github.io/phenoscapR/reference/FormatTemplate.md)
(one template per data row, or one template for every row). `size`,
`colour` and `bold` may be given per line. The block is anchored at `x`,
`y` (fractions of the box) with `hjust`, `vjust`.

Table: cells with `row`, `column`, `label`, `header`, `highlight` and
`key` columns; the first column is left aligned, the others centred;
header cells are bold on `header_fill` and coloured by `key` through
`key_colours`; highlighted cells use `highlight_fill`.

## Examples

``` r
g <- PlotTextBlock(data.frame(k = 11, n = 12, p = 0.0015),
                   template = "{k|d}/{n|d} patients; p = {p|p}")
grid::grid.newpage(); grid::grid.draw(g)
```
