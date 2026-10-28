# Voronoi Territory Tiles of the Cells in a Field

Computes the Voronoi tessellation of the cells around a square field and
caps every territory at `cap` from its cell by moving the polygon
vertices that lie further away onto that radius; cells on the outer hull
(unbounded territories) get a regular 12-gon of radius `0.7 * cap`. Each
tile carries a class from `classes` (first matching entry), and tiles
are ordered for drawing by `order` (classes listed first are drawn
first, all others afterwards; ties keep cell order). Requires 'deldir'.

## Usage

``` r
TerritoryTiles(
  cells,
  centre = NULL,
  size,
  cap = 11,
  margin = 30,
  classes = list(),
  default = "other",
  order = c("other", "tumour"),
  centre_cell = NULL,
  id = "row",
  offset = NULL,
  x = "x",
  y = "y",
  label = "label"
)
```

## Arguments

- cells:

  Data frame of cells.

- centre:

  `c(x, y)`, a data frame with `x`, `y`, or `NULL` with `centre_cell`.

- size:

  Field width.

- cap:

  Maximum territory radius.

- margin:

  Neighbourhood kept around the field for the tessellation.

- classes:

  Named list: class name to labels; unmatched cells get `default`.

- default:

  Class of unmatched cells.

- order:

  Classes drawn first, in this order.

- centre_cell, id, offset:

  As in
  [`CellMapData()`](https://cttir.github.io/phenoscapR/dev/reference/CellMapData.md).

- x, y, label:

  Column names.

## Value

A list of class `phenoscapR_territories` with `tiles` (data frame with
`tile`, `x`, `y`, `class`), `centre`, `size` and `extent`.

## Examples

``` r
if (requireNamespace("deldir", quietly = TRUE)) {
  set.seed(2)
  d <- data.frame(x = runif(300, 0, 100), y = runif(300, 0, 100),
                  label = sample(c("t", "a"), 300, TRUE))
  tt <- TerritoryTiles(d, c(50, 50), 40, cap = 5, classes = list(tumour = "t"))
  head(tt$tiles)
}
#>   tile        x        y class
#> 1    1 43.95380 69.24557 other
#> 2    1 39.75610 68.45388 other
#> 3    1 38.17729 64.30769 other
#> 4    1 44.59806 64.97032 other
#> 5    2 48.07636 75.33569 other
#> 6    2 48.08042 76.69321 other
```
