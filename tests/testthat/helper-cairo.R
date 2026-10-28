# capabilities("cairo") can be TRUE while the cairo devices cannot be loaded
# (macOS without XQuartz), so open one to find out.
skip_without_cairo <- function() {
  ok <- tryCatch({
    f <- tempfile(fileext = ".png")
    grDevices::png(f, type = "cairo", width = 10, height = 10)
    grid::grid.newpage()
    grDevices::dev.off()
    file.exists(f)
  }, error = function(e) FALSE, warning = function(w) FALSE)
  testthat::skip_if_not(ok, "cairo graphics devices are not available")
}
