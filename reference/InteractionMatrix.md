# Interaction Matrix (SpatialCellData)

Computes pairwise spatial interaction scores between phenotypes.

## Usage

``` r
InteractionMatrix(object, radius)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://r-heller.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- radius:

  Numeric. Radius for defining spatial neighbourhoods.

## Value

A data frame with columns `from`, `to`, `observed`, `expected`, and
`interaction_score`.

## Examples

``` r
set.seed(42)
counts <- matrix(rnorm(200), nrow = 100,
                 dimnames = list(NULL, c("CD3", "CD8")))
coords <- data.frame(x = runif(100, 0, 500), y = runif(100, 0, 500))
meta <- data.frame(cell_id = 1:100, sample_id = "s1",
  phenotype = sample(c("CD3+", "CD8+", "Tumour"), 100, replace = TRUE))
obj <- CreateSpatialObject(counts, coords, meta)
InteractionMatrix(obj, radius = 50)
#>     from     to observed expected interaction_score
#> 1   CD3+   CD3+       40   26.908        0.57196484
#> 2   CD3+   CD8+       36   26.040        0.46726746
#> 3   CD3+ Tumour       32   33.852       -0.08116917
#> 4   CD8+   CD3+       36   26.040        0.46726746
#> 5   CD8+   CD8+       26   25.200        0.04508789
#> 6   CD8+ Tumour       26   32.760       -0.33342373
#> 7 Tumour   CD3+       32   33.852       -0.08116917
#> 8 Tumour   CD8+       26   32.760       -0.33342373
#> 9 Tumour Tumour       26   42.588       -0.71193536
```
