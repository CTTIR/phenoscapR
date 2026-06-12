## R CMD check results

0 errors | 0 warnings | 1 note

## Test environments

* Windows 11 x64, R 4.5.2 (local)
* GitHub Actions: ubuntu-latest (R devel, release, oldrel-1), macOS-latest (release), windows-latest (release)
* win-builder (R-devel)

## Notes

* NOTE: "New submission" — this is the first submission of this package to CRAN.

* NOTE: "Found the following (possibly) invalid URLs" — the GitHub repository
  (https://github.com/cttir/phenoscapR) and pkgdown site
  (https://cttir.github.io/phenoscapR/) may return 404 during local checking
  if the pkgdown site has not yet been published. These URLs resolve correctly
  once the site is built and deployed via GitHub Actions.

* NOTE: "Suggests or Enhances not in mainstream repositories: songR" — songR is
  an optional add-on (used only by the optional RunSONG() embedding) and is
  distributed via the maintainer's R-universe, declared in
  Additional_repositories. All functionality that depends on it is guarded with
  requireNamespace() and skipped gracefully when it is absent, so the package
  installs, checks, and runs fully without it.

## Downstream dependencies

This is a new package with no downstream dependencies.
