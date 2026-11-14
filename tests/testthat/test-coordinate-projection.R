projection_object <- function() {
 CreateSpatialObject(cbind(m1=1:8,m2=(8:1)^2),
  data.frame(x=c(0,.8,2.3,4.7,6.1,7.4,9.2,10.3),
             y=c(.2,1.4,0,2.8,.6,4.1,1.9,3.7)),
  data.frame(cell_id=paste0('c',1:8),sample_id='s',phenotype=rep(c('A','B'),4)))
}
projection_results <- function(o) {
 list(nearest=FindNeighbours(o,k=2)$nn_distance,
      density=CellDensity(o,radius=3.1)$density,
      interaction=InteractionMatrix(o,radius=3.1),
      moran=MoransI(o,'m1',3.1,weights='idw',n_perm=9,seed=1),
      ripley=RipleysK(o,r_seq=c(1,2,3)),
      enrichment=NeighbourhoodEnrichment(o,3.1,n_perm=9,seed=1),
      quadrat=suppressWarnings(QuadratAnalysis(o,nx=2,ny=2)),
      pair=PairCorrelation(o,r_seq=c(1,2,3),dr=.7),
      cross=CrossNNDistance(o,'A','B'),
      cluster=SpatialClusters(o,2,method='hierarchical')$cluster,
      delaunay=suppressWarnings(DelaunayNetwork(o))@spatial$delaunay_edges,
      niches=CellularNeighbourhoods(o,1,k=2,seed=1)@spatial$neighbourhood_composition,
      domains=SpatialDomains(o,2,k=2,seed=1)$domain)
}

test_that('two-dimensional object analyses ignore extra coordinate columns and order', {
 o<-projection_object();expected<-projection_results(o)
 variants<-list(o,o,o)
 variants[[1]]@coords$extra<-rep(c(0,100),4)
 variants[[2]]@coords$note<-letters[1:8]
 variants[[3]]@coords<-data.frame(note=letters[1:8],y=o@coords$y,extra=8:1,x=o@coords$x)
 for (x in variants) {
  before<-x
  actual<-projection_results(x)
  for(name in names(expected))expect_equal(actual[[name]],expected[[name]],info=name,tolerance=1e-12)
  expect_identical(x,before)
  expect_identical(SpatialClusters(x,2,method='hierarchical')@coords,x@coords)
  expect_identical(CellularNeighbourhoods(x,1,k=2,seed=1)@coords,x@coords)
 }
})

test_that('native and fallback geometry agree after named projection', {
 skip_if_not_installed('RANN')
 o<-projection_object();o@coords<-data.frame(note=letters[1:8],y=o@coords$y,extra=8:1,x=o@coords$x)
 native<-projection_results(o)
 local_mocked_bindings(requireNamespace=function(package,...) {
   if(package=='RANN')FALSE else base::requireNamespace(package,...)
 })
 fallback<-projection_results(o)
 for(name in names(native))expect_equal(fallback[[name]],native[[name]],info=name,tolerance=1e-12)
})

test_that('named projection preserves independently partitioned samples', {
 o<-projection_object();o@meta_data$sample_id<-rep(c('s1','s2'),each=4)
 x<-o;x@coords<-data.frame(extra=letters[1:8],y=o@coords$y,x=o@coords$x)
 expect_equal(FindNeighbours(x,2)$nn_distance,FindNeighbours(o,2)$nn_distance)
 expect_equal(CellularNeighbourhoods(x,1,k=2,seed=1)@spatial$neighbourhood_composition,
              CellularNeighbourhoods(o,1,k=2,seed=1)@spatial$neighbourhood_composition)
 expect_equal(MoransI(x,'m1',3.1,by_sample=TRUE),MoransI(o,'m1',3.1,by_sample=TRUE))
 edges<-DelaunayNetwork(x)@spatial$delaunay_edges
 expect_true(all(x$sample_id[edges$from]==x$sample_id[edges$to]))
 expect_equal(edges,DelaunayNetwork(o)@spatial$delaunay_edges)
})

test_that('matrix coordinate columns cannot create extra axes', {
 o<-projection_object();o@coords$x<-cbind(o@coords$x,o@coords$x)
 expect_error(SpatialClusters(o,2),'finite real numeric vectors')
 expect_error(RipleysK(o,r_seq=1:2),'finite real numeric vectors')
})
