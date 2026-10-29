# Sub-Window with the Most Cells of a Kind

Scans square sub-windows of width `sub` on a grid of spacing `step`
inside a field and returns the one holding the most cells that match
`filter` (first maximum in row-major grid order, x varying fastest).

## Usage

``` r
BestSubWindow(
  cells,
  centre,
  size,
  sub,
  filter = list(),
  ranges = list(),
  step = 10,
  x = "x",
  y = "y"
)
```

## Arguments

- cells:

  Data frame of cells.

- centre:

  Field centre, `c(x, y)` or a data frame with `x`, `y`.

- size:

  Field width.

- sub:

  Sub-window width.

- filter:

  Named list: column to values.

- ranges:

  Named list: column to `c(min, max)` (inclusive) for numeric
  conditions, combined with `filter`.

- step:

  Grid spacing.

- x, y:

  Column names.

## Value

One-row data frame with `x`, `y`, `n`, `dx`, `dy` (offset from the field
centre).

## Examples

``` r
set.seed(1)
d <- data.frame(x = c(runif(40, 0, 100), runif(20, 60, 80)),
                y = c(runif(40, 0, 100), runif(20, 20, 40)),
                label = rep(c("a", "b"), c(40, 20)))
BestSubWindow(d, centre = c(50, 50), size = 100, sub = 20, filter = list(label = "b"))
#>    x  y  n dx  dy
#> 1 70 30 20 20 -20
```
