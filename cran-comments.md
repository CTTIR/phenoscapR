## Local check result

phenoscapR 0.1.1 was checked on 25 October 2026 using R 4.6.1 on Ubuntu
26.04 LTS (x86_64-pc-linux-gnu).

Source archive SHA-256:
`6cb6b0753b4132a808cc016968da0dba42fb5df6ad63d21318e916c25597f185`

`R CMD check --as-cran` completed with **0 errors, 0 warnings and 2 NOTEs**.
Examples, tests, vignette rebuilding, and the PDF and HTML manuals passed.
The check used `_R_CHECK_FORCE_SUGGESTS_=false`,
`PHENOSCAPR_TEST_SONG=false` and `R_TEXI2DVICMD=emulation`.

## Incoming feasibility NOTE

This is a new submission. The optional Suggested packages cellspecR and songR
are available from https://github.com/CTTIR/cellspecR and
https://github.com/CTTIR/songR, as documented in Description. Their use is
conditional; the package does not install or download them automatically.

songR was unavailable during the package check. The live SONG numerical test
was also explicitly disabled; this check does not qualify that optional backend.
A separate check of the same installed archive made both cellspecR and songR
unavailable and verified informative FromCellspec()/RunSONG() refusals, along
with patient-level exact inference, declared-family adjustment and PCA smoke
cases. It preserved the supplied inputs and used no namespace mocking.

## Foreign-function NOTE

Static checking cannot evaluate `target[[.NAME]]` and `backend$master` outside
their runtime contexts in two `.Fortran` calls. Both expressions hold registered
`NativeSymbolInfo` objects selected by the exact Delaunay adapter. Before dispatch,
the adapter checks routine names, argument counts, DLL identity and library
containment, and requires dynamic lookup to be disabled. It uses local function
copies without modifying the installed dependency namespace.

The supported backend profile is deldir 2.0-4; unsupported profiles are refused.
The registration diagnostic is retained and explained rather than suppressed.
