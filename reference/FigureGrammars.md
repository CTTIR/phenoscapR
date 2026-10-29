# Figure Plot Builders Available to Figure Specifications

Names usable in the `grammar` field of a figure specification and the
exported function each one calls.

## Usage

``` r
FigureGrammars()
```

## Value

Named character vector: grammar name to function name.

## See also

[`RenderFigure()`](https://cttir.github.io/phenoscapR/reference/RenderFigure.md)

## Examples

``` r
head(FigureGrammars())
#>      paired_patients      quantile_curves        band_profiles 
#> "PlotPairedPatients" "PlotQuantileCurves"   "PlotBandProfiles" 
#>      interval_forest          group_strip         stacked_bars 
#> "PlotIntervalForest"     "PlotGroupStrip"    "PlotStackedBars" 
```
