\name{show,AkoyaExperiment-method}
\alias{show,AkoyaExperiment-method}
\title{Show an AkoyaExperiment}
\description{
Display a summary of an \code{\link{AkoyaExperiment}} object, including
the number of cells, samples, markers, normalisation status, phenotypes,
and spatial results.
}
\usage{
\S4method{show}{AkoyaExperiment}(object)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
}
\examples{
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10), y = runif(10))
obj <- CreateAkoyaObject(counts, coords)
obj
}
