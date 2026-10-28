# Layered Point Data for an Embedding

Stacks the points of several layers in drawing order: each layer selects
rows by column values, takes its key either as a fixed name or from a
column, and may be put in random order (for example so that no cell type
is systematically drawn on top). The random order is a permutation from
R's default generator after `set.seed(seed)`; the caller's random state
is left unchanged.

## Usage

``` r
EmbeddingLayers(data, x = "x", y = "y", layers, carry = NULL, seed = NULL)
```

## Arguments

- data:

  Data frame with coordinates.

- x, y:

  Coordinate columns.

- layers:

  List of layers, each a list with `filter` (named list of columns and
  values), `key` (fixed key) or `key_from` (column holding the key),
  optional `recode` (named mapping of keys) and `shuffle`.

- carry:

  Further columns copied to the output.

- seed:

  Seed for shuffled layers.

## Value

A data frame with `x`, `y`, `key`, `layer` and the carried columns, in
drawing order.

## Examples

``` r
d <- data.frame(u = 1:6, v = 6:1, type = c("a", "b", "a", "c", "b", "a"), kept = TRUE)
EmbeddingLayers(d, "u", "v", layers = list(
  list(filter = list(kept = TRUE), key = "background"),
  list(filter = list(type = "a"), key_from = "type", shuffle = TRUE)), seed = 1)
#>   x y        key layer
#> 1 1 6 background     1
#> 2 2 5 background     1
#> 3 3 4 background     1
#> 4 4 3 background     1
#> 5 5 2 background     1
#> 6 6 1 background     1
#> 7 1 6          a     2
#> 8 6 1          a     2
#> 9 3 4          a     2
```
