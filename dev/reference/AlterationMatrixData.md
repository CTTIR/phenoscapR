# Alteration Classes for an Alteration Matrix

Turns a gene-by-sample table of alteration types (several types joined
by a separator) into one class per gene and item: types are mapped to
classes (for example nonsense, frameshift and splice variants to
"Truncating"), and a gene with more than one class in a sample is
"Multiple". Genes are selected and ordered as `first`, then genes
altered in at least `min_count` samples by decreasing count (ties in
table order), then `last`.

## Usage

``` r
AlterationMatrixData(
  matrix,
  gene = NULL,
  ids,
  id_map = NULL,
  map_from = NULL,
  map_to = NULL,
  first = NULL,
  last = NULL,
  min_count = 1,
  classes = list(Truncating = c("Nonsense", "Frameshift", "Splice")),
  multiple = "Multiple",
  separator = "|"
)
```

## Arguments

- matrix:

  Data frame: gene column and one column per sample; empty or missing
  entries mean no alteration.

- gene:

  Gene column (default the first column).

- ids:

  Items (columns of the plot) in order: vector or data frame ordered by
  `rank`.

- id_map:

  Optional data frame mapping items to sample columns.

- map_from, map_to:

  Columns of `id_map`.

- first, last:

  Genes always shown first and last.

- min_count:

  Smallest number of altered samples for other genes.

- classes:

  Named list: class to the types it collects; other types keep their
  name.

- multiple:

  Class of genes with several classes in one sample.

- separator:

  Separator of several types in one entry.

## Value

A long data frame with `gene`, `id`, `class` (missing if none), `count`
(altered samples of the gene in the table), `percent` (count relative to
the number of items) and `gene_rank`.

## Examples

``` r
m <- data.frame(gene = c("G1", "G2"), S1 = c("Missense", ""), S2 = c("Nonsense|Missense", "Deletion"))
AlterationMatrixData(m, ids = c("S1", "S2"), min_count = 1)
#>   gene id    class count percent gene_rank
#> 1   G1 S1 Missense     2     100         1
#> 2   G1 S2 Multiple     2     100         1
#> 3   G2 S1     <NA>     1      50         2
#> 4   G2 S2 Deletion     1      50         2
```
