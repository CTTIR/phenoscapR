# Attach Cell Positions to a Table of Cell References

Looks up cells referenced by image and row (as in review ledgers and
example lists) in per-image cell tables and adds their positions and
further columns.

## Usage

``` r
CellPositionsFor(
  table,
  cells,
  labels = NULL,
  source = "sample_id",
  row = "row",
  columns = c("x", "y", "label")
)
```

## Arguments

- table:

  Data frame with an image key column and a row column.

- cells:

  List of cell tables (with column `row`), one per image.

- labels:

  Image keys of `cells`, in list order (default the list names).

- source, row:

  Columns of `table` holding the image key and the cell row.

- columns:

  Columns copied from the cell tables.

## Value

`table` with the added columns.
