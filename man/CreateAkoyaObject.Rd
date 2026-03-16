\name{CreateAkoyaObject}
\alias{CreateAkoyaObject}
\title{Create an AkoyaExperiment from Existing Data}
\description{
Constructs an \code{\link{AkoyaExperiment}} from a counts matrix,
coordinate data frame, and optional metadata.
}
\usage{
CreateAkoyaObject(counts, coords, meta_data = NULL,
                  sample_id = "sample1", project = "AkoyaProject")
}
\arguments{
  \item{counts}{Numeric matrix (cells x markers). Row names are optional.}
  \item{coords}{Data frame with columns \code{x} and \code{y}.}
  \item{meta_data}{Data frame of per-cell metadata, or \code{NULL}.}
  \item{sample_id}{Character. Sample identifier. Default \code{"sample1"}.}
  \item{project}{Character. Project name. Default \code{"AkoyaProject"}.}
}
\value{
An \code{\link{AkoyaExperiment}} object.
}
\examples{
counts <- matrix(rnorm(50), nrow = 10,
                 dimnames = list(NULL, c("CD3", "CD8", "CD20", "DAPI", "PanCK")))
coords <- data.frame(x = runif(10, 0, 500), y = runif(10, 0, 500))
obj <- CreateAkoyaObject(counts, coords, sample_id = "mysample")
obj
}
