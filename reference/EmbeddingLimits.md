# Display Limits of an Embedding

Limits enclosing the central part of the points plus a margin: the
`probs` quantiles of each coordinate (type 7, linear interpolation)
widened by `pad` times their span on both sides.

## Usage

``` r
EmbeddingLimits(
  data,
  x = "x",
  y = "y",
  filter = NULL,
  probs = c(5e-04, 0.9995),
  pad = 0.04
)
```

## Arguments

- data:

  Data frame with coordinates.

- x, y:

  Coordinate columns.

- filter:

  Optional named list of columns and values selecting the points used.

- probs:

  Lower and upper quantile.

- pad:

  Margin as a fraction of the quantile span.

## Value

A one-row data frame with `xmin`, `xmax`, `ymin`, `ymax`.

## Examples

``` r
EmbeddingLimits(data.frame(x = 1:100, y = (1:100)^2))
#>       xmin     xmax      ymin     ymax
#> 1 -2.90654 103.9065 -398.4115 10389.71
```
