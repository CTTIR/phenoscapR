\name{SetPalette}
\alias{SetPalette}
\alias{GetPalette}
\title{Set or Get the Default Colour Palette}
\description{
Sets or retrieves the global colour palette used by all plotting functions
in phenoscapR. The palette can be a viridis option, a custom gradient
defined by 2-3 anchor colours, or a named vector of discrete colours.
}
\usage{
SetPalette(palette)

GetPalette()
}
\arguments{
  \item{palette}{Character or named character vector. Either:
    \itemize{
      \item A viridis palette name: \code{"viridis"}, \code{"magma"},
        \code{"inferno"}, \code{"plasma"}, \code{"cividis"},
        \code{"rocket"}, \code{"mako"}, \code{"turbo"}.
      \item A character vector of 2-3 hex colours for a custom gradient
        (e.g. \code{c("#440154", "#21918c", "#fde725")}).
      \item \code{NULL} to return the current palette without changing it.
    }
  }
}
\value{
\code{SetPalette} invisibly returns the previous palette setting.
\code{GetPalette} returns the current palette setting (a character string
or vector).
}
\examples{
SetPalette("magma")
GetPalette()

# Custom 3-colour gradient
SetPalette(c("navy", "white", "firebrick"))
GetPalette()

# Reset to default
SetPalette("viridis")
}
