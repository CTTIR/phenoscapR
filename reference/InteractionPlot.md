# Plot Spatial Interaction Heatmap

Heatmap of pairwise spatial interaction scores between phenotypes.

## Usage

``` r
InteractionPlot(interactions, title = NULL)
```

## Arguments

- interactions:

  Data frame as returned by
  [`InteractionMatrix`](https://cttir.github.io/phenoscapR/reference/InteractionMatrix.md).

- title:

  Character or `NULL`.

## Value

A `ggplot` object.

## Examples

``` r
interactions <- data.frame(
  from = rep(c("CD3+", "CD8+"), each = 2),
  to = rep(c("CD3+", "CD8+"), 2),
  observed = c(50, 30, 25, 40),
  expected = rep(35, 4),
  interaction_score = log2(c(50, 30, 25, 40) / 35)
)
InteractionPlot(interactions)

```
