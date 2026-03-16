\name{[,AkoyaExperiment-method}
\alias{[,AkoyaExperiment-method}
\alias{[,AkoyaExperiment,ANY,ANY,ANY-method}
\title{Subset an AkoyaExperiment}
\description{
Subset an \code{\link{AkoyaExperiment}} object by cell indices (rows)
and/or marker indices (columns).
}
\usage{
\S4method{[}{AkoyaExperiment}(x, i, j, drop = FALSE)
}
\arguments{
  \item{x}{An \code{\link{AkoyaExperiment}} object.}
  \item{i}{Cell indices (integer or logical).}
  \item{j}{Marker indices (integer, logical, or character).}
  \item{drop}{Ignored.}
}
\value{
A subsetted \code{\link{AkoyaExperiment}}.
}
\examples{
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10), y = runif(10))
obj <- CreateAkoyaObject(counts, coords)
obj_sub <- obj[1:5, c("CD3", "CD8")]
dim(obj_sub)
}
