# Field Centre as Plot Data

Resolves a field centre as in
[`CellMapData()`](https://cttir.github.io/phenoscapR/dev/reference/CellMapData.md)
(given point, cell, grid snapping, offset) and returns it as a one-row
data frame, the form taken by image readers, maps and boxes.

## Usage

``` r
FieldCentre(
  cells,
  centre = NULL,
  centre_cell = NULL,
  id = "row",
  grid = NULL,
  offset = NULL,
  size = NULL,
  x = "x",
  y = "y"
)
```

## Arguments

- cells:

  Data frame of cells (positions, label and further columns).

- centre:

  Optional `c(x, y)` or a data frame with columns `x`, `y`.

- centre_cell:

  Optional cell identifier giving the centre.

- id:

  Column holding cell identifiers for `centre_cell`.

- grid:

  Optional list with `step` and `offset`: the centre is moved to the
  nearest `min(coordinate) + offset + k * step`.

- offset:

  Optional shift `c(dx, dy)` added to the centre.

- size:

  Optional field width stored in a `size` column.

- x, y:

  Coordinate columns of `cells`.

## Value

A data frame with `x`, `y` and, when given, `size`.

## Examples

``` r
d <- data.frame(row = 0:2, x = c(1, 5, 9), y = c(2, 6, 10), label = "a")
FieldCentre(d, centre_cell = 1, offset = c(10, 0), size = 20)
#>    x y size
#> 1 15 6   20
```
