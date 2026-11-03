.app_modules_for_test <- function() {
  for (pkg in c("shiny", "reactable", "ggplot2")) skip_if_not_installed(pkg)
  path <- system.file("app", "R", package = "phenoscapR")
  skip_if(!nzchar(path), "app modules unavailable")
  e <- new.env(parent = globalenv())
  for (f in list.files(path, pattern = "[.]R$", full.names = TRUE)) {
    sys.source(f, envir = e)
  }
  e
}

test_that("empty QC is recoverable and does not return stale cells", {
  e <- .app_modules_for_test()
  shiny::testServer(e$mod_data_server, {
    session$setInputs(area = c(20, 1000), norm = "zscore", sample = "S1",
                      colour = "phenotype", feature = "CD3")
    before <- obj()
    expect_gt(nrow(Meta(before)), 0L)
    session$setInputs(area = c(1999, 2000))
    err <- tryCatch(obj(), error = identity)
    expect_s3_class(err, "shiny.silent.error")
    expect_match(conditionMessage(err), "No cells pass.*reset")
    expect_false(session$isClosed())
    session$setInputs(area = c(20, 1000))
    expect_identical(Meta(obj()), Meta(before))
    expect_false(session$isClosed())
  })
})

test_that("missing UMAP is visible and leaves PCA available", {
  e <- .app_modules_for_test()
  # Change only optional-backend availability, never the numerical routines.
  e$requireNamespace <- function(package, quietly = FALSE, ...) {
    if (identical(package, "uwot")) return(FALSE)
    base::requireNamespace(package, quietly = quietly, ...)
  }
  o <- e$.app_example()
  shiny::testServer(e$mod_reductions_server,
                   args = list(obj = shiny::reactive(o)), {
    session$setInputs(npcs = 2, colour = "phenotype", reduction = "pca")
    expect_identical(Reductions(reduced()), "pca")
    session$setInputs(reduction = "umap")
    err <- tryCatch(reduced(), error = identity)
    expect_s3_class(err, "shiny.silent.error")
    expect_match(conditionMessage(err), 'install.packages("uwot")', fixed = TRUE)
    expect_identical(Reductions(pca()), "pca")
    expect_false(session$isClosed())
    session$setInputs(reduction = "pca")
    expect_identical(Reductions(reduced()), "pca")
  })
})

test_that("differential comparison retains actual warnings in visible UI", {
  e <- .app_modules_for_test()
  o <- e$.app_example()
  actual_da <- phenoscapR::DifferentialAbundance
  extra_warning <- "Additional diagnostic warning from abundance backend."
  local_mocked_bindings(DifferentialAbundance = function(...) {
    warning(extra_warning, call. = FALSE)
    actual_da(...)
  }, .package = "phenoscapR")
  shiny::testServer(e$mod_reductions_server,
                   args = list(obj = shiny::reactive(o)), {
    session$setInputs(npcs = 2, colour = "phenotype", reduction = "pca")
    value <- differential()
    expect_gt(nrow(value$data), 0L)
    expect_true(any(grepl("fewer than 2 samples", value$warnings)))
    expect_true(extra_warning %in% value$warnings)
    rendered <- output$diff_warnings$html
    expect_match(rendered, "not replicated group inference")
    expect_match(rendered, "p-values are unreliable", fixed = TRUE)
    expect_match(rendered, extra_warning, fixed = TRUE)
    expect_match(rendered, 'role="alert"', fixed = TRUE)
    expect_gt(nchar(output$diff), 0L)
  })
})

test_that("empty QC propagates through observers without S4 error wrapping", {
  e <- .app_modules_for_test()
  app_server <- function(input, output, session) {
    obj <- e$mod_data_server("data")
    e$mod_spatial_server("spatial", obj)
    e$mod_niches_server("niches", obj)
    e$mod_reductions_server("reductions", obj)
  }
  shiny::testServer(app_server, {
    session$setInputs(`data-area` = c(20, 1000), `data-norm` = "zscore")
    expect_gt(nrow(Meta(obj())), 0L)
    expect_false(session$isClosed())
    session$setInputs(`data-area` = c(1999, 2000))
    expect_false(session$isClosed())
    expect_error(obj(), "No cells pass", class = "shiny.silent.error")
    session$setInputs(`data-area` = c(20, 1000))
    expect_gt(nrow(Meta(obj())), 0L)
    expect_false(session$isClosed())
  })
})
