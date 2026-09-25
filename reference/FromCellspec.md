# Import a Canonical Cell Table Without Losing Spatial Identity

Converts a validated cellspecR object to a SpatialCellData object. Each
image is an independent coordinate frame: output sample_id is image_id,
while source_sample_id preserves the original biological sample
identifier. Cell identifiers remain unchanged and are unique jointly
with image_id. Coordinates remain in micrometres and area remains in
square micrometres; calibration is validated but is not applied a second
time.

## Usage

``` r
FromCellspec(x, features = NULL, project = "SpatialProject")
```

## Arguments

- x:

  A structurally valid cellspec object. Requires cellspecR.

- features:

  Unique ordered feature identifiers, or NULL for all features.

- project:

  Character scalar naming the project.

## Value

A SpatialCellData object with unchanged selected measurements and
explicit image-local sample IDs. Read provenance via attr(Meta(object),
"cellspec_import").

## Details

Feature identifiers retain their complete compartment/marker/statistic
names. No marker guessing, normalisation, filtering, imputation or
removal of all-NA features occurs. Functions requiring complete
intensities need an explicit downstream missing-feature policy. Existing
phenotype metadata is preserved; import does not verify or authorize
review decisions.

The metadata attribute cellspec_import holds an original-import snapshot
of dictionary, image/channel tables, input provenance, adjacency and raw
feature support. Its scope remains original_import after subsetting:
adjacency and support in this snapshot are not current subset results or
active graphs. No reviewed tissue window or observation area is inferred
from cell centroids.

## Examples

``` r
if (requireNamespace("cellspecR", quietly = TRUE)) {
  object <- FromCellspec(cellspecR::cs_example())
  Coords(object)
}
#>            x          y
#> 1  355.88666 441.653955
#> 2  331.04879 479.922468
#> 3  113.79383 270.560933
#> 4  108.91662 120.103228
#> 5  399.63199 455.578378
#> 6  235.48707  88.792773
#> 7   30.63910  84.382323
#> 8  115.79331  41.903383
#> 9  111.04847 498.561782
#> 10 443.33209 204.531792
#> 11  63.83051 158.410671
#> 12 369.28911  69.231511
#> 13 160.59729 223.686777
#> 14 337.65402 237.042872
#> 15 438.98723 238.126500
#> 16 227.04382 184.962629
#> 17 148.81347 316.637915
#> 18 382.95146 402.372202
#> 19 419.86656 298.154834
#> 20 379.69573  37.901575
#> 21 504.54198 105.357748
#> 22 256.78480 426.199606
#> 23 459.42655 132.548805
#> 24 375.67208  45.530207
#> 25 317.15023  20.589407
#> 26 243.06165 112.666603
#> 27 504.86050 260.318278
#> 28  51.76572 470.341155
#> 29  33.10549 167.437353
#> 30 400.61824 402.299043
#> 31  58.25211 506.923989
#> 32 246.94103 171.637419
#> 33  22.49848  51.181707
#> 34 143.58264 106.386964
#> 35  67.73099 175.354168
#> 36 409.50060 364.938241
#> 37 309.11944 375.076342
#> 38  39.96489 129.297991
#> 39 193.73812 101.869517
#> 40 453.12295 508.739060
#> 41 305.48934  19.215617
#> 42 205.58355  47.404693
#> 43 180.71732 363.315786
#> 44  44.24748 147.464659
#> 45  76.99758 314.911881
#> 46 344.05651 231.648778
#> 47 460.34162 483.730739
#> 48 432.30179  87.615812
#> 49  61.88860 409.140947
#> 50  61.91354  92.705406
#> 51  63.76230  23.011496
#> 52 202.95994 457.558693
#> 53 152.41825 189.893602
#> 54 474.87805 334.422214
#> 55 485.92224 122.520020
#> 56 245.21624  34.677971
#> 57 411.13283 291.581885
#> 58  75.91856 209.612095
#> 59 415.83062 313.052063
#> 60 249.48752   1.151986
#> 61 125.82327 201.077835
#> 62 386.60053 408.107650
#> 63  17.14609 149.092316
#> 64 135.85373 429.410044
#> 65 454.50598 381.776758
#> 66 243.42274  39.384242
#> 67 185.46476 359.733375
#> 68 433.08866 437.902848
#> 69 371.58388 481.954068
#> 70 494.75301 500.004281
#> 71 360.22826  27.384330
#> 72 383.42821 345.279549
#> 73 101.26995 416.264867
#> 74  51.60705 464.755903
#> 75 439.61898 236.476408
#> 76 370.87842 322.995138
#> 77 325.02764 255.241072
#> 78 359.20022 266.015047
#> 79  58.17887 120.002275
#> 80  21.25140  12.475787
```
