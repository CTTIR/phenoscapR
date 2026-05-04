# Create a Custom Gradient Palette from Anchor Colours

Creates a gradient palette function from 2 or 3 anchor colours. The
returned function takes an integer `n` and returns `n` colours.

## Usage

``` r
CustomGradient(colours)
```

## Arguments

- colours:

  Character vector of 2-3 colours (names or hex codes).

## Value

A function that takes integer `n` and returns `n` hex colour codes.

## Examples

``` r
pal <- CustomGradient(c("navy", "white", "firebrick"))
cols <- pal(100)
image(matrix(1:100, ncol = 1), col = cols)

```
