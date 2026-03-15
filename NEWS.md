# phenoscapR 0.1.0

* Initial release.
* S4 class `AkoyaExperiment` for storing Akoya spatial biology data.
* `ReadAkoya()` reads cell segmentation CSV files with auto-detected columns.
* `CreateAkoyaObject()` constructs objects from raw matrices.
* `QCFilter()` for quality control filtering.
* `NormaliseData()` with z-score, min-max, and quantile methods.
* `PhenotypeCells()` and `PhenotypeSummary()` for marker-based phenotyping.
* `FindNeighbours()`, `CellDensity()`, `InteractionMatrix()`,
  `SpatialClusters()` for spatial analysis.
* `CellMap()`, `DensityPlot()`, `MarkerHeatmap()`, `InteractionPlot()`
  for visualisation.
* Accessor methods: `NCells()`, `NMarkers()`, `Markers()`, `Coords()`,
  `Meta()`, `GetData()`, `Idents()`.
* Subsetting with `[`, `[[`, and `$`.
