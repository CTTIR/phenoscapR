# phenoscapR: Read, Analyse, and Visualise Single-Cell Spatial Biology Data

Tools for importing, processing, analysing, and visualising single-cell
spatial biology data from multiplexed imaging platforms. Supports
cell-table quality control, marker normalisation, phenotype summaries,
spatial neighbourhood statistics such as Ripley's K function (Ripley
(1977)
[doi:10.1111/j.2517-6161.1977.tb01615.x](https://doi.org/10.1111/j.2517-6161.1977.tb01615.x)
) and Moran's I (Moran (1950)
[doi:10.2307/2332142](https://doi.org/10.2307/2332142) ), and explicit
sample and coordinate-frame registries. Patient-level inference
enumerates label allocations for declared contrasts (exact permutation
tests; Pitman (1937)
[doi:10.2307/2984124](https://doi.org/10.2307/2984124) ) and retains
unavailable hypotheses when adjusting for multiple testing. Grouped
summaries expose missingness, eligibility, and denominator provenance.
Optional canonical cell-table import uses 'cellspecR'
<https://github.com/CTTIR/cellspecR>; optional Self-Organising Nebulous
Growths (SONG) embeddings (Senanayake et al. (2021)
[doi:10.1109/TNNLS.2020.3023941](https://doi.org/10.1109/TNNLS.2020.3023941)
) use 'songR' <https://github.com/CTTIR/songR>. Both optional packages
are available from <https://cttir.r-universe.dev>.

## See also

Useful links:

- <https://github.com/CTTIR/phenoscapR>

- <https://cttir.github.io/phenoscapR/>

- Report bugs at <https://github.com/CTTIR/phenoscapR/issues>

## Author

**Maintainer**: R. Heller <raban.heller@uni-ulm.de>
([ORCID](https://orcid.org/0000-0001-8006-9742)) (affiliation: Ulm
University) \[copyright holder\]

Authors:

- R. Heller <raban.heller@uni-ulm.de>
  ([ORCID](https://orcid.org/0000-0001-8006-9742)) (affiliation: Ulm
  University) \[copyright holder\]

- E. Chteinberg ([ORCID](https://orcid.org/0000-0002-9231-9291))
  (affiliation: Ulm University)

- H. Witte ([ORCID](https://orcid.org/0000-0001-5767-7125))
  (affiliation: Ulm University) \[copyright holder\]
