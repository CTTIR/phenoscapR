# Set or Get the Default Colour Palette

Sets a global colour palette used by all plotting functions in
phenoscapR. The palette can be a viridis option, a custom gradient
defined by 2-3 anchor colours, or a named vector of discrete colours.

## Usage

``` r
SetPalette(palette)

GetPalette()
```

## Arguments

- palette:

  Character or named character vector. Either:

  - A viridis-family palette name: `"viridis"` (default), `"inferno"`,
    `"plasma"`, `"cividis"`, `"rocket"`, or `"mako"`.

  - A character vector of 2-3 hex colours for a custom gradient (e.g.
    `c("#440154", "#21918c", "#fde725")`).

  - `NULL` to return the current palette without changing it.

  An unrecognised name falls back to `"viridis"` rather than erroring.

## Value

Invisibly returns the previous palette setting.

## Examples

``` r
SetPalette("inferno")
GetPalette()
#> [1] "inferno"

# Custom 3-colour gradient
SetPalette(c("navy", "white", "firebrick"))
GetPalette()
#> [1] "navy"      "white"     "firebrick"

# Reset to default
SetPalette("viridis")
```
