# ============================================================================
# reductions.R -- Dimensionality-reduction embeddings
# ============================================================================
# Computes 2-D (or n-D) embeddings of cells from their marker-expression
# profiles and stores them in the `reductions` slot of a SpatialCellData
# object. PCA (base R) is always available; UMAP (uwot), t-SNE (Rtsne), and
# SONG (songR) are optional backends used only when installed.
# ============================================================================

#' Require an optional package, with an actionable install hint
#' @noRd
.require_pkg <- function(pkg, fn) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    hint <- if (pkg == "songR") {
      "install.packages(\"songR\", repos = \"https://cttir.r-universe.dev\")"
    } else {
      paste0("install.packages(\"", pkg, "\")")
    }
    stop(fn, "() requires the '", pkg, "' package. Install it with ", hint,
         ".", call. = FALSE)
  }
  invisible(TRUE)
}

#' Build the input matrix for a non-linear embedding
#'
#' By convention UMAP/t-SNE/SONG are run on the top principal components rather
#' than the raw markers: this denoises and speeds up the embedding. When
#' \code{use_pca = TRUE} the PCA reduction is computed on demand if absent.
#' @noRd
.embedding_input <- function(object, use_pca, dims, slot, markers) {
  if (use_pca) {
    pca <- object@reductions[["pca"]]
    if (is.null(pca)) {
      object <- RunPCA(object, n_pcs = dims, slot = slot, markers = markers)
      pca <- object@reductions[["pca"]]
    }
    d <- min(dims, ncol(pca))
    return(pca[, seq_len(d), drop = FALSE])
  }
  mat <- methods::slot(object, match.arg(slot, c("data", "counts")))
  if (!is.null(markers)) {
    mat <- mat[, intersect(markers, colnames(mat)), drop = FALSE]
  }
  mat
}

#' Principal Component Analysis
#'
#' Computes a PCA embedding of the marker-expression matrix and stores it in
#' the \code{reductions} slot under the name \code{"pca"}. PCA uses only base R
#' and is always available; it is also the default input space for
#' \code{\link{RunUMAP}}, \code{\link{RunTSNE}}, and \code{\link{RunSONG}}.
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @param n_pcs Integer. Number of principal components to keep. Capped at the
#'   rank of the data. Default \code{30}.
#' @param slot Character. \code{"data"} (default) or \code{"counts"}.
#' @param markers Character vector or \code{NULL}. Markers to use; \code{NULL}
#'   uses all.
#'
#' @return The object with a \code{"pca"} entry in its \code{reductions} slot.
#'
#' @examples
#' counts <- matrix(rnorm(500), nrow = 50,
#'                  dimnames = list(NULL, paste0("M", 1:10)))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- RunPCA(obj, n_pcs = 5)
#' Embeddings(obj, "pca")[1:3, ]
#'
#' @export
#' @importFrom stats prcomp
RunPCA <- function(object, n_pcs = 30L, slot = "data", markers = NULL) {
  mat <- methods::slot(object, match.arg(slot, c("data", "counts")))
  if (!is.null(markers)) {
    mat <- mat[, intersect(markers, colnames(mat)), drop = FALSE]
  }
  if (ncol(mat) < 1L) stop("No markers available for PCA.", call. = FALSE)

  n_pcs <- min(as.integer(n_pcs), ncol(mat), nrow(mat) - 1L)
  pr <- stats::prcomp(mat, center = TRUE, scale. = FALSE)
  emb <- pr$x[, seq_len(n_pcs), drop = FALSE]
  colnames(emb) <- paste0("PC_", seq_len(n_pcs))

  # Retain the model so variance explained and loadings stay queryable.
  total_var <- sum(pr$sdev^2)
  attr(emb, "sdev") <- pr$sdev[seq_len(n_pcs)]
  attr(emb, "percent_var") <- 100 * pr$sdev[seq_len(n_pcs)]^2 / total_var
  attr(emb, "rotation") <- pr$rotation[, seq_len(n_pcs), drop = FALSE]

  object@reductions[["pca"]] <- emb
  object
}

#' Variance Explained by Principal Components
#'
#' Returns the percentage of total variance captured by each principal
#' component from a previously computed PCA reduction.
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @return A named numeric vector of percent-variance-explained per PC.
#'
#' @examples
#' counts <- matrix(rnorm(500), nrow = 50,
#'                  dimnames = list(NULL, paste0("M", 1:10)))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' obj <- RunPCA(CreateSpatialObject(counts, coords), n_pcs = 5)
#' VarianceExplained(obj)
#'
#' @export
VarianceExplained <- function(object) {
  emb <- object@reductions[["pca"]]
  if (is.null(emb)) stop("No PCA reduction. Run RunPCA() first.", call. = FALSE)
  pv <- attr(emb, "percent_var")
  if (is.null(pv)) {
    stop("This PCA was computed by an older version without variance info; ",
         "re-run RunPCA().", call. = FALSE)
  }
  stats::setNames(pv, colnames(emb))
}

#' Scree Plot of PCA Variance
#'
#' Bar-and-line plot of the percent variance explained by each principal
#' component -- the standard tool for choosing how many PCs to retain.
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @param n_pcs Integer or \code{NULL}. Number of PCs to show. Default all.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(500), nrow = 50,
#'                  dimnames = list(NULL, paste0("M", 1:10)))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' obj <- RunPCA(CreateSpatialObject(counts, coords), n_pcs = 8)
#' ScreePlot(obj)
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_col geom_line geom_point labs .data
ScreePlot <- function(object, n_pcs = NULL) {
  pv <- VarianceExplained(object)
  if (!is.null(n_pcs)) pv <- pv[seq_len(min(n_pcs, length(pv)))]
  df <- data.frame(pc = factor(names(pv), levels = names(pv)),
                   percent = as.numeric(pv),
                   idx = seq_along(pv))
  ggplot2::ggplot(df, ggplot2::aes(.data$idx, .data$percent)) +
    ggplot2::geom_col(fill = "#3366cc", alpha = 0.7) +
    ggplot2::geom_line(colour = "grey30") +
    ggplot2::geom_point(colour = "grey30", size = 1.5) +
    ggplot2::scale_x_continuous(breaks = df$idx, labels = df$pc) +
    ggplot2::labs(x = NULL, y = "variance explained (%)",
                  title = "PCA scree plot") +
    ggplot2::theme_minimal(base_size = 11)
}

#' UMAP Embedding
#'
#' Computes a 2-D UMAP embedding via the \pkg{uwot} package and stores it under
#' \code{"umap"}. By default the embedding is computed on the top principal
#' components (see \code{use_pca}).
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @param dims Integer. Number of PCs (or markers) to embed. Default \code{30}.
#' @param use_pca Logical. Embed on PCA space (default \code{TRUE}) or directly
#'   on the marker matrix.
#' @param n_neighbors Integer. UMAP neighbourhood size. Default \code{15}.
#' @param densmap Logical. Use density-preserving densMAP instead of UMAP.
#'   Default \code{FALSE}. Requires a recent \pkg{uwot}.
#' @param slot Character. \code{"data"} (default) or \code{"counts"}.
#' @param markers Character vector or \code{NULL}.
#' @param seed Integer or \code{NULL}. Random seed for reproducibility.
#' @param ... Passed to \code{uwot::umap()} / \code{uwot::densmap()}.
#'
#' @return The object with a \code{"umap"} entry in its \code{reductions} slot.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("uwot", quietly = TRUE)) {
#'   counts <- matrix(rnorm(500), nrow = 50,
#'                    dimnames = list(NULL, paste0("M", 1:10)))
#'   coords <- data.frame(x = runif(50), y = runif(50))
#'   obj <- CreateSpatialObject(counts, coords)
#'   obj <- RunUMAP(obj, seed = 1)
#' }
#' }
#'
#' @export
RunUMAP <- function(object, dims = 30L, use_pca = TRUE, n_neighbors = 15L,
                    densmap = FALSE, slot = "data", markers = NULL,
                    seed = NULL, ...) {
  .require_pkg("uwot", "RunUMAP")
  if (!is.null(seed)) set.seed(seed)

  input <- .embedding_input(object, use_pca, dims, slot, markers)
  nn <- min(as.integer(n_neighbors), nrow(input) - 1L)

  emb <- if (densmap) {
    if (!exists("densmap", where = asNamespace("uwot"))) {
      stop("densmap = TRUE requires a newer version of 'uwot'.", call. = FALSE)
    }
    # Looked up dynamically: older 'uwot' releases do not export densmap(),
    # and a static uwot::densmap reference would fail R CMD check against them.
    densmap_fn <- get("densmap", envir = asNamespace("uwot"))
    densmap_fn(input, n_components = 2L, n_neighbors = nn, verbose = FALSE,
               ...)
  } else {
    uwot::umap(input, n_components = 2L, n_neighbors = nn, verbose = FALSE,
               ...)
  }
  emb <- as.matrix(emb)
  colnames(emb) <- c("UMAP_1", "UMAP_2")

  object@reductions[["umap"]] <- emb
  object
}

#' t-SNE Embedding
#'
#' Computes a 2-D t-SNE embedding via the \pkg{Rtsne} package and stores it
#' under \code{"tsne"}. By default the embedding is computed on the top
#' principal components (see \code{use_pca}).
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @param dims Integer. Number of PCs (or markers) to embed. Default \code{30}.
#' @param use_pca Logical. Embed on PCA space (default \code{TRUE}) or directly
#'   on the marker matrix.
#' @param perplexity Numeric. t-SNE perplexity. Automatically capped at
#'   \code{(n - 1) / 3}. Default \code{30}.
#' @param slot Character. \code{"data"} (default) or \code{"counts"}.
#' @param markers Character vector or \code{NULL}.
#' @param seed Integer or \code{NULL}. Random seed for reproducibility.
#' @param ... Passed to \code{Rtsne::Rtsne()}.
#'
#' @return The object with a \code{"tsne"} entry in its \code{reductions} slot.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("Rtsne", quietly = TRUE)) {
#'   counts <- matrix(rnorm(500), nrow = 50,
#'                    dimnames = list(NULL, paste0("M", 1:10)))
#'   coords <- data.frame(x = runif(50), y = runif(50))
#'   obj <- CreateSpatialObject(counts, coords)
#'   obj <- RunTSNE(obj, seed = 1)
#' }
#' }
#'
#' @export
RunTSNE <- function(object, dims = 30L, use_pca = TRUE, perplexity = 30,
                    slot = "data", markers = NULL, seed = NULL, ...) {
  .require_pkg("Rtsne", "RunTSNE")
  if (!is.null(seed)) set.seed(seed)

  input <- .embedding_input(object, use_pca, dims, slot, markers)
  perp <- min(perplexity, floor((nrow(input) - 1L) / 3))
  if (perp < 1) stop("Too few cells for t-SNE.", call. = FALSE)

  res <- Rtsne::Rtsne(input, dims = 2L, perplexity = perp, pca = FALSE,
                      check_duplicates = FALSE, verbose = FALSE, ...)
  emb <- res$Y
  colnames(emb) <- c("tSNE_1", "tSNE_2")

  object@reductions[["tsne"]] <- emb
  object
}

#' SONG Embedding
#'
#' Computes a 2-D SONG (Self-Organising Nebulous Growths) embedding via the
#' \pkg{songR} package and stores it under \code{"song"}. SONG is incremental,
#' noise-robust, and preserves global structure. By default the embedding is
#' computed on the top principal components (see \code{use_pca}).
#'
#' \pkg{songR} is available from the CTTIR R-universe:
#' \code{install.packages("songR", repos = "https://cttir.r-universe.dev")}.
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @param dims Integer. Number of PCs (or markers) to embed. Default \code{30}.
#' @param use_pca Logical. Embed on PCA space (default \code{TRUE}) or directly
#'   on the marker matrix.
#' @param slot Character. \code{"data"} (default) or \code{"counts"}.
#' @param markers Character vector or \code{NULL}.
#' @param seed Integer or \code{NULL}. Random seed for reproducibility.
#' @param ... Passed to \code{songR::song()}.
#'
#' @return The object with a \code{"song"} entry in its \code{reductions} slot.
#'
#' @examples
#' \donttest{
#' if (requireNamespace("songR", quietly = TRUE)) {
#'   counts <- matrix(rnorm(500), nrow = 50,
#'                    dimnames = list(NULL, paste0("M", 1:10)))
#'   coords <- data.frame(x = runif(50), y = runif(50))
#'   obj <- CreateSpatialObject(counts, coords)
#'   obj <- RunSONG(obj, seed = 1)
#' }
#' }
#'
#' @export
RunSONG <- function(object, dims = 30L, use_pca = TRUE, slot = "data",
                    markers = NULL, seed = NULL, ...) {
  .require_pkg("songR", "RunSONG")

  input <- .embedding_input(object, use_pca, dims, slot, markers)
  args <- list(input, ...)
  if (!is.null(seed)) args$seed <- seed

  fit <- do.call(songR::song, args)
  emb <- fit$embedding
  if (is.null(emb)) {
    stop("songR::song() did not return an 'embedding' element.", call. = FALSE)
  }
  emb <- as.matrix(emb)[, 1:2, drop = FALSE]
  colnames(emb) <- c("SONG_1", "SONG_2")

  object@reductions[["song"]] <- emb
  object
}

# --- Accessors ---------------------------------------------------------------

#' List Available Reductions
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @return Character vector of reduction names.
#' @examples
#' data(phenoscapR_example)
#' Reductions(RunPCA(phenoscapR_example, n_pcs = 5))
#' @export
#' @importFrom methods setGeneric setMethod
setGeneric("Reductions", function(object) standardGeneric("Reductions"))

#' @rdname Reductions
#' @export
setMethod("Reductions", "SpatialCellData", function(object) {
  names(object@reductions)
})

#' Get a Dimensionality-Reduction Embedding
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @param reduction Character. Name of the reduction (e.g. \code{"pca"},
#'   \code{"umap"}).
#' @return A numeric matrix (cells x dimensions).
#' @examples
#' data(phenoscapR_example)
#' Embeddings(RunPCA(phenoscapR_example, n_pcs = 5), "pca")[1:3, ]
#' @export
setGeneric("Embeddings", function(object, reduction = "pca") {
  standardGeneric("Embeddings")
})

#' @rdname Embeddings
#' @export
setMethod("Embeddings", "SpatialCellData", function(object, reduction = "pca") {
  emb <- object@reductions[[reduction]]
  if (is.null(emb)) {
    stop("Reduction '", reduction, "' not found. Available: ",
         if (length(object@reductions) > 0L) {
           paste(names(object@reductions), collapse = ", ")
         } else {
           "none"
         },
         ". Run RunPCA()/RunUMAP()/RunTSNE()/RunSONG() first.", call. = FALSE)
  }
  emb
})

# --- Visualisation -----------------------------------------------------------

#' Plot a Dimensionality-Reduction Embedding
#'
#' Scatter plot of cells in an embedding (PCA, UMAP, t-SNE, or SONG), coloured
#' by a metadata column. Analogous to Seurat's \code{DimPlot}.
#'
#' @param object A \code{\link{SpatialCellData-class}} object.
#' @param reduction Character. Reduction to plot. Default \code{"umap"}.
#' @param colour_by Character. Metadata column for colour. Default
#'   \code{"phenotype"}.
#' @param colours Named character vector or \code{NULL}.
#' @param pt_size Numeric. Point size. Default \code{1}.
#' @param title Character or \code{NULL}.
#' @param dark_theme Logical. Dark background. Default \code{FALSE}.
#'
#' @return A \code{ggplot} object.
#'
#' @examples
#' counts <- matrix(rnorm(500), nrow = 50,
#'                  dimnames = list(NULL, paste0("M", 1:10)))
#' coords <- data.frame(x = runif(50), y = runif(50))
#' obj <- CreateSpatialObject(counts, coords)
#' obj <- RunPCA(obj, n_pcs = 5)
#' obj <- PhenotypeCells(obj, thresholds = list(M1 = 0))
#' EmbeddingPlot(obj, reduction = "pca")
#'
#' @export
#' @importFrom ggplot2 labs
EmbeddingPlot <- function(object, reduction = "umap", colour_by = "phenotype",
                          colours = NULL, pt_size = 1, title = NULL,
                          dark_theme = FALSE) {
  emb <- Embeddings(object, reduction)
  if (!colour_by %in% names(object@meta_data)) {
    stop("Column '", colour_by, "' not found in meta_data.", call. = FALSE)
  }

  df <- data.frame(
    x = emb[, 1L],
    y = emb[, 2L],
    colour = object@meta_data[[colour_by]],
    stringsAsFactors = FALSE
  )

  .cell_map_plot(df, colour_by, colours, pt_size, title, dark_theme) +
    ggplot2::labs(x = colnames(emb)[1L], y = colnames(emb)[2L])
}

#' @rdname EmbeddingPlot
#' @export
DimPlot <- function(object, reduction = "umap", colour_by = "phenotype",
                    colours = NULL, pt_size = 1, title = NULL,
                    dark_theme = FALSE) {
  EmbeddingPlot(object, reduction = reduction, colour_by = colour_by,
                colours = colours, pt_size = pt_size, title = title,
                dark_theme = dark_theme)
}
