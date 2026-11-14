availability_object <- function() {
 CreateSpatialObject(matrix(1:8,4,2,dimnames=list(NULL,c('m1','m2'))),
  data.frame(x=c(0,1,0,1),y=0),
  data.frame(cell_id=c('q4','q1','q3','q2'),sample_id=c('a','a','b','c'),
             phenotype=c('A','B','C','C'),neighbourhood_status='user_value'))
}

test_that('singleton cells remain present but do not dilute composition centers', {
 o<-availability_object();before<-o
 out<-CellularNeighbourhoods(o,1,k=20,seed=1)
 expect_equal(out@spatial$neighbourhood_composition,
              matrix(c(.5,.5,0),1,dimnames=list('CN1',c('A','B','C'))))
 expect_identical(out$neighbourhood,c('CN1','CN1',NA_character_,NA_character_))
 expect_identical(out$cell_id,o$cell_id)
 expect_identical(out$sample_id,o$sample_id)
 expect_identical(out@counts,o@counts)
 expect_identical(out$neighbourhood_status,o$neighbourhood_status)
 expect_identical(o,before)
 a<-out@spatial$neighbourhood_availability
 expect_identical(a$per_cell$cell_id,o$cell_id)
 expect_identical(a$per_cell$row_index,1:4)
 expect_identical(a$per_cell$status,c('defined','defined','no_neighbors','no_neighbors'))
 expect_equal(a$by_sample,data.frame(sample_id=c('a','b','c'),n_total=c(2L,1L,1L),
                                    n_defined=c(2L,0L,0L),n_unavailable=c(0L,1L,1L)))
 expect_identical(a$weighting,'cell')
 # Plotting preserves unavailable points rather than discarding cell rows.
 p<-ggplot2::ggplot_build(CellMap(out,colour_by='neighbourhood'))
 expect_equal(nrow(p$data[[1]]),4)
 expect_true(all(is.finite(p$data[[1]]$x)))
})

test_that('all-singleton and empty inputs have typed unavailable output without RNG use', {
 o<-availability_object();o@meta_data$sample_id<-letters[1:4]
 for (x in list(o,o[FALSE,])) {
  set.seed(25);before<-.Random.seed
  out<-CellularNeighbourhoods(x,n_neighbourhoods=8,k=20,seed=1)
  expect_identical(.Random.seed,before)
  expect_identical(out$cell_id,x$cell_id)
  expect_identical(out$neighbourhood,rep(NA_character_,NCells(x)))
  cc<-out@spatial$neighbourhood_composition
  expect_equal(dim(cc),c(0L,length(unique(x$phenotype))))
  a<-out@spatial$neighbourhood_availability
  expect_identical(a$per_cell$status,rep('no_neighbors',NCells(x)))
  expect_type(a$per_cell$status,'character')
  expect_type(a$by_sample$n_defined,'integer')
  expect_true(all(a$by_sample$n_defined==0))
  if (NCells(x)) {
   map <- ggplot2::ggplot_build(CellMap(out,colour_by='neighbourhood'))
   expect_equal(nrow(map$data[[1]]),NCells(x))
   expect_true(all(is.finite(map$data[[1]]$x)))
  }
 }
})

test_that('unachievable center counts fail before random draws', {
 o<-availability_object();o@meta_data$phenotype<-rep('A',4)
 set.seed(26);before<-.Random.seed
 expect_error(CellularNeighbourhoods(o,2,k=1,seed=1),'distinct defined composition')
 expect_identical(.Random.seed,before)
 expect_equal(unname(CellularNeighbourhoods(o,1,k=1,seed=1)@spatial$neighbourhood_composition),matrix(1,1,1))
})

test_that('availability follows input order and cache invalidation', {
 o<-availability_object();idx<-c(3L,2L,4L,1L);o<-o[idx,]
 out<-CellularNeighbourhoods(o,1,k=1,seed=1)
 expect_identical(out@spatial$neighbourhood_availability$per_cell$cell_id,o$cell_id)
 expect_identical(is.na(out$neighbourhood),c(TRUE,FALSE,TRUE,FALSE))
 expect_length(out[1:2,]@spatial,0)
})

test_that('the niche app explains unavailable compositions', {
 skip_if_not_installed('shiny')
 path<-system.file('app','R','mod_niches.R',package='phenoscapR')
 if(!nzchar(path))path<-file.path('..','..','inst','app','R','mod_niches.R')
 module<-new.env(parent=globalenv());sys.source(path,envir=module)
 o<-availability_object();o@meta_data$sample_id<-letters[1:4]
 shiny::testServer(module$mod_niches_server,args=list(obj=shiny::reactive(o)),{
  session$setInputs(n_cn=3,k=5,n_dom=2,section='a')
  expect_error(output$composition,'No neighbourhood compositions are available',class='shiny.silent.error')
 })
})
