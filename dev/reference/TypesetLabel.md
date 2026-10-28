# Typeset Figure Text

Applies manuscript typesetting to plain labels and returns rich text for
'gridtext'/'ggtext': italic *P*, *q* and *n* before `=` or `<`; powers
of ten for `4.9e-04`; superscript plus signs on markers (`CD8+`,
`FOXP3+`, `CD4 T`, `CD8 T`); `Treg`/`Tregs` with subscript *reg*;
`log2`; `mm2`; micrometres; italic gene symbols; and line breaks.
Straight quotes stay straight (no typographic apostrophes).

## Usage

``` r
TypesetLabel(
  x,
  genes = c("TP53", "RB1"),
  markers = c("CD\\d+[a-z]?", "FOXP3", "PD-L1", "PD-1", "Ki67", "MPO"),
  rich = .fig_has_rich_text()
)
```

## Arguments

- x:

  Character vector of labels.

- genes:

  Gene symbols to set in italics.

- markers:

  Marker names that take a superscript `+` when followed by `+`.

- rich:

  If `FALSE`, return plain text with Unicode substitutes (superscript
  plus, subscript two, minus sign) instead of markup. The default uses
  markup when 'gridtext' and 'ggtext' are installed.

## Value

Character vector of the same length.

## Details

Typesetting can be switched off with
`options(phenoscapR.typeset = FALSE)`; labels are then only escaped for
rich text. Single rules are switched off by naming them instead, for
example `options(phenoscapR.typeset = "treg")`: `"exponent"`, `"p"`,
`"q"`, `"n"`, `"markers"`, `"treg"`, `"log2"`, `"mm2"`, `"um"` and
`"genes"`. Figure specifications do this per figure, panel, text or
legend (`"typeset"`, see
[`RenderFigure()`](https://cttir.github.io/phenoscapR/dev/reference/RenderFigure.md)).

## Examples

``` r
TypesetLabel(c("p = 4.9e-04", "Tregs near CD8+ cells", "log2 ratio (mm2)"),
             rich = FALSE)
#> [1] "P = 4.9 × 10⁻⁴"             "Treg cells near CD8⁺ cells"
#> [3] "log₂ ratio (mm²)"          
```
