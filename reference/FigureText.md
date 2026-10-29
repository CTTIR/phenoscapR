# Place Text on a Figure Page

Place Text on a Figure Page

## Usage

``` r
FigureText(
  label,
  at,
  size = NULL,
  colour = NULL,
  bold = FALSE,
  hjust = 0,
  vjust = 1,
  angle = 0,
  typeset = TRUE
)
```

## Arguments

- label:

  Text, typeset with
  [`TypesetLabel()`](https://cttir.github.io/phenoscapR/reference/TypesetLabel.md).

- at:

  Numeric `c(left, top)` in millimetres.

- size:

  Font size in points; default is the style's note size.

- colour:

  Text colour; default is the style's muted colour.

- bold:

  Bold face.

- hjust, vjust:

  Justification relative to `at`; by default the text hangs below and to
  the right of the point. `vjust = "baseline"` puts the baseline of the
  last line at `at`, as figure text placed without vertical alignment in
  common plotting code.

- angle:

  Rotation in degrees.

- typeset:

  If `FALSE`, the label is drawn as written (see
  [`TypesetLabel()`](https://cttir.github.io/phenoscapR/reference/TypesetLabel.md)).

## Value

A list of class `phenoscapR_text`.

## Examples

``` r
FigureText("Median and IQR\nn = 12 patients", c(20, 50))
#> $label
#> [1] "Median and IQR\nn = 12 patients"
#> 
#> $at
#> [1] 20 50
#> 
#> $size
#> NULL
#> 
#> $colour
#> NULL
#> 
#> $bold
#> [1] FALSE
#> 
#> $hjust
#> [1] 0
#> 
#> $vjust
#> [1] 1
#> 
#> $angle
#> [1] 0
#> 
#> $typeset
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "phenoscapR_text"
FigureText("Treg-like cells", c(20, 60), vjust = "baseline", typeset = FALSE)
#> $label
#> [1] "Treg-like cells"
#> 
#> $at
#> [1] 20 60
#> 
#> $size
#> NULL
#> 
#> $colour
#> NULL
#> 
#> $bold
#> [1] FALSE
#> 
#> $hjust
#> [1] 0
#> 
#> $vjust
#> [1] "baseline"
#> 
#> $angle
#> [1] 0
#> 
#> $typeset
#> [1] FALSE
#> 
#> attr(,"class")
#> [1] "phenoscapR_text"
```
