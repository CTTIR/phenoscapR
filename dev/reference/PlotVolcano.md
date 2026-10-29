# Volcano Plot of Exact Group Tests

Effect size against minus log10 of the exact P value for one family of
tests: open grey symbols for P at or above `alpha`, filled symbols below
it, labels for the `top` smallest nominal P values, a grey line at P =
`alpha` and a dashed line at the lower bound of the exact P value (from
`stats`, see
[`PlotDataContrastSummary()`](https://cttir.github.io/phenoscapR/dev/reference/PlotDataContrastSummary.md)).

## Usage

``` r
PlotVolcano(
  data,
  stats = NULL,
  effect = "cliffs_delta",
  p = "p",
  label = NULL,
  alpha = 0.05,
  top = 3,
  bound = "p_bound",
  bound_label = "Minimum attainable p = {p_bound|p}",
  bound_colour = "minimum_p",
  open_size = 8,
  open_edge = 0.6,
  open_colour = "open_edge",
  filled_size = 11,
  filled_colour = "ink",
  label_size = 4.3,
  bound_label_size = 4.4,
  x_limits = c(-1.08, 1.08),
  y_limits = c(0, 3.2),
  x_nbins = 6,
  y_nbins = 9,
  x_label = NULL,
  y_label = NULL,
  show_y_label = TRUE,
  box_mm = NULL,
  style = ManuscriptStyle()
)
```

## Arguments

- data:

  Test table, one row per endpoint.

- stats:

  Optional one-row table with the bound column.

- effect, p:

  Columns of the effect size and the P value.

- label:

  Optional column with display labels of the endpoints.

- alpha:

  Nominal threshold.

- top:

  Number of labelled endpoints.

- bound:

  Column of `stats` with the lower bound of P.

- bound_label:

  Template written at the bound line.

- bound_colour:

  Colour of the bound line and text.

- open_size, open_edge, open_colour:

  Open symbols (area, edge, colour).

- filled_size, filled_colour:

  Filled symbols (area; drawn with a 1 pt edge of the same colour as in
  common figure code).

- label_size, bound_label_size:

  Text sizes.

- x_limits, y_limits:

  Axis limits.

- x_nbins, y_nbins:

  Tick intervals.

- x_label:

  Axis title; by default "Cliff's \\\delta\\" (drawn with the Greek
  letter). An explicit `NULL` draws no title.

- y_label:

  Axis title; `NULL` gives a typeset "-log10 exact P".

- show_y_label:

  Draw the y axis title.

- box_mm:

  Size of the data area `c(width, height)` in millimetres, passed by
  [`RenderFigure()`](https://cttir.github.io/phenoscapR/dev/reference/RenderFigure.md);
  used by `"auto"` tick intervals (see
  [`NiceBreaks()`](https://cttir.github.io/phenoscapR/dev/reference/NiceBreaks.md)).

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptStyle.md)
  object.

## Value

A 'ggplot2' object.

## Examples

``` r
t <- data.frame(d = c(-0.9, 0.2, 0.7, -0.1), p = c(0.02, 0.6, 0.04, 0.9),
                name = c("e1", "e2", "e3", "e4"))
p <- PlotVolcano(t, stats = data.frame(p_bound = 0.0048), effect = "d", label = "name")
```
