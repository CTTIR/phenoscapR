# Launch the phenoscapR Shiny Application

Opens an interactive, Hugo Coder-themed Shiny interface to the package's
analysis functions: load the bundled example data (or your own object),
run quality control, phenotyping, spatial statistics, cellular
neighbourhoods, spatial domains, dimensionality reductions, and
differential abundance, and explore the results with live plots and
tables.

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
and reports any that are missing.

## Examples

``` r
if (FALSE) { # \dontrun{
run_app()
} # }
```
