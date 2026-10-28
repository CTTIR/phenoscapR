# Distance to the Nearest Cell of Given Labels

Adds the Euclidean distance from every cell to the nearest cell whose
label is in `labels` (exact nearest-neighbour search). Cells carrying
one of these labels get `self` (0 by default) instead of the distance to
another such cell.

## Usage

``` r
NearestLabelDistance(
  cells,
  labels,
  column = "distance",
  x = "x",
  y = "y",
  label = "label",
  self = 0
)
```

## Arguments

- cells:

  Data frame of cells.

- labels:

  Labels of the target cells.

- column:

  Name of the new column.

- x, y, label:

  Column names.

- self:

  Value for target cells; `NULL` keeps the distance to the nearest other
  target cell.

## Value

`cells` with the new column.

## Examples

``` r
d <- data.frame(x = c(0, 3, 10), y = 0, label = c("t", "a", "a"))
NearestLabelDistance(d, "t", column = "dist")
#>    x y label dist
#> 1  0 0     t    0
#> 2  3 0     a    3
#> 3 10 0     a   10
```
