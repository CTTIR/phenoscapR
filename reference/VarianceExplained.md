# Variance Explained by Principal Components

Returns the percentage of total variance captured by each principal
component from a previously computed PCA reduction.

## Usage

``` r
VarianceExplained(object)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object.

## Value

A named numeric vector of percent-variance-explained per PC.

## Examples

``` r
counts <- matrix(rnorm(500), nrow = 50,
                 dimnames = list(NULL, paste0("M", 1:10)))
coords <- data.frame(x = runif(50), y = runif(50))
obj <- RunPCA(CreateSpatialObject(counts, coords), n_pcs = 5)
VarianceExplained(obj)
#>     PC_1     PC_2     PC_3     PC_4     PC_5 
#> 17.43838 16.56759 12.93802 11.43196 10.32822 
```
