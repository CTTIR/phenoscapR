# Write a Figure from a Specification

File-producing form of
[`RenderFigure()`](https://cttir.github.io/phenoscapR/reference/RenderFigure.md)
for workflow graphs: reads the specification and the panel data, renders
the figure and writes PDF and PNG files.

## Usage

``` r
WriteFigure(spec, data, pdf, png, style = ManuscriptStyle())
```

## Arguments

- spec:

  Specification list or JSON path.

- data:

  Named list of data frames, or of paths to `.rds`, `.tsv`, `.tsv.gz` or
  `.csv` files.

- pdf, png:

  Output paths.

- style:

  A
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/reference/ManuscriptStyle.md)
  object.

## Value

Output paths, invisibly.

## Examples

``` r
values <- tempfile(fileext = ".tsv")
write.table(data.frame(group = rep(c("A", "B"), each = 3), value = c(1, 2, 3, 2, 3, 5)),
            values, sep = "\t", row.names = FALSE, quote = FALSE)
spec <- list(height_mm = 50, width_mm = 70, panels = list(
  list(box = c(15, 10, 45, 30), letter = "a", grammar = "group_strip", data = "values")))
if (capabilities("cairo")) {
  WriteFigure(spec, list(values = values), pdf = tempfile(fileext = ".pdf"),
              png = tempfile(fileext = ".png"))
}
```
