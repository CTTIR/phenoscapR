# Marked controls run on every locale; native UTF-8 cases require that locale.
key_sort_text <- function(code, native = FALSE) {
  value <- intToUtf8(code)
  if (native) Encoding(value) <- "unknown"
  value
}
key_sort_marked <- function(x) {
  if (is.data.frame(x)) {
    x[] <- lapply(x, key_sort_marked)
    return(x)
  }
  if (is.list(x)) return(lapply(x, key_sort_marked))
  if (is.character(x)) return(enc2utf8(x))
  x
}

test_that("edge sorting accepts mixed native keys without changing counts or fields", {
  fixture <- function(native) {
    g <- key_sort_text(945, native); f <- key_sort_text(946, native)
    ids <- c(key_sort_text(947, native), key_sort_text(948))
    list(nodes = data.frame(g=c(g,enc2utf8(g)), f=f, id=ids,
      src=c(TRUE,FALSE), tgt=c(FALSE,TRUE)),
      edges=data.frame(g=g,f=f,a=ids[1],b=ids[2]),
      registry=data.frame(g=c(g,"empty"),f=f,
        geometry_source="supplied_edges",geometry_reference="synthetic"))
  }
  run <- function(z) CountDisjointEdges(z$nodes,z$edges,z$registry,
    "g","f","id","a","b","src","tgt")
  expected <- run(fixture(FALSE))
  expect_equal(expected$n_cross_edges,c(0,1))
  expect_equal(expected$source_contact_fraction,c(NA,1))
  skip_if_not(l10n_info()[["UTF-8"]], "native UTF-8 keys require a UTF-8 locale")
  z <- fixture(TRUE); before <- serialize(z,NULL); got <- run(z)
  expect_identical(key_sort_marked(got),expected)
  expect_identical(Encoding(got$g),c("unknown","unknown"))
  expect_identical(Encoding(got$f),rep("unknown",2))
  expect_identical(serialize(z,NULL),before)
})

test_that("overlap sorting accepts native groups strata and IDs with marked controls", {
  fixture <- function(native) {
    g <- key_sort_text(945,native); s <- key_sort_text(946,native)
    data.frame(g=c(g,enc2utf8(g)),s=s,
      id=c(key_sort_text(947,native),key_sort_text(948)),positive=c(TRUE,FALSE),value=c(8,2))
  }
  run <- function(d) ContrastGroupedOverlap(d,data.frame(g=c(d$g[1],"empty")),
    "g","s","id","positive","value")
  expected <- run(fixture(FALSE))
  expect_equal(expected$summary$contrast,c(NA,6))
  expect_equal(expected$summary$control_effective_n,c(NA,1))
  expect_equal(expected$observations$weight,c(1,1))
  skip_if_not(l10n_info()[["UTF-8"]], "native UTF-8 keys require a UTF-8 locale")
  d <- fixture(TRUE); before <- serialize(d,NULL); got <- run(d)
  expect_identical(key_sort_marked(got),expected)
  expect_identical(Encoding(got$observations$g),Encoding(d$g))
  expect_identical(Encoding(got$observations$id),Encoding(d$id))
  expect_identical(Encoding(got$strata$s),"unknown")
  expect_identical(serialize(d,NULL),before)
})

test_that("exact inference native patient sorting preserves literal allocation results", {
  fixture <- function(native) {
    ids <- c(key_sort_text(945,native),key_sort_text(946),"c","d")
    endpoint <- key_sort_text(947,native); contrast <- key_sort_text(948,native)
    list(endpoints=data.frame(endpoint_id=endpoint,patient_id=ids,value=1:4,eligible=TRUE),
      design=data.frame(contrast_id=contrast,patient_id=ids,group=c("A","A","B","B")),
      hypotheses=data.frame(hypothesis_id=key_sort_text(949,native),endpoint_id=endpoint,
        contrast_id=contrast,family_id=key_sort_text(950,native)))
  }
  expected <- do.call(ExactPatientTests,fixture(FALSE))
  expect_equal(expected$mean_difference,-2)
  expect_equal(expected$p_value,1/3)
  expect_equal(expected$allocations,6)
  skip_if_not(l10n_info()[["UTF-8"]], "native UTF-8 keys require a UTF-8 locale")
  z <- fixture(TRUE); before <- serialize(z,NULL); got <- do.call(ExactPatientTests,z)
  expect_identical(key_sort_marked(got),expected)
  for(nm in names(z$hypotheses)) expect_identical(Encoding(got[[nm]]),Encoding(z$hypotheses[[nm]]))
  expect_identical(serialize(z,NULL),before)
  z$endpoints <- z$endpoints[4:1,]; z$design <- z$design[c(3,1,4,2),]
  expect_identical(do.call(ExactPatientTests,z),got)
})
