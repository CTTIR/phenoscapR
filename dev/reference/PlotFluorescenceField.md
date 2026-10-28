# Multichannel Fluorescence Field

Composes an additive multichannel image from channel windows (a field as
returned by `segmantR::sg_read_field()`), display levels and channel
colours and weights (see
[`CompositeFields()`](https://cttir.github.io/phenoscapR/dev/reference/CompositeFields.md)
for the layer and level rules), and draws it at its physical extent with
optional scale bar, corner text, arrows pointing at cells, crosses on
partner cells and boxes.

## Usage

``` r
PlotFluorescenceField(
  field,
  layers,
  slide = NULL,
  levels = NULL,
  marks = NULL,
  index = NULL,
  marks_index = NULL,
  gamma = 0.8,
  min_span = 1,
  interpolate = TRUE,
  arrow = NULL,
  cross = NULL,
  corner_text = NULL,
  corner_size = 5,
  corner_colour = "white",
  corner_at = c(0.04, 0.96),
  label = NULL,
  label_size = 5.5,
  scale_bar = list(length = 50, label = "50 um", colour = "white"),
  boxes = NULL,
  box_colour = "white",
  box_width = 0.6,
  box_size = NULL,
  frame = FALSE,
  style = ManuscriptStyle()
)
```

## Arguments

- field:

  A field (`channels`, `centre`, `size`) or a list of fields with
  `index` selecting one.

- layers:

  List of channel layers (see
  [`CompositeFields()`](https://cttir.github.io/phenoscapR/dev/reference/CompositeFields.md)).

- slide, levels:

  Optional range tables (`channel`, `lo`, `hi`).

- marks:

  Optional data frame of cells to annotate (`x`, `y`, and for crosses
  `partner_x`, `partner_y`); `marks_index` selects rows.

- index, marks_index:

  Optional selections.

- gamma, min_span:

  Display gamma and minimum level span.

- interpolate:

  Smooth the raster when scaling (bilinear).

- arrow:

  `NULL` or a list: `tip`, `tail` (offsets from the cell along both
  axes, physical units), `colour`, `linewidth` (points), `head`
  (arrow-head scale in points) and `shrink` (points left free at both
  ends).

- cross:

  `NULL` or a list: `colour`, `size` (marker area in square points),
  `linewidth`; drawn at the partner positions.

- corner_text:

  `NULL`, a fixed text, or a list with `column` and `format` (sprintf)
  taking the value from the first mark.

- corner_size, corner_colour:

  Corner text size and colour.

- corner_at:

  Corner text position (fractions of the field, top-left anchored).

- label:

  Optional field label in the top-left corner (as `corner_text`,
  larger).

- label_size:

  Label size.

- scale_bar, boxes, box_colour, box_width, box_size, frame:

  As in
  [`PlotCellMap()`](https://cttir.github.io/phenoscapR/dev/reference/PlotCellMap.md).

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptStyle.md)
  object.

## Value

A 'grid' grob.
