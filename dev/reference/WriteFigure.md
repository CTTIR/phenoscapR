# Write a Figure from a Specification

File-producing form of
[`RenderFigure()`](https://cttir.github.io/phenoscapR/dev/reference/RenderFigure.md)
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
  [`ManuscriptStyle()`](https://cttir.github.io/phenoscapR/dev/reference/ManuscriptStyle.md)
  object.

## Value

Output paths, invisibly.
