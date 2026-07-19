# Differential Abundance of Phenotypes Across Conditions

Tests whether the proportion of each phenotype differs between
experimental conditions. Proportions are computed per sample (the unit
of replication), then compared across the condition groups, so the test
respects the sample-level design rather than treating individual cells
as independent.

## Usage

``` r
DifferentialAbundance(
  object,
  condition,
  phenotype_col = "phenotype",
  test = c("wilcox", "t", "kruskal")
)
```

## Arguments

- object:

  A
  [`SpatialCellData-class`](https://cttir.github.io/phenoscapR/reference/SpatialCellData-class.md)
  object with several samples.

- condition:

  Character. Metadata column giving each cell's condition (constant
  within a sample).

- phenotype_col:

  Character. Phenotype column. Default `"phenotype"`.

- test:

  Character. `"wilcox"` (default) or `"t"` for two groups; `"kruskal"`
  for more than two.

## Value

A classed data frame (`phenoscapR_diffabund`) with one row per
phenotype: per-condition mean proportions, the test `statistic`,
`p_value`, and BH-adjusted `p_adj`.

## Examples

``` r
data(phenoscapR_example)
obj <- phenoscapR_example
obj@meta_data$phenotype <- obj@meta_data$phenotype_true
# Toy condition: label the two sections as different arms.
obj@meta_data$arm <- ifelse(obj$sample_id == "tonsil_A", "ctrl", "treat")
DifferentialAbundance(obj, condition = "arm")
#> Warning: Some conditions have fewer than 2 samples; p-values are unreliable.
#> <phenoscapR> Differential abundance (wilcox test)
#>   conditions: ctrl vs treat
#>   0 of 6 phenotypes differ at p_adj < 0.05
#>    phenotype mean_ctrl mean_treat statistic p_value p_adj
#>       B cell  0.250000   0.250000       0.5       1     1
#>   Epithelial  0.281250   0.281250       0.5       1     1
#>   Macrophage  0.118750   0.118750       0.5       1     1
#>  T cytotoxic  0.140625   0.140625       0.5       1     1
#>     T helper  0.171875   0.171875       0.5       1     1
#>        T reg  0.037500   0.037500       0.5       1     1
```
