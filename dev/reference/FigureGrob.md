# Place a Grob on a Figure Page

Place a Grob on a Figure Page

## Usage

``` r
FigureGrob(grob, at, hjust = 0, vjust = 1)
```

## Arguments

- grob:

  A 'grid' grob, for example a legend from
  [`LegendKeys()`](https://cttir.github.io/phenoscapR/dev/reference/LegendKeys.md).

- at:

  Numeric `c(left, top)` in millimetres.

- hjust, vjust:

  Justification relative to `at`.

## Value

A list of class `phenoscapR_grob`.

## Examples

``` r
key <- FigureGrob(grid::textGrob("Legend text", just = c(0, 1)), at = c(5, 5))
fig <- ComposeFigure(list(FigurePanel(NULL, c(5, 10, 40, 20), letter = "a")),
                     height_mm = 35, width_mm = 60, texts = list(key))
grid::grid.newpage(); print(fig)
```
