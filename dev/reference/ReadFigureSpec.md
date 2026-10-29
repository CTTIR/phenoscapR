# Read a Figure Specification

Reads one or more JSON specification files (or a directory of them) and
merges them as described in
[`RenderFigure()`](https://cttir.github.io/phenoscapR/dev/reference/RenderFigure.md).

## Usage

``` r
ReadFigureSpec(paths)
```

## Arguments

- paths:

  JSON file paths or one directory.

## Value

The merged specification list.

## Examples

``` r
if (requireNamespace("jsonlite", quietly = TRUE)) {
  dir <- tempfile("spec")
  dir.create(dir)
  writeLines('{"height_mm": 50, "panels": [{"box": [15, 10, 45, 30], "grammar": "group_strip",
    "data": "values"}]}', file.path(dir, "1-page.json"))
  writeLines('{"texts": [{"label": "Note", "at": [5, 48]}]}', file.path(dir, "2-texts.json"))
  str(ReadFigureSpec(dir), max.level = 1)
  unlink(dir, recursive = TRUE)
}
#> List of 4
#>  $ panels   :List of 1
#>  $ texts    :List of 1
#>  $ legends  : list()
#>  $ height_mm: int 50
```
