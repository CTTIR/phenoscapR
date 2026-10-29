# Cells Paired with Their Nearest Partner Cell

For selected cells (by identifier) finds the nearest cell with a partner
label and returns both positions, their distance and the midpoint, the
input of close-up fields that show a cell next to its nearest neighbour
of another type.

## Usage

``` r
NearestPartnerPairs(
  cells,
  ids,
  partner,
  id = "row",
  x = "x",
  y = "y",
  label = "label"
)
```

## Arguments

- cells:

  Data frame of cells.

- ids:

  Identifiers (values of `id`) of the focus cells, in output order.

- partner:

  Labels of the partner cells.

- id, x, y, label:

  Column names.

## Value

A data frame with `id`, `x`, `y`, `partner_id`, `partner_x`,
`partner_y`, `distance`, `mid_x` and `mid_y`.

## Examples

``` r
d <- data.frame(row = 0:3, x = c(0, 4, 10, 30), y = 0, label = c("f", "p", "f", "p"))
NearestPartnerPairs(d, c(0, 2), "p")
#>   id  x y partner_id partner_x partner_y distance mid_x mid_y
#> 1  0  0 0          1         4         0        4     2     0
#> 2  2 10 0          1         4         0        6     7     0
```
