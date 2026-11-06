## Submission

This is the first submission of phenoscapR (version 1.0.0).

## Test environments

* Local: Ubuntu 26.04 LTS, R 4.6.1 (x86_64-pc-linux-gnu), with all suggested
  packages installed, vignettes rebuilt and PDF and HTML manuals checked.
* Local: the same environment with `_R_CHECK_DEPENDS_ONLY_=true`.
* GitHub Actions: ubuntu-latest (R devel, release, oldrel-1 and oldrel-3),
  macOS-latest (release) and windows-latest (release).

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

* Suggests or Enhances not in mainstream repositories: cellspecR, songR.
  Both are available from the repository declared in
  `Additional_repositories` (<https://cttir.r-universe.dev>). They are used
  only conditionally: examples, tests and vignettes check for them with
  `requireNamespace()` or `skip_if_not_installed()`, and the package works
  without them.

## Examples

The example of `RunSONG()` is in `\dontrun{}`: it needs the optional 'songR'
package, whose compiled code does not run on every platform.
