# Tick Breaks of Common Plotting Code

Tick positions as placed by the automatic tick locator of common
plotting libraries (a "maximum number of intervals" locator): the
smallest "nice" step from `steps` (times a power of ten) that divides
the axis range into at most `nbins` intervals, with ticks restricted to
the limits. For example limits 0 to 7 give 0, 2, 4, 6 rather than 0, 3,
6.

## Usage

``` r
NiceBreaks(
  limits,
  nbins = 9,
  steps = c(1, 2, 2.5, 5, 10),
  min_n = 2,
  length_pt = NULL,
  tick_size = 5.5,
  axis = c("y", "x")
)
```

## Arguments

- limits:

  Axis limits (as drawn, including any margins).

- nbins:

  Maximum number of intervals, or `"auto"`.

- steps:

  Nice step multipliers between 1 and 10.

- min_n:

  Minimum number of ticks inside the limits.

- length_pt:

  Axis length in points (for `nbins = "auto"`).

- tick_size:

  Tick label size in points (for `nbins = "auto"`).

- axis:

  `"y"` or `"x"` (for `nbins = "auto"`).

## Value

Numeric vector of tick positions.

## Details

With `nbins = "auto"` the number of intervals follows the axis length as
in those libraries: the axis length divided by twice (y axis) or three
times (x axis) the tick label size, between 1 and 9.

## Examples

``` r
NiceBreaks(c(0, 7))
#> [1] 0 1 2 3 4 5 6 7
NiceBreaks(c(-3.9, 82), nbins = "auto", length_pt = 51, tick_size = 5.5)
#> [1]  0 25 50 75
```
