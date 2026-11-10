## Submission

This is a new submission (phenoscapR 1.0.0).

## Test environments

* local macOS (aarch64-apple-darwin), R 4.6.1, with all suggested packages
  installed (cellspecR 1.2.0 and songR 1.0.0 from the CTTIR R-universe):
  `R CMD check --as-cran --no-manual` on the built tarball. LaTeX is not
  installed on this machine, so the PDF manual was not built locally.
* GitHub Actions (r-lib/actions v2, `--as-cran`):
  * macos-latest (R release)
  * windows-latest (R release)
  * ubuntu-latest (R devel, release, oldrel-1)

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'R. Heller <raban.heller@uni-ulm.de>'
  New submission
  Suggests or Enhances not in mainstream repositories:
    cellspecR, songR
  Availability using Additional_repositories specification:
    cellspecR   yes   https://cttir.r-universe.dev
    songR       yes   https://cttir.r-universe.dev

  This is the first submission of this package. cellspecR and songR are
  optional: they are available from the repository declared in
  `Additional_repositories` and are used only conditionally. Examples, tests
  and vignettes check for them with `requireNamespace()` or
  `skip_if_not_installed()`, and the package works without them.

## Additional notes

* Examples longer than a few seconds are wrapped in `\donttest{}`; the
  `RunSONG()` example additionally runs only when the optional 'songR'
  package is installed.
* Examples, tests and vignettes use small synthetic data, write only to
  `tempdir()` and do not access the network. Browser-based app tests
  ('shinytest2'/'chromote') are skipped on CRAN.

## Downstream dependencies

There are currently no downstream dependencies on CRAN.
