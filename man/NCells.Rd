\name{NCells}
\alias{NCells}
\alias{NCells,AkoyaExperiment-method}
\title{Get the Number of Cells}
\description{
Returns the number of cells in an \code{\link{AkoyaExperiment}} object.
}
\usage{
NCells(object)
}
\arguments{
  \item{object}{An \code{\link{AkoyaExperiment}} object.}
}
\value{
Integer.
}
\examples{
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10), y = runif(10))
obj <- CreateAkoyaObject(counts, coords)
NCells(obj)
}
