\name{[[,AkoyaExperiment-method}
\alias{[[,AkoyaExperiment,ANY,ANY-method}
\alias{[[,AkoyaExperiment-method}
\title{Access Metadata Columns with \code{[[}}
\description{
Access a column from the \code{meta_data} slot of an
\code{\link{AkoyaExperiment}} object using \code{[[}.
}
\usage{
\S4method{[[}{AkoyaExperiment}(x, i)
}
\arguments{
  \item{x}{An \code{\link{AkoyaExperiment}} object.}
  \item{i}{Column name (character).}
}
\value{
The requested metadata column.
}
\examples{
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10), y = runif(10))
obj <- CreateAkoyaObject(counts, coords)
obj[["cell_id"]]
}
