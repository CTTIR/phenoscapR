# run_app(): dependency checking, app-directory location, and dispatch to
# shiny::runApp(). The launch itself is mocked so the test stays headless and
# fast; the real headed launch is covered by test-app.R.
#
# requireNamespace() and the shiny::runApp() dispatch are mocked through
# bindings in the phenoscapR namespace; no other namespace is touched.

test_that("run_app() errors listing every missing optional package", {
  local_mocked_bindings(requireNamespace = function(...) FALSE)
  expect_error(run_app(), "run_app\\(\\) needs these packages")
  expect_error(run_app(), "shiny")
  expect_error(run_app(), "install\\.packages")
})

test_that("run_app() errors when only some packages are missing", {
  local_mocked_bindings(
    requireNamespace = function(package, ...) !identical(package, "bsicons")
  )
  err <- expect_error(run_app(), "needs these packages")
  expect_match(conditionMessage(err), "bsicons")
})

test_that("run_app() dispatches to shiny::runApp with the bundled app dir", {
  app_dir <- system.file("app", package = "phenoscapR")
  skip_if(!nzchar(app_dir), "app directory not installed")

  local_mocked_bindings(requireNamespace = function(...) TRUE)
  seen <- NULL
  local_mocked_bindings(
    .run_shiny_app = function(app_dir, ...) {
      seen <<- app_dir
      invisible("launched")
    }
  )
  expect_identical(run_app(), "launched")
  expect_identical(seen, app_dir)
  expect_true(dir.exists(seen))
})
