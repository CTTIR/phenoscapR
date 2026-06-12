# ============================================================================
# data-raw/benchmark.R
# ----------------------------------------------------------------------------
# Micro-benchmark harness for the spatial-search engine. Times the core
# neighbour-based statistics at increasing cell counts to demonstrate the
# kd-tree wins and to guard against performance regressions. Dev-only;
# Rbuildignored with the rest of data-raw/.
#
# Run with:  Rscript data-raw/benchmark.R
# ============================================================================

devtools::load_all(quiet = TRUE)

sim <- function(n, seed = 1L) {
  set.seed(seed)
  counts <- matrix(rlnorm(2 * n), nrow = n,
                   dimnames = list(NULL, c("CD3", "CD8")))
  coords <- data.frame(x = runif(n, 0, 1000), y = runif(n, 0, 1000))
  meta <- data.frame(cell_id = seq_len(n), sample_id = "s1",
                     phenotype = sample(c("A", "B", "C"), n, replace = TRUE))
  CreateSpatialObject(counts, coords, meta)
}

timeit <- function(expr) {
  t <- system.time(force(expr))[["elapsed"]]
  round(t, 3)
}

sizes <- c(1000L, 5000L, 20000L)
cat(sprintf("%8s %12s %12s %14s %10s\n",
            "n", "density", "interaction", "enrichment", "ripleysK"))
for (n in sizes) {
  obj <- sim(n)
  t_den <- timeit(CellDensity(obj, radius = 30))
  t_int <- timeit(InteractionMatrix(obj, radius = 30))
  t_enr <- timeit(NeighbourhoodEnrichment(obj, radius = 30, n_perm = 50L))
  t_rip <- timeit(RipleysK(obj, r_seq = seq(0, 100, length.out = 25)))
  cat(sprintf("%8d %12.3f %12.3f %14.3f %10.3f\n",
              n, t_den, t_int, t_enr, t_rip))
}
