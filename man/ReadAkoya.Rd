\name{ReadAkoya}
\alias{ReadAkoya}
\title{Read Akoya Cell Segmentation Data}
\description{
Reads cell segmentation CSV files produced by Akoya Biosciences platforms
(PhenoCycler, CODEX, PhenoImager) and returns an
\code{\link{AkoyaExperiment}} object. Column names are auto-detected and
standardised.
}
\usage{
ReadAkoya(path, sample_id = NULL, markers = NULL, project = "AkoyaProject")
}
\arguments{
  \item{path}{Character. Path to a CSV file or a directory containing CSV
    files. When a directory is given, all \code{.csv} files are read and
    combined into a single object.}
  \item{sample_id}{Character or \code{NULL}. An identifier for the sample.
    When \code{path} is a directory and \code{sample_id} is \code{NULL}, the
    file name (without extension) is used.}
  \item{markers}{Character vector or \code{NULL}. If provided, only these
    marker columns are retained. Matching is case-insensitive.}
  \item{project}{Character. Project name stored in the object. Default
    \code{"AkoyaProject"}.}
}
\value{
An \code{\link{AkoyaExperiment}} object.
}
\examples{
# Create a temporary example file
tmp <- tempfile(fileext = ".csv")
write.csv(data.frame(
  `Cell ID` = 1:5,
  `Cell X Position` = runif(5, 0, 1000),
  `Cell Y Position` = runif(5, 0, 1000),
  `Cell Area (px)` = runif(5, 50, 200),
  DAPI = rnorm(5, 500, 100),
  CD3 = rnorm(5, 300, 80),
  check.names = FALSE
), tmp, row.names = FALSE)
obj <- ReadAkoya(tmp)
obj
unlink(tmp)
}
