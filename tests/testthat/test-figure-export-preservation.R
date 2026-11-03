export_test_figure <- function() {
  p <- ggplot2::ggplot(data.frame(x = 1:3, y = c(2, 1, 3)), ggplot2::aes(x, y)) +
    ggplot2::geom_point()
  ComposeFigure(list(FigurePanel(p, c(10, 8, 50, 30))), height_mm = 45, width_mm = 70)
}

export_bytes <- function(path) readBin(path, "raw", n = file.info(path)$size)

export_existing_pair <- function(dir) {
  paths <- c(pdf = file.path(dir, "figure.pdf"), png = file.path(dir, "figure.png"))
  writeBin(charToRaw("previous PDF"), paths[["pdf"]])
  writeBin(charToRaw("previous PNG"), paths[["png"]])
  paths
}

test_that("figure export validates every destination before replacing files", {
  dir <- withr::local_tempdir()
  paths <- export_existing_pair(dir)
  before <- lapply(paths, export_bytes)
  fig <- export_test_figure()
  for (dpi in list(0, -1, Inf, NA_real_, TRUE, c(72, 144))) {
    expect_error(SaveFigure(fig, paths[["pdf"]], paths[["png"]], dpi), "dpi")
    expect_identical(lapply(paths, export_bytes), before)
  }
  expect_error(SaveFigure(fig, paths[["pdf"]], dir), "existing directory")
  expect_error(SaveFigure(fig, paths[["pdf"]], file.path(dir, "absent", "out.png")),
               "existing directory")
  expect_error(SaveFigure(fig, pdf = paths), "one nonempty")
  expect_error(SaveFigure(fig, pdf = NA_character_), "one nonempty")
  expect_error(SaveFigure(fig, pdf = ""), "one nonempty")
  expect_error(SaveFigure(fig, paths[["pdf"]], file.path(dir, ".", "figure.pdf")), "distinct")
  expect_identical(lapply(paths, export_bytes), before)
  expect_setequal(list.files(dir, all.files = TRUE, no.. = TRUE), basename(paths))
})

test_that("real rendering errors preserve previous figures and close devices", {
  skip_without_cairo()
  dir <- withr::local_tempdir()
  paths <- export_existing_pair(dir)
  before <- lapply(paths, export_bytes)
  bad <- ggplot2::ggplot(data.frame(x = 1:3), ggplot2::aes(x, absent_column)) +
    ggplot2::geom_point()
  fig <- ComposeFigure(list(FigurePanel(bad, c(10, 8, 50, 30))), height_mm = 45, width_mm = 70)
  devices <- grDevices::dev.list()
  expect_error(SaveFigure(fig, paths[["pdf"]], paths[["png"]], dpi = 72), "absent_column")
  expect_identical(lapply(paths, export_bytes), before)
  expect_identical(grDevices::dev.list(), devices)
  expect_setequal(list.files(dir, all.files = TRUE, no.. = TRUE), basename(paths))
})

test_that("successful paired exports replace both formats and retain no temporary files", {
  skip_without_cairo()
  dir <- withr::local_tempdir()
  paths <- export_existing_pair(dir)
  out <- SaveFigure(export_test_figure(), paths[["pdf"]], paths[["png"]], dpi = 72)
  expect_identical(out, paths)
  expect_identical(rawToChar(export_bytes(paths[["pdf"]])[1:4]), "%PDF")
  expect_identical(as.integer(export_bytes(paths[["png"]])[1:8]),
                    c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L))
  expect_gt(length(png::readPNG(paths[["png"]])), 1000)
  expect_setequal(list.files(dir, all.files = TRUE, no.. = TRUE), basename(paths))
})

export_publisher_with_failure <- function(failure) {
  publish <- getFromNamespace(".fig_publish_outputs", "phenoscapR")
  context <- new.env(parent = environment(publish))
  context$file.rename <- function(from, to) {
    if (failure(from, to)) return(FALSE)
    base::file.rename(from, to)
  }
  environment(publish) <- context
  publish
}

test_that("failure promoting the second output restores both previous files", {
  dir <- withr::local_tempdir()
  paths <- export_existing_pair(dir)
  before <- lapply(paths, export_bytes)
  staged <- file.path(dir, c("rendered.pdf", "rendered.png"))
  writeBin(charToRaw("new PDF"), staged[1]); writeBin(charToRaw("new PNG"), staged[2])
  publish <- export_publisher_with_failure(function(from, to) identical(unname(from), staged[2]))
  expect_error(publish(staged, paths), "Could not publish")
  expect_identical(lapply(paths, export_bytes), before)
  expect_setequal(list.files(dir, all.files = TRUE, no.. = TRUE), c(basename(paths), basename(staged[2])))
})

test_that("failed paired promotion removes newly created partial output", {
  dir <- withr::local_tempdir()
  paths <- file.path(dir, c("figure.pdf", "figure.png"))
  staged <- file.path(dir, c("rendered.pdf", "rendered.png"))
  writeBin(charToRaw("new PDF"), staged[1]); writeBin(charToRaw("new PNG"), staged[2])
  publish <- export_publisher_with_failure(function(from, to) identical(unname(from), staged[2]))
  expect_error(publish(staged, paths), "Could not publish")
  expect_false(any(file.exists(paths)))
})

test_that("failed restoration retains original bytes and reports their recovery path", {
  dir <- withr::local_tempdir()
  paths <- export_existing_pair(dir)
  before <- lapply(paths, export_bytes)
  staged <- file.path(dir, c("rendered.pdf", "rendered.png"))
  writeBin(charToRaw("new PDF"), staged[1]); writeBin(charToRaw("new PNG"), staged[2])
  publish <- export_publisher_with_failure(function(from, to) identical(unname(to), unname(paths[2])))
  warning <- character()
  expect_error(withCallingHandlers(publish(staged, paths), warning = function(w) {
    warning <<- c(warning, conditionMessage(w)); invokeRestart("muffleWarning")
  }), "Could not publish")
  expect_identical(export_bytes(paths[1]), before[[1]])
  expect_length(warning, 1L)
  recovery <- sub("^.*originals retained at: ", "", warning)
  expect_true(file.exists(recovery))
  expect_identical(export_bytes(recovery), before[[2]])
})

test_that("a warning-only device failure does not draw on or close a caller device", {
  skip_without_cairo()
  dir <- withr::local_tempdir()
  paths <- export_existing_pair(dir)
  before <- lapply(paths, export_bytes)
  grDevices::pdf(file.path(dir, "caller.pdf"))
  caller <- grDevices::dev.cur()
  on.exit(if (caller %in% grDevices::dev.list()) grDevices::dev.off(which = caller), add = TRUE)
  local_mocked_bindings(cairo_pdf = function(...) warning("synthetic device failure"),
                        .package = "grDevices")
  conditions <- character()
  expect_error(withCallingHandlers(
    SaveFigure(export_test_figure(), paths[["pdf"]], paths[["png"]], dpi = 72),
    warning = function(w) {
      conditions <<- c(conditions, conditionMessage(w)); invokeRestart("muffleWarning")
    }), "Could not open figure graphics device")
  expect_identical(conditions, "synthetic device failure")
  expect_identical(grDevices::dev.cur(), caller)
  expect_identical(lapply(paths, export_bytes), before)
})
