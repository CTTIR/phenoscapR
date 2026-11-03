# Launch the phenoscapR Shiny Application

Opens an interactive, Hugo Coder-themed Shiny interface to the package's
analysis functions using the bundled synthetic teaching data: run
quality control, spatial statistics, cellular neighbourhoods, spatial
domains, dimensionality reductions, and differential abundance, and
explore the results with live plots and tables. Simulated phenotypes are
supplied with the example. This app does not import user objects or
export results; use the package functions for those workflows. Each
example section is one sample, so differential-abundance p-values are
not suitable for replicated group inference.

## Usage

``` r
run_app(...)
```

## Arguments

- ...:

  Additional arguments passed to
  [`runApp`](https://rdrr.io/pkg/shiny/man/runApp.html) (e.g.
  `launch.browser`, `port`, `host`).

## Value

Called for its side effect of launching the app; returns the value of
[`runApp`](https://rdrr.io/pkg/shiny/man/runApp.html) invisibly.

## Details

The app ships in `inst/app`. It depends on optional packages (Shiny,
bslib, sass, thematic, reactable, bsicons); `run_app()` checks for them
and reports any that are missing. Branding requires bslib \>= 0.9.0. The
optional UMAP view requires uwot; PCA remains available without it. If
QC removes every cell, widen or reset the cell-area filter.

## Examples

``` r
if (interactive()) {
  run_app()
}
```
