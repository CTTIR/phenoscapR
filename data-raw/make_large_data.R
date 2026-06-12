# ============================================================================
# data-raw/make_large_data.R
# ----------------------------------------------------------------------------
# Builds a LARGE, biologically structured synthetic multi-sample
# SpatialCellData (~500k cells) for scalability demonstrations and benchmarking.
# NOT shipped in the package (far too big for CRAN) -- generated on demand.
#
# Tissue model (a solid organ):
#   * CD31+ ENDOTHELIAL cells trace vessel paths -> the spatial ANCHORS.
#   * IMMUNE cells (T helper / cytotoxic / reg, B cells, macrophages) are
#     enriched PERIVASCULARLY (cuffed around vessels), with a scattered minority.
#   * Solid-organ PARENCHYMA (PanCK+ epithelium) forms the bulk, with a few
#     proliferative (Ki67-high) TUMOUR nests.
# This planted structure makes the spatial statistics return meaningful results:
# immune cells sit close to CD31+ vessels, organ parenchyma fills the stroma.
#
#   source("data-raw/make_large_data.R")
#   spe <- make_large_spatial(n_per_sample = 50000L, n_samples = 10L)
# ============================================================================

.markers_large <- c("CD3", "CD4", "CD8", "CD20", "CD68",
                     "FoxP3", "Ki67", "PanCK", "CD31")

# Per-phenotype log-scale marker means. CD31 marks the vessel endothelium.
.profiles_large <- rbind(
  `T helper`    = c(3.0, 2.8, 0.2, 0.1, 0.1, 0.2, 0.4, 0.1, 0.1),
  `T cytotoxic` = c(3.0, 0.2, 2.9, 0.1, 0.1, 0.1, 0.5, 0.1, 0.1),
  `T reg`       = c(2.8, 2.4, 0.2, 0.1, 0.1, 2.6, 0.3, 0.1, 0.1),
  `B cell`      = c(0.2, 0.1, 0.1, 3.1, 0.1, 0.1, 0.8, 0.1, 0.1),
  Macrophage    = c(0.2, 0.3, 0.1, 0.1, 3.0, 0.1, 0.2, 0.1, 0.2),
  Epithelial    = c(0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 1.0, 3.2, 0.1),
  Tumour        = c(0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 2.6, 3.0, 0.1),
  Endothelial   = c(0.1, 0.1, 0.1, 0.1, 0.2, 0.1, 0.6, 0.2, 3.3)
)
colnames(.profiles_large) <- .markers_large

# Target composition of each section (fractions sum to 1).
.composition_large <- c(
  Endothelial   = 0.07,
  `T helper`    = 0.13,
  `T cytotoxic` = 0.10,
  `T reg`       = 0.03,
  `B cell`      = 0.10,
  Macrophage    = 0.17,
  Epithelial    = 0.30,
  Tumour        = 0.10
)

.immune_types <- c("T helper", "T cytotoxic", "T reg", "B cell", "Macrophage")

#' Trace smooth vessel centre-lines across the window.
#' Returns a matrix of anchor points sampled along all vessels.
.make_vessels <- function(n_vessels, window) {
  pts <- vector("list", n_vessels)
  for (k in seq_len(n_vessels)) {
    npath <- 80L
    x0 <- runif(1, 0, window); y0 <- runif(1, 0, window)
    ang <- runif(1, 0, 2 * pi)
    angles <- ang + cumsum(rnorm(npath, 0, 0.18))   # gentle curvature
    step <- (window / npath) * runif(1, 0.8, 1.5)
    px <- x0 + cumsum(cos(angles)) * step
    py <- y0 + cumsum(sin(angles)) * step
    # Reflect back into the window so vessels stay on-tissue.
    px <- window - abs(((px %% (2 * window)) ) - window)
    py <- window - abs(((py %% (2 * window)) ) - window)
    pts[[k]] <- cbind(px, py)
  }
  do.call(rbind, pts)
}

#' Place m cells by jittering around randomly chosen anchor points.
.near_anchors <- function(anchor, m, sd, window) {
  if (m <= 0L) return(matrix(numeric(0), ncol = 2))
  idx <- sample.int(nrow(anchor), m, replace = TRUE)
  xy <- anchor[idx, , drop = FALSE] + matrix(rnorm(2 * m, 0, sd), ncol = 2)
  cbind(pmin(pmax(xy[, 1], 0), window), pmin(pmax(xy[, 2], 0), window))
}

#' Place m cells in a few gaussian nests (used for tumour foci).
.nests <- function(m, window, n_foci = 5L, sd = 90) {
  if (m <= 0L) return(matrix(numeric(0), ncol = 2))
  cx <- runif(n_foci, 0, window); cy <- runif(n_foci, 0, window)
  f <- sample.int(n_foci, m, replace = TRUE)
  xy <- cbind(rnorm(m, cx[f], sd), rnorm(m, cy[f], sd))
  cbind(pmin(pmax(xy[, 1], 0), window), pmin(pmax(xy[, 2], 0), window))
}

#' Simulate one large tissue section (vectorised per phenotype).
simulate_large_sample <- function(sample_id, n, window = 2000,
                                   perivascular = 0.65) {
  anchor <- .make_vessels(n_vessels = max(6L, round(window / 300)), window)

  counts_per <- as.integer(round(n * .composition_large))
  counts_per[1] <- counts_per[1] + (n - sum(counts_per))   # exact total
  names(counts_per) <- names(.composition_large)

  coord_list <- list()
  pheno_list <- list()
  for (ph in names(counts_per)) {
    m <- counts_per[[ph]]
    if (m <= 0L) next
    xy <- if (ph == "Endothelial") {
      .near_anchors(anchor, m, sd = 9, window)               # vessel wall
    } else if (ph %in% .immune_types) {
      n_peri <- round(m * perivascular)
      sd_peri <- if (ph == "B cell") 28 else 45              # tighter B cuffs
      rbind(.near_anchors(anchor, n_peri, sd = sd_peri, window),
            cbind(runif(m - n_peri, 0, window),
                  runif(m - n_peri, 0, window)))             # scattered rest
    } else if (ph == "Tumour") {
      .nests(m, window, n_foci = 6L, sd = 80)
    } else {                                                 # Epithelial bulk
      cbind(runif(m, 0, window), runif(m, 0, window))
    }
    coord_list[[ph]] <- xy
    pheno_list[[ph]] <- rep(ph, m)
  }

  coords <- do.call(rbind, coord_list)
  phenotype <- unlist(pheno_list, use.names = FALSE)
  N <- length(phenotype)

  means <- .profiles_large[phenotype, , drop = FALSE]
  intens <- matrix(
    rlnorm(N * length(.markers_large), meanlog = as.vector(means), sdlog = 0.35),
    nrow = N
  )
  colnames(intens) <- .markers_large

  ord <- sample.int(N)
  list(
    counts = intens[ord, , drop = FALSE],
    coords = data.frame(x = coords[ord, 1], y = coords[ord, 2]),
    meta = data.frame(
      cell_id   = paste0(sample_id, "_", seq_len(N)),
      sample_id = sample_id,
      cell_area = round(rlnorm(N, log(120), 0.3))[ord],
      phenotype_true = phenotype[ord],
      stringsAsFactors = FALSE
    )
  )
}

#' Build a large multi-sample SpatialCellData object (~n_per_sample * n_samples).
make_large_spatial <- function(n_per_sample = 50000L, n_samples = 10L,
                               window = 2000, seed = 2024L) {
  set.seed(seed)
  ids <- sprintf("section_%02d", seq_len(n_samples))
  parts <- lapply(ids, simulate_large_sample, n = n_per_sample, window = window)

  counts <- do.call(rbind, lapply(parts, `[[`, "counts"))
  coords <- do.call(rbind, lapply(parts, `[[`, "coords"))
  meta   <- do.call(rbind, lapply(parts, `[[`, "meta"))

  CreateSpatialObject(
    counts = counts, coords = coords, meta_data = meta,
    project = sprintf("phenoscapR large demo (%s cells, %d sections)",
                      format(nrow(counts), big.mark = ","), n_samples)
  )
}
