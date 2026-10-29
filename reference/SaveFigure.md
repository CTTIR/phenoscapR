# Save a Composed Figure as PDF and PNG

Writes the page at its exact size: PDF through the Cairo device with
embedded TrueType fonts, PNG through 'ragg' at the style's resolution
(falling back to the 'png' Cairo device when 'ragg' is absent).

## Usage

``` r
SaveFigure(figure, pdf = NULL, png = NULL, dpi = NULL)
```

## Arguments

- figure:

  A
  [`ComposeFigure()`](https://cttir.github.io/phenoscapR/reference/ComposeFigure.md)
  result.

- pdf:

  Output PDF path, or `NULL`.

- png:

  Output PNG path, or `NULL`.

- dpi:

  Raster resolution; defaults to the style's.

## Value

The output paths, invisibly.

## Details

With 'ragg', the page is drawn on a new capture device for every save
and the captured pixels are written by
[`ragg::agg_png()`](https://ragg.r-lib.org/reference/agg_png.html).
'gridtext' keeps rich text metrics for the session under the device
name, not its resolution, so a fresh device name makes the PNG
independent of what was drawn before in the session. Without 'ragg',
PNGs saved at different resolutions in one session can place rich text a
pixel apart.

## Examples

``` r
p <- ggplot2::ggplot(data.frame(x = 1:3, y = c(2, 1, 3)), ggplot2::aes(x, y)) +
  ggplot2::geom_point()
fig <- ComposeFigure(list(FigurePanel(p, c(10, 8, 50, 30), letter = "a")),
                     height_mm = 45, width_mm = 70)
if (capabilities("cairo")) {
  out <- SaveFigure(fig, pdf = tempfile(fileext = ".pdf"),
                    png = tempfile(fileext = ".png"), dpi = 72)
  file.exists(out)
}
#> [1] TRUE TRUE
```
