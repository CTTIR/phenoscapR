# Composite Fluorescence Images from Channel Fields

Turns image fields (lists with a `channels` element of named matrices,
as returned by `segmantR::sg_read_field()`) into RGB images for
galleries: every view is an additive mixture of display-scaled channels,
`clip((value - lo) / (hi - lo), 0, 1) ^ gamma * weight * colour`.

## Usage

``` r
CompositeFields(
  fields,
  views,
  slide = NULL,
  levels = NULL,
  source = "source",
  gamma = 0.8,
  min_span = 1,
  style = ManuscriptStyle()
)
```

## Arguments

- fields:

  List of fields (`channels`, and `row` with the field's table row for
  column lookups).

- views:

  Named list of views; each view is a list of layers.

- slide, levels:

  Optional data frames with columns `channel`, `lo`, `hi` and, when
  fields come from several images, `source`.

- source:

  Column of a field's `row` that matches `source` in the range tables.

- gamma:

  Display gamma.

- min_span:

  Minimum distance between the levels.

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptStyle.md)
  object (resolves colour names).

## Value

A list of class `phenoscapR_images` with `images` (list of RGB arrays)
and `info` (data frame: `image`, `field`, `view` and the columns of each
field's row).

## Details

A layer is a list with `channel` (a channel name) or `column` (a column
of the field's `row` table that holds the channel name), `colour` (hex
or style colour), optional `weight` (default 1), `overlay` (paint over
the mixture instead of adding) and display levels: `lo` and `hi`. `lo`
is the name of a range table (`"slide"`, `"levels"`) or `"q0.01"` (a
quantile of the field's own values); `hi` is one or several terms, each
a table name, a table name with a factor (`"slide*0.9"`) or a quantile
(`"q0.995"`); the largest term is used, and never less than
`lo + min_span`.

## Examples

``` r
set.seed(1)
field <- list(channels = list(dna = matrix(runif(100, 0, 50), 10),
                              cd3 = matrix(runif(100, 0, 20), 10)))
views <- list(merge = list(list(channel = "dna", colour = "#3366FF", lo = "q0", hi = "q0.99"),
                           list(channel = "cd3", colour = "#FF3300", lo = "q0.5", hi = "q1")))
imgs <- CompositeFields(field, views)
dim(imgs$images[[1]])
#> [1] 10 10  3
imgs$info
#>   image field  view field_name
#> 1     1     1 merge          1
```
