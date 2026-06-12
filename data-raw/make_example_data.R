# ============================================================================
# data-raw/make_example_data.R
# ----------------------------------------------------------------------------
# Generates `phenoscapR_example`, a small synthetic two-sample SpatialCellData
# object used throughout the examples, tests, and vignettes. The data are
# simulated with realistic spatial niche structure (a B-cell follicle, a T-cell
# zone, an epithelial/tumour region, and scattered macrophages) so that the
# spatial statistics produce meaningful, non-trivial results.
#
# Run from the package root with:
#   Rscript data-raw/make_example_data.R
#
# This script is dev-only; it is listed in .Rbuildignore.
# ============================================================================

devtools::load_all(quiet = TRUE)
set.seed(2024)

markers <- c("CD3", "CD4", "CD8", "CD20", "CD68", "PanCK", "FoxP3", "Ki67")

# Per-phenotype mean marker intensities (log-scale anchors). Rows are
# phenotypes, columns markers; positive markers are elevated.
profiles <- list(
  `T helper`   = c(CD3 = 3.0, CD4 = 2.8, CD8 = 0.2, CD20 = 0.1, CD68 = 0.1,
                   PanCK = 0.1, FoxP3 = 0.2, Ki67 = 0.4),
  `T cytotoxic` = c(CD3 = 3.0, CD4 = 0.2, CD8 = 2.9, CD20 = 0.1, CD68 = 0.1,
                    PanCK = 0.1, FoxP3 = 0.1, Ki67 = 0.5),
  `T reg`      = c(CD3 = 2.8, CD4 = 2.4, CD8 = 0.2, CD20 = 0.1, CD68 = 0.1,
                   PanCK = 0.1, FoxP3 = 2.6, Ki67 = 0.3),
  `B cell`     = c(CD3 = 0.2, CD4 = 0.1, CD8 = 0.1, CD20 = 3.1, CD68 = 0.1,
                   PanCK = 0.1, FoxP3 = 0.1, Ki67 = 0.8),
  Macrophage   = c(CD3 = 0.2, CD4 = 0.3, CD8 = 0.1, CD20 = 0.1, CD68 = 3.0,
                   PanCK = 0.1, FoxP3 = 0.1, Ki67 = 0.2),
  Epithelial   = c(CD3 = 0.1, CD4 = 0.1, CD8 = 0.1, CD20 = 0.1, CD68 = 0.1,
                   PanCK = 3.2, FoxP3 = 0.1, Ki67 = 1.0)
)

# Spatial niche centres and spreads (window is 0-1000 x 0-1000).
niches <- list(
  `B cell`      = list(centre = c(300, 700), sd = 70,  n = 80),
  `T helper`    = list(centre = c(650, 650), sd = 110, n = 55),
  `T cytotoxic` = list(centre = c(700, 600), sd = 120, n = 45),
  `T reg`       = list(centre = c(680, 640), sd = 90,  n = 12),
  Epithelial    = list(centre = c(500, 250), sd = 130, n = 90),
  Macrophage    = list(centre = c(500, 500), sd = 260, n = 38)
)

simulate_sample <- function(sample_id) {
  rows <- lapply(names(niches), function(ph) {
    spec <- niches[[ph]]
    n <- spec$n
    x <- rnorm(n, spec$centre[1], spec$sd)
    y <- rnorm(n, spec$centre[2], spec$sd)
    prof <- profiles[[ph]]
    intens <- vapply(markers, function(m) {
      rlnorm(n, meanlog = prof[[m]], sdlog = 0.35)
    }, numeric(n))
    if (n == 1L) intens <- matrix(intens, nrow = 1L, dimnames = list(NULL, markers))
    list(x = x, y = y, intens = intens, phenotype = rep(ph, n))
  })

  x <- unlist(lapply(rows, `[[`, "x"))
  y <- unlist(lapply(rows, `[[`, "y"))
  intens <- do.call(rbind, lapply(rows, `[[`, "intens"))
  phenotype <- unlist(lapply(rows, `[[`, "phenotype"))

  # Clamp coordinates into the imaging window.
  x <- pmin(pmax(x, 0), 1000)
  y <- pmin(pmax(y, 0), 1000)

  n <- length(x)
  ord <- sample.int(n)  # shuffle so rows are not grouped by phenotype
  list(
    counts = intens[ord, , drop = FALSE],
    coords = data.frame(x = x[ord], y = y[ord]),
    meta = data.frame(
      cell_id   = paste0(sample_id, "_", seq_len(n)),
      sample_id = sample_id,
      cell_area = round(rlnorm(n, log(120), 0.3))[ord],
      phenotype_true = phenotype[ord],
      stringsAsFactors = FALSE
    )
  )
}

a <- simulate_sample("tonsil_A")
b <- simulate_sample("tonsil_B")

counts <- rbind(a$counts, b$counts)
colnames(counts) <- markers
coords <- rbind(a$coords, b$coords)
meta   <- rbind(a$meta, b$meta)

phenoscapR_example <- CreateSpatialObject(
  counts = counts,
  coords = coords,
  meta_data = meta,
  project = "phenoscapR example (tonsil, simulated)"
)

save(phenoscapR_example,
     file = "data/phenoscapR_example.rda",
     compress = "xz")

cat("Wrote data/phenoscapR_example.rda:",
    NCells(phenoscapR_example), "cells,",
    NMarkers(phenoscapR_example), "markers,",
    length(unique(phenoscapR_example$sample_id)), "samples\n")
