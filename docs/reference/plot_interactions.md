# Plot Interaction Heatmap

Visualises the spatial interaction matrix as a heatmap.

## Usage

``` r
plot_interactions(interactions, title = NULL)
```

## Arguments

- interactions:

  A `data.table` as returned by
  [`interaction_matrix()`](https://r-heller.github.io/phenoscapR/reference/interaction_matrix.md).

- title:

  Character string or `NULL`. Plot title.

## Value

A `ggplot` object.

## Examples

``` r
interactions <- data.table::data.table(
  from = rep(c("CD3+", "CD8+"), each = 2),
  to = rep(c("CD3+", "CD8+"), 2),
  observed = c(50, 30, 25, 40),
  expected = c(35, 35, 35, 35),
  interaction_score = log2(c(50, 30, 25, 40) / 35)
)
plot_interactions(interactions)

```
