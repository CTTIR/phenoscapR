# Spatial Interaction Matrix

Computes a pairwise interaction matrix between phenotypes based on
observed versus expected neighbour frequencies within a given radius.

## Usage

``` r
interaction_matrix(dt, radius)
```

## Arguments

- dt:

  A `data.table` with columns `x`, `y`, `phenotype`, and `sample_id`.

- radius:

  Numeric. Radius for defining spatial neighbourhoods.

## Value

A `data.table` in long format with columns `from`, `to`, `observed`,
`expected`, and `interaction_score` (log2 observed/expected). Positive
values indicate spatial attraction; negative values indicate avoidance.

## Examples

``` r
set.seed(42)
dt <- data.table::data.table(
  sample_id = "s1", cell_id = 1:100,
  x = runif(100, 0, 500), y = runif(100, 0, 500),
  phenotype = sample(c("CD3+", "CD8+", "Tumour"), 100, replace = TRUE)
)
interactions <- interaction_matrix(dt, radius = 50)
interactions
#>      from     to observed expected interaction_score
#>    <char> <char>    <num>    <num>             <num>
#> 1:   CD3+   CD3+       62  45.9192         0.4331707
#> 2:   CD3+   CD8+       35  38.6688        -0.1438151
#> 3:   CD3+ Tumour       40  36.2520         0.1419394
#> 4:   CD8+   CD3+       35  38.6688        -0.1438151
#> 5:   CD8+   CD8+       36  32.5632         0.1447544
#> 6:   CD8+ Tumour       23  30.5280        -0.4084992
#> 7: Tumour   CD3+       40  36.2520         0.1419394
#> 8: Tumour   CD8+       23  30.5280        -0.4084992
#> 9: Tumour Tumour       24  28.6200        -0.2539893
```
