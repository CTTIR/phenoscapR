# Manuscript Palettes

Named colour palettes used by
[`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/reference/ManuscriptStyle.md).
Names are generic cell types, groups, markers and alteration classes; a
study maps its own labels onto them.

## Usage

``` r
ManuscriptPalettes()
```

## Value

A named list of named character vectors.

## Details

- `groups`: Okabe-Ito colours for three clinical groups (`group1` to
  `group3`).

- `lineage`: one colour per cell lineage for legends and embeddings.

- `subsets`: highlight colours for cell maps (focus subsets on grey
  background cells) and the tumour interface tint.

- `coarse`: six coarse classes for whole-section maps.

- `neighbourhood`: an ordered palette for cellular neighbourhoods.

- `fluorescence`: display colours of common immunofluorescence channels.

- `alteration`: genomic alteration classes.

- `qc`: four colours for exclusion classes.

- `sequential`, `diverging`: endpoints for continuous scales.

- `clusters`: twenty colours for many unordered clusters.

## Examples

``` r
ManuscriptPalettes()$groups
#>    group1    group2    group3 
#> "#009E73" "#D55E00" "#0072B2" 
```
