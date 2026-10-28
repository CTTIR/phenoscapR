# Coloured Annotation Tracks

Builds categorical annotation tracks (for example clinical group,
co-mutation, architecture) for a set of items: each track takes a value
column, maps values to colours by exact values or regular expressions
and uses a default colour otherwise.

## Usage

``` r
AnnotationTracks(data, id, tracks, style = ManuscriptStyle())
```

## Arguments

- data:

  Data frame with one row per item.

- id:

  Identifier column.

- tracks:

  List of tracks: `name`, `column`, `colours` (named mapping value to
  colour), optional `patterns` (named mapping regular expression to
  colour) and `default`. Colours may be hex values or palette entries
  such as `"groups/group1"`.

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptStyle.md)
  object resolving palette entries.

## Value

A long data frame with `id`, `track`, `value`, `colour` and
`track_rank`.

## Examples

``` r
d <- data.frame(p = c("a", "b"), grp = c("x", "y"), mut = c("yes", "no"))
AnnotationTracks(d, "p", list(
  list(name = "Group", column = "grp", colours = c(x = "groups/group1", y = "groups/group2")),
  list(name = "Mutation", column = "mut", colours = c(yes = "#222222"), default = "#E0E0E0")))
#>   p    track value  colour track_rank
#> 1 a    Group     x #009E73          1
#> 2 b    Group     y #D55E00          1
#> 3 a Mutation   yes #222222          2
#> 4 b Mutation    no #E0E0E0          2
```
