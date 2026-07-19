# Interaction Matrix (SpatialCellData)

Computes pairwise spatial interaction scores between phenotypes.

## Usage

``` r
InteractionMatrix(
  object,
  radius,
  method = c("analytic", "permutation"),
  n_perm = 100L,
  seed = NULL
)
```

## Arguments

- object:

  An
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

- radius:

  Numeric. Radius for defining spatial neighbourhoods.

- method:

  Character. `"analytic"` (default) compares observed neighbour counts
  to an expectation under random mixing; `"permutation"` builds the null
  by shuffling phenotype labels within each sample, adding `z_score` and
  `p_value` columns.

- n_perm:

  Integer. Number of label permutations when `method = "permutation"`.
  Default `100`.

- seed:

  Integer or `NULL`. Random seed for the permutation null.

## Value

A data frame with columns `from`, `to`, `observed`, `expected`, and
`interaction_score`; the permutation method adds `z_score` and
`p_value`.

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
#> <phenoscapR> Phenotype interaction matrix
#>   3 phenotypes; score = log2(observed / expected)
#>   strongest attractions:
#>  from     to interaction_score
#>  CD3+   CD3+        0.57196484
#>  CD3+   CD8+        0.46726746
#>  CD8+   CD3+        0.46726746
#>  CD8+   CD8+        0.04508789
#>  CD3+ Tumour       -0.08116917
```
