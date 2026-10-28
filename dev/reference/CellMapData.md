# Cells of a Map Field or Whole Section

Prepares the input of
[`PlotCellMap()`](https://cttir.github.io/phenoscapR/dev/reference/PlotCellMap.md):
the cells inside a square field (or all cells for a whole-section map),
the field geometry and, when requested, the interface zone, i.e. the
points of a regular grid that lie within `radius` of a reference cell
type (for example the tumour-stroma interface within 20 micrometres of a
tumour cell).

## Usage

``` r
CellMapData(
  cells,
  centre = NULL,
  size = NULL,
  centre_cell = NULL,
  id = "row",
  grid = NULL,
  offset = NULL,
  interface = NULL,
  classes = NULL,
  margin = 0,
  x = "x",
  y = "y",
  label = "label"
)
```

## Arguments

- cells:

  Data frame of cells (positions, label and further columns).

- centre:

  Optional `c(x, y)` or a data frame with columns `x`, `y`.

- size:

  Optional field width; `NULL` for a whole-section map.

- centre_cell:

  Optional cell identifier giving the centre.

- id:

  Column holding cell identifiers for `centre_cell`.

- grid:

  Optional list with `step` and `offset`: the centre is moved to the
  nearest `min(coordinate) + offset + k * step`.

- offset:

  Optional shift `c(dx, dy)` added to the centre.

- interface:

  Optional list with `labels` (reference cell labels), `radius` and
  `step` (grid spacing).

- classes:

  Optional list with `column`, `map` (named list of value to class) and
  `to` (new column name; default `"class"`); unmapped values become
  `default` (default `NA`).

- margin:

  Extra width kept around the field (cells drawn partly inside).

- x, y, label:

  Column names.

## Value

A list of class `phenoscapR_cellmap` with `cells`, `interface` (data
frame of grid points in the zone, or `NULL`), `centre`, `size`, `step`
and `extent` (`c(xmin, xmax, ymin, ymax)`).

## Details

The field centre is given directly, taken from a cell (`centre_cell`,
the value of column `id`), taken from the first row of a data frame with
columns `x` and `y`, snapped to a regular grid anchored at the minimum
cell coordinates (`grid`), and finally shifted by `offset`.

## Examples

``` r
set.seed(1)
d <- data.frame(x = runif(200, 0, 100), y = runif(200, 0, 100),
                label = sample(c("t", "a"), 200, TRUE))
m <- CellMapData(d, centre = c(50, 50), size = 40,
                 interface = list(labels = "t", radius = 5, step = 2))
nrow(m$cells)
#> [1] 30
```
