## Submission

This is a new submission (phenoscapR 1.0.0).

## Test environments

* Local: macOS (aarch64-apple-darwin), R 4.6.1, 14 November 2026:
  full `R CMD check --as-cran` on the built source tarball, including
  PDF manual compilation with TinyTeX (TeX Live 2026) and HTML manual
  validation. This supersedes the earlier local check environment.
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
