# Summarise Phenotype Proportions

Computes phenotype frequencies and proportions per sample. Missing
phenotype labels are retained as an explicit unknown category and remain
in the sample denominator. This descriptive summary does not test
differential abundance.

## Usage

``` r
summarise_phenotypes(dt)
```

## Arguments

- dt:

  A `data.table` with a `phenotype` column, as returned by
  [`phenotype_cells()`](https://cttir.github.io/phenoscapR/reference/phenotype_cells.md).

## Value

A `data.table` with columns `sample_id`, `phenotype`, `count`, and
`proportion`.

## Examples

``` r
dt <- data.table::data.table(
  sample_id = rep("s1", 100),
  phenotype = sample(c("CD3+", "CD8+", "Negative"), 100, replace = TRUE)
)
summarise_phenotypes(dt)
#>    sample_id phenotype count proportion
#>       <char>    <char> <int>      <num>
#> 1:        s1  Negative    34       0.34
#> 2:        s1      CD3+    24       0.24
#> 3:        s1      CD8+    42       0.42
```
