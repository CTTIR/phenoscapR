# Describe One Figure Panel

A panel places a plot so that its data area fills `box` exactly; axis
labels, ticks and legends extend outside the box, as in hand-laid
journal figures. Boxes are measured in millimetres from the top-left
corner of the page.

## Usage

``` r
FigurePanel(
  plot,
  box,
  letter = NULL,
  letter_at = NULL,
  heading = NULL,
  note = NULL,
  fill_box = FALSE,
  typeset = TRUE
)
```

## Arguments

- plot:

  A 'ggplot2' plot, a 'grid' grob, or `NULL` for a text-only panel.

- box:

  Numeric `c(left, top, width, height)` in millimetres.

- letter:

  Optional panel letter.

- letter_at:

  Optional `c(left, top)` of the letter in millimetres; defaults to 4 mm
  left of and 3 mm above the box.

- heading:

  Optional panel heading, set bold above the box.

- note:

  Optional statistic or note line, set small and grey directly above the
  box (below the heading).

- fill_box:

  If `TRUE`, the whole plot (including axes) is fitted into the box
  instead of aligning the data area.

- typeset:

  If `FALSE`, heading, note and the text drawn by the plot are not
  typeset (see
  [`TypesetLabel()`](https://cttir.github.io/phenoscapR/reference/TypesetLabel.md)).

## Value

A list of class `phenoscapR_panel`.

## See also

[`ComposeFigure()`](https://cttir.github.io/phenoscapR/reference/ComposeFigure.md)

## Examples

``` r
FigurePanel(NULL, c(10, 10, 40, 30), letter = "a", heading = "Overview")
#> $plot
#> NULL
#> 
#> $box
#> [1] 10 10 40 30
#> 
#> $letter
#> [1] "a"
#> 
#> $letter_at
#> NULL
#> 
#> $heading
#> [1] "Overview"
#> 
#> $note
#> NULL
#> 
#> $fill_box
#> [1] FALSE
#> 
#> $typeset
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "phenoscapR_panel"
```
