# Centre of the Densest Grid Window

Bins cells into square windows of a regular grid with origin 0 and
returns the centre of the window holding the most cells (ties: the
window with the smallest x index, then y index).

## Usage

``` r
DensestGridWindow(cells, size, filter = list(), x = "x", y = "y")
```

## Arguments

- cells:

  Data frame of cells.

- size:

  Window width.

- filter:

  Optional named list: column to values; only matching cells are
  counted. Use `NA` among the values to count missing values.

- x, y:

  Column names.

## Value

A one-row data frame with `x`, `y` (window centre), `x0`, `y0` (window
corner) and `n`.

## Examples

``` r
d <- data.frame(x = c(1, 2, 15, 16, 17), y = c(1, 2, 5, 6, 7))
DensestGridWindow(d, 10)
#>    x y x0 y0 n
#> 1 15 5 10  0 3
```
