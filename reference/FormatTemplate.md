# Fill Text Templates from Table Rows

Replaces placeholders in braces with values of `data`, so that figure
text such as `"{k|d}/{n|d} patients; p = {p|p}"` is written from plot
data rather than typed by hand. Placeholders:

## Usage

``` r
FormatTemplate(template, data = NULL)
```

## Arguments

- template:

  Character vector of templates. A single template is applied to every
  row; several templates use one row each, or all the single row of a
  one-row table.

- data:

  A data frame (or a named list treated as one row), or `NULL` for
  templates without placeholders.

## Value

Character vector, one element per template or per row.

## Details

- `{column}`: the value; whole numbers with thousands separators
  (`1,200`), other numbers and text as they are, missing and infinite
  values `"n.e."`. Negative numbers are written with a true minus sign.

- `{column|format}`: a named format: `p`
  ([`FormatP()`](https://cttir.github.io/phenoscapR/reference/FormatP.md)),
  `pfixed` (four decimals below 0.01, three otherwise), `d` (rounded
  integer), `comma` (rounded integer with thousands separators), `f0` to
  `f9` (fixed decimals), `sf0` to `sf9` (fixed decimals with a leading
  `+` or true minus sign) and `s` (the value as text).

- `{column:%fmt}`: a [`sprintf()`](https://rdrr.io/r/base/sprintf.html)
  format such as `%.1f`.

- `{column~singular~plural}`: `singular` when the value is 1, otherwise
  `plural`.

A placeholder whose whole content is a column name refers to that
column, so column names may contain `|`, `:` or `~`.

## Examples

``` r
d <- data.frame(k = 11, n = 12, p = 0.00146, cells = 27081)
FormatTemplate("{k|d}/{n|d} patients; p = {p|p}", d)
#> [1] "11/12 patients; p = 0.0015"
FormatTemplate("{cells} cells ({cells:%.0f}); {k~patient~patients}", d)
#> [1] "27,081 cells (27081); patients"
FormatTemplate("{x|sf1} ({share|f0}%)", data.frame(x = -3.42, share = 51.2))
#> [1] "−3.4 (51%)"
```
