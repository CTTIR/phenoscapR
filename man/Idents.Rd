\name{Idents}
\alias{Idents}
\alias{Idents,AkoyaExperiment-method}
\title{Get Active Cell Identities}
\description{
Returns the phenotype labels if set, otherwise sample identities.
}
\usage{
Idents(object)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
}
\value{
A character vector.
}
\examples{
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10), y = runif(10))
obj <- CreateAkoyaObject(counts, coords)
Idents(obj)
}
