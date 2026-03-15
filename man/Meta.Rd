\name{Meta}
\alias{Meta}
\alias{Meta,AkoyaExperiment-method}
\title{Get or Set Cell Metadata}
\description{
Returns the cell metadata data frame from an \code{\link{AkoyaExperiment}} object.
}
\usage{
Meta(object)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
}
\value{
Data frame of cell metadata.
}
\examples{
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10), y = runif(10))
obj <- CreateAkoyaObject(counts, coords)
Meta(obj)
}
