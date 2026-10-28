# Paired Patient Lines

One line per patient across ordered conditions, coloured by clinical
group, with a short bold bar at the median of each condition. Patients
flagged in `excluded` are drawn dashed with open symbols and are left
out of the medians, as patients not included in a test.

## Usage

``` r
PlotPairedPatients(
  data,
  patient = "patient",
  group = "group",
  condition = "condition",
  value = "value",
  conditions = NULL,
  labels = NULL,
  excluded = NULL,
  group_colours = NULL,
  log_y = FALSE,
  y_label = NULL,
  x_label = NULL,
  y_limits = NULL,
  y_nbins = "auto",
  box_mm = NULL,
  style = ManuscriptStyle()
)
```

## Arguments

- data:

  Tidy data: one row per patient and condition.

- patient, group, condition, value:

  Column names.

- conditions:

  Condition order; defaults to first appearance.

- labels:

  Tick labels for the conditions; default `conditions`.

- excluded:

  Optional logical column marking patients outside the test.

- group_colours:

  Named colours per group level.

- log_y:

  Logarithmic y axis.

- y_label, x_label:

  Axis titles.

- y_limits:

  Optional y limits.

- y_nbins:

  Maximum number of y intervals of the tick locator (see
  [`NiceBreaks()`](https://cttir.github.io/phenoscapR/dev/reference/NiceBreaks.md));
  `"auto"` follows the axis length.

- box_mm:

  Size of the data area `c(width, height)` in millimetres, passed by
  [`RenderFigure()`](https://cttir.github.io/phenoscapR/dev/reference/RenderFigure.md).

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptStyle.md)
  object.

## Value

A 'ggplot2' object.

## Examples

``` r
d <- data.frame(patient = rep(c("p1", "p2", "p3"), each = 2),
                group = rep(c("A", "B", "A"), each = 2),
                condition = rep(c("x", "y"), 3), value = c(3, 5, 2, 6, 4, 4.5))
PlotPairedPatients(d, group_colours = c(A = "#009E73", B = "#0072B2"))
```
