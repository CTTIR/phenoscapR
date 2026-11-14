contract_object <- function() {
  CreateSpatialObject(matrix(c(1,2,4,8), ncol=1, dimnames=list(NULL,'m')),
    data.frame(x=c(0,1,3,4),y=0),
    data.frame(cell_id=letters[1:4],sample_id='s',phenotype=c('A','B','A','B')))
}

test_that('neighborhood controls and malformed labels fail before RNG changes', {
  o <- contract_object()
  for (bad in list(0,-1,1.9,NA_real_,Inf,c(1,2),matrix(1),1+1i)) {
    set.seed(31); before <- .Random.seed
    expect_error(CellularNeighbourhoods(o,1,k=bad,seed=2),'k must')
    expect_error(SpatialDomains(o,1,k=bad,seed=2),'k must')
    expect_identical(.Random.seed,before)
  }
  for (bad in list(c('s','s',NA,'s'),rep('',4),matrix(rep('s',4)))) {
    x <- o;x@meta_data$sample_id<-bad
    expect_error(CellularNeighbourhoods(x,1,k=1),'sample_id')
    expect_error(SpatialDomains(x,1,k=1),'sample_id')
    expect_error(MoransI(x,'m',2),'sample_id')
  }
  for (bad in list(c('A','B',NA,'A'),rep('',4),matrix(c('A','B','A','B')))) {
    x<-o;x@meta_data$phenotype<-bad
    expect_error(CellularNeighbourhoods(x,1,k=1),'Phenotypes')
  }
  expect_error(CellularNeighbourhoods(o,1.5,k=1),'n_neighbourhoods')
  expect_error(SpatialDomains(o,1.5,k=1),'n_domains')
  expect_error(CellularNeighbourhoods(o,1,k=1,seed=1.5),'seed')
})

test_that('Moran requires numeric measurements and defined IDW distances', {
  o<-contract_object()
  for (bad in list(factor(c('low','high','low','high')),as.character(1:4),
                  c(1,2,NA,4),c(1,2,Inf,4),matrix(1:4),rep(1+1i,4))) {
    x<-o;x@meta_data$measurement<-bad
    set.seed(32);before<-.Random.seed
    expect_error(MoransI(x,'measurement',2,n_perm=9,seed=2),'finite real numeric vector')
    expect_identical(.Random.seed,before)
  }
  o@coords$x<-c(0,0,3,4)
  set.seed(33);before<-.Random.seed
  expect_error(MoransI(o,'m',2,weights='idw',n_perm=9,seed=2),'positive distances')
  expect_identical(.Random.seed,before)
  expect_true(is.finite(MoransI(o,'m',2)$I))
})

test_that('Moran validates controls before random draws', {
  o<-contract_object()
  for (bad in list(-1,NA_real_,Inf,c(1,2),matrix(1),1+1i)) {
    expect_error(MoransI(o,'m',bad),'radius')
  }
  for (bad in list(-1,1,1.9,NA_real_,Inf,c(2,3),matrix(2),2+1i)) {
    set.seed(34);before<-.Random.seed
    expect_error(MoransI(o,'m',2,n_perm=bad,seed=2),'n_perm')
    expect_identical(.Random.seed,before)
  }
  expect_error(MoransI(o,'m',2,n_perm=9,seed=1.5),'seed')
  expect_error(MoransI(o,'m',2,by_sample=NA),'by_sample')
  expect_equal(MoransI(o,'m',2,seed=1.5),MoransI(o,'m',2))
})

test_that('valid Moran weights retain the dense-matrix definition', {
  o<-contract_object();v<-o@counts[,1];D<-abs(outer(o@coords$x,o@coords$x,'-'))
  A<-(D<=2.1)&!diag(4)
  for (scheme in c('binary','row','idw')) {
    W<-A*1
    if(scheme=='row')W<-W/rowSums(W)
    if(scheme=='idw')W[A]<-1/D[A]
    z<-v-mean(v);expected<-4/sum(W)*drop(crossprod(z,W%*%z))/sum(z*z)
    out<-MoransI(o,'m',2.1,weights=scheme,n_perm=9,seed=-2)
    expect_equal(out$I,expected,tolerance=1e-12)
  }
})

 test_that('all sample features are validated before per-sample random draws', {
  o <- contract_object(); o@meta_data$sample_id <- c('a','a','b','b')
  o@meta_data$measurement <- c(1,2,NA,4)
  set.seed(39); before <- .Random.seed
  expect_error(MoransI(o,'measurement',2,n_perm=9,seed=2,by_sample=TRUE),
               'finite real numeric vector')
  expect_identical(.Random.seed,before)
})

test_that('IDW validates every sample before permutations without crossing samples', {
  o <- contract_object(); o@meta_data$sample_id <- c('a','a','b','b')
  o@coords$x <- c(0,1,3,3)
  set.seed(40); before <- .Random.seed
  expect_error(MoransI(o,'m',2,weights='idw',n_perm=9,seed=2,by_sample=TRUE),
               'positive distances')
  expect_identical(.Random.seed,before)
  o@coords$x <- c(0,1,0,1)
  expect_no_error(MoransI(o,'m',2,weights='idw',n_perm=9,seed=2,by_sample=TRUE))
})
