\name{AkoyaExperiment-class}
\alias{AkoyaExperiment-class}
\alias{AkoyaExperiment}
\title{The AkoyaExperiment Class}
\description{
Central S4 class for storing and analysing Akoya spatial biology data.
Inspired by the Seurat object design, it holds raw and normalised marker
intensities, spatial coordinates, cell-level metadata, and results from
spatial analyses in a single container.
}
\section{Slots}{
\describe{
  \item{\code{counts}}{Numeric matrix of raw marker intensities (cells x markers).}
  \item{\code{data}}{Numeric matrix of normalised marker intensities
    (cells x markers). Identical to \code{counts} until
    \code{\link{NormaliseData}} is called.}
  \item{\code{coords}}{Data frame with columns \code{x} and \code{y} holding
    spatial coordinates for each cell.}
  \item{\code{meta_data}}{Data frame of per-cell metadata. Always contains
    \code{cell_id} and \code{sample_id}. Additional columns such as
    \code{cell_area}, \code{phenotype}, or \code{cluster} are added by
    analysis functions.}
  \item{\code{project}}{Character string. Project or experiment name.}
  \item{\code{spatial}}{List for storing spatial analysis results (nearest-neighbour
    distances, density values, interaction matrices).}
}
}
\seealso{
\code{\link{CreateAkoyaObject}}, \code{\link{ReadAkoya}}
}
\examples{
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10, 0, 500), y = runif(10, 0, 500))
obj <- CreateAkoyaObject(counts, coords, sample_id = "mysample")
obj
}
