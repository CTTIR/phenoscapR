# Cells of One Type inside a Field, Ranked

Selects cells with given labels inside a square of half-width `half`
around a centre, ordered by a column (for example the distance to the
nearest tumour cell), and keeps the first `n`; used to place arrows on a
fluorescence field.

## Usage

``` r
FieldCellsRanked(
  cells,
  centre,
  half,
  labels,
  order_by = NULL,
  n = Inf,
  x = "x",
  y = "y",
  label = "label"
)
```

## Arguments

- cells:

  Data frame of cells.

- centre:

  `c(x, y)` or a data frame with `x`, `y`.

- half:

  Half-width of the square.

- labels:

  Labels of the cells to select.

- order_by:

  Optional column to sort by (ascending).

- n:

  Maximum number of cells.

- x, y, label:

  Column names.

## Value

The selected rows of `cells`.

## Examples

``` r
d <- data.frame(x = c(1, 2, 3, 9), y = c(1, 1, 2, 9), label = c("a", "a", "b", "a"),
                dist = c(4, 2, 1, 3))
FieldCellsRanked(d, centre = c(2, 2), half = 3, labels = "a", order_by = "dist")
#>   x y label dist
#> 1 2 1     a    2
#> 2 1 1     a    4
```
