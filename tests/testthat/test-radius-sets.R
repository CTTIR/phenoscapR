fixture <- function() list(
 nodes=data.frame(sample='one',frame='f',id=c('self','coincident','inside','boundary','outside'),
 x=c(0,0,1-.Machine$double.eps/2,1,1+.Machine$double.eps),y=0,
 query=c(TRUE,FALSE,FALSE,FALSE,FALSE),reference=TRUE,
 a=c(TRUE,TRUE,TRUE,FALSE,TRUE),b=c(FALSE,TRUE,FALSE,TRUE,FALSE)),
 frames=data.frame(sample=c('one','empty'),frame='f',units='um'))
run <- function(z,radii=1,chunk=2L,search=max(radii)) CountRadiusSets(z$nodes,z$frames,'sample','frame','id','x','y','query','reference',c('a','b'),'units','um',radii,search,chunk)
test_that('inclusive boundaries and distinct coincident IDs are preserved',{
 z<-fixture();o<-run(z);expect_equal(o$query_counts$n_reference_neighbors,3)
 expect_equal(o$set_counts$count,c(2,2));expect_equal(o$frame_summary$n_nodes,c(0,5))
 expect_identical(o$frame_summary$status,c('NO_QUERIES','DEFINED'))
 expect_identical(o$backend$search,'kdtree');expect_identical(o$backend$approx,0)
 expect_match(o$backend$description_sha256,'^[a-f0-9]{64}$')
 expect_true(all(grepl('^[a-f0-9]{64}$',o$backend$native_sha256)))
 z$nodes$query<-TRUE;expect_identical(run(z,chunk=1)$query_counts,run(z,chunk=100)$query_counts)
 expect_identical(run(z,chunk=1)$set_counts,run(z,chunk=100)$set_counts)
})
test_that('complete query rows, empty reference and empty frames retain typed counts',{
 z<-fixture();z$nodes$reference<-FALSE;o<-run(z,c(.5,1));expect_equal(o$query_counts$n_reference_neighbors,c(0,0));expect_true(all(o$query_counts$status=='EMPTY_REFERENCE'));expect_equal(o$set_counts$count,rep(0,4))
 z$nodes<-z$nodes[FALSE,];o<-run(z);expect_equal(nrow(o$frame_summary),2L);expect_equal(nrow(o$query_counts),0L);expect_type(o$query_counts$n_reference_neighbors,'double');expect_type(o$query_counts$status,'character')
 z$frames<-z$frames[FALSE,];o<-run(z);expect_equal(nrow(o$frame_summary),0L);expect_type(o$frame_summary$status,'character')
})
test_that('frames isolate same IDs and count overlapping sets independently',{
 z<-fixture();w<-z$nodes;w$sample<-'two';w$x<-w$x+100;z$nodes<-rbind(z$nodes,w);z$frames<-rbind(z$frames,data.frame(sample='two',frame='f',units='um'));o<-run(z)
 # Offset changes representability near a boundary; no coordinate recentering is inferred.
 expect_equal(o$frame_summary$n_queries,c(0,1,1));expect_equal(o$query_counts$n_reference_neighbors[1],3)
 z<-fixture();before<-serialize(z,NULL);run(z);expect_identical(serialize(z,NULL),before)
})
test_that('independent squared integer distance oracle covers small graphs',{
 set.seed(501)
 for(trial in 1:40){
  n<-12L;z<-fixture();z$nodes<-data.frame(sample='one',frame='f',id=as.character(seq_len(n)),x=sample(-5:5,n,TRUE),y=sample(-5:5,n,TRUE),query=sample(c(TRUE,FALSE),n,TRUE),reference=sample(c(TRUE,FALSE),n,TRUE),a=sample(c(TRUE,FALSE),n,TRUE),b=sample(c(TRUE,FALSE),n,TRUE));radii<-c(1,2,5);o<-run(z,radii,chunk=3)
  for(q in which(z$nodes$query))for(r in radii){
   # Integer-coordinate squared distances are exact here: no sqrt/backend replication.
   keep<-z$nodes$reference & z$nodes$id!=z$nodes$id[q] & (z$nodes$x-z$nodes$x[q])^2+(z$nodes$y-z$nodes$y[q])^2<=r^2
   actual<-o$query_counts[o$query_counts$id==z$nodes$id[q]&o$query_counts$radius==r,];expect_equal(actual$n_reference_neighbors,sum(keep))
   for(s in c('a','b')){v<-o$set_counts[o$set_counts$id==z$nodes$id[q]&o$set_counts$radius==r&o$set_counts$set==s,'count'];expect_equal(v,sum(keep&z$nodes[[s]]))}
  }
  zz<-z;zz$nodes<-zz$nodes[rev(seq_len(n)),];expect_identical(run(zz,radii,chunk=1)$query_counts,o$query_counts);expect_identical(run(zz,radii,chunk=1)$set_counts,o$set_counts)
 }
})
test_that('malformed keys memberships dimensions units and unsafe arithmetic reject',{
 z<-fixture();z$nodes$id[2]<-z$nodes$id[1];expect_error(run(z),'Duplicate')
 z<-fixture();z$nodes$sample[2]<-'unknown';expect_error(run(z),'Unknown')
 z<-fixture();z$frames$units[1]<-'mm';expect_error(run(z),'units')
 for(column in c('sample','frame','id','x','y','query','reference','a','b')){
  z<-fixture();z$nodes[[column]]<-matrix(z$nodes[[column]],ncol=1);expect_error(run(z))
  z<-fixture();z$nodes[[column]][1]<-NA;expect_error(run(z))
 }
 z<-fixture();z$nodes$x[1]<-Inf;expect_error(run(z),'finite')
 z<-fixture();z$nodes$x[1]<-1e308;expect_error(run(z),'magnitude')
 expect_error(run(fixture(),1e308),'squared radius');expect_error(run(fixture(),1e-300),'squared radius');expect_error(run(fixture(),1e-160),'squared radius')
 expect_error(run(fixture(),c(1,1)),'distinct');expect_error(run(fixture(),0),'positive')
 expect_error(run(fixture(),chunk=.5),'chunk')
})

test_that('ordinary argument names are safe key names and selected roles cannot collide',{
 z<-fixture();expected<-run(z)
 for(nm in c('method','decreasing','na.last','collapse','recycle0','.SD')){
  a<-z;names(a$nodes)[names(a$nodes)=='sample']<-nm;names(a$frames)[names(a$frames)=='sample']<-nm
  actual<-CountRadiusSets(a$nodes,a$frames,nm,'frame','id','x','y','query','reference',c('a','b'),'units','um',1,1)
  for(tab in c('frame_summary','query_counts','set_counts')){names(actual[[tab]])[names(actual[[tab]])==nm]<-'sample';expect_identical(actual[[tab]],expected[[tab]])}
 }
 expect_error(CountRadiusSets(z$nodes,z$frames,'sample','frame','id','x','x','query','reference',c('a','b'),'units','um',1,1),'collide')
 expect_error(CountRadiusSets(z$nodes,z$frames,'sample','frame','id','x','y','query','reference',c('a','b'),'sample','um',1),'collide')
})

test_that('explicit search radius binds backend boundary semantics',{
 z<-fixture();z$nodes<-data.frame(sample='one',frame='f',id=c('q','r'),x=c(0,3+2*.Machine$double.eps),y=c(0,4),query=c(TRUE,FALSE),reference=c(FALSE,TRUE),a=TRUE,b=FALSE)
 small<-run(z,5,search=5);large<-run(z,5,search=6)
 expect_equal(small$query_counts$n_reference_neighbors,0)
 expect_equal(large$query_counts$n_reference_neighbors,1)
 expect_equal(large$backend$search_radius,6)
 grid<-run(z,c(5,6),search=6)
 expect_identical(large$query_counts,grid$query_counts[grid$query_counts$radius==5,,drop=FALSE])
 expect_error(run(z,5,search=4),'search_radius')
 expect_error(run(z,5,search=Inf),'search_radius')
 expect_error(run(z,5,search=1e308),'squared radius')
})

test_that('native fingerprint names retain architecture directories',{
 paths<-c('/package/libs/x64/dbscan.dll','/package/libs/i386/dbscan.dll')
 expect_identical(.radius_native_keys(paths,'/package/libs'),c('x64/dbscan.dll','i386/dbscan.dll'))
 expect_error(.radius_native_keys(rep(paths[1],2),'/package/libs'),'Duplicate')
 expect_error(.radius_native_keys('/package/libs-other/dbscan.dll','/package/libs'),'Invalid')
 o<-run(fixture());expect_false(anyDuplicated(names(o$backend$native_sha256))>0L)
 expect_false(any(startsWith(names(o$backend$native_sha256),'/')))
})
test_that('integer native and planned output bounds reject without allocations',{
 lim<-as.double(.Machine$integer.max)
 expect_error(.radius_count_limits(lim+1,1,1,1,1),'integer index')
 expect_error(.radius_count_limits(1,lim+1,1,1,1),'integer index')
 expect_error(.radius_count_limits(lim,1,lim,2,1),'output exceeds')
 expect_error(.radius_count_limits(lim,1,lim,1,2),'output exceeds')
 n<-floor(floor(lim/11)/4)
 expect_silent(.radius_count_limits(n,1,n,4,11))
 expect_error(.radius_count_limits(n+1,1,n+1,4,11),'output exceeds')
 expect_silent(.radius_count_limits(0,0,0,lim,lim))
 expect_error(.radius_count_limits(1,1,1,lim,lim),'output exceeds')
 expect_error(.radius_count_limits(1,1,2,1,1),'integer index')
})

test_that('native and marked Unicode sorting keys retain columns and counts', {
  skip_if_not(l10n_info()[['UTF-8']], 'native UTF-8 fixture requires UTF-8 locale')
  u <- intToUtf8(c(945, 946))
  native <- u; Encoding(native) <- 'unknown'
  z <- fixture(); z$nodes$sample <- native; z$nodes$frame <- native
  z$nodes$id <- paste0(native, seq_len(nrow(z$nodes)))
  Encoding(z$nodes$id) <- 'unknown'
  z$frames <- data.frame(sample=native, frame=native, units='um')
  names(z$nodes)[names(z$nodes)=='a'] <- native
  call <- function(z, set) CountRadiusSets(z$nodes,z$frames,'sample','frame','id',
    'x','y','query','reference',c(set,'b'),'units','um',1,1)
  got <- call(z,native)
  marked <- z
  for(column in c('sample','frame','id')) marked$nodes[[column]] <- enc2utf8(marked$nodes[[column]])
  for(column in c('sample','frame')) marked$frames[[column]] <- enc2utf8(marked$frames[[column]])
  names(marked$nodes) <- enc2utf8(names(marked$nodes))
  expected <- call(marked,u)
  expect_equal(got$query_counts$n_reference_neighbors,expected$query_counts$n_reference_neighbors)
  expect_equal(got$set_counts$count,expected$set_counts$count)
  expect_identical(Encoding(got$query_counts$sample),Encoding(z$nodes$sample[z$nodes$query]))
  expect_identical(Encoding(got$query_counts$id),Encoding(z$nodes$id[z$nodes$query]))
  expect_identical(enc2utf8(got$set_counts$set),expected$set_counts$set)
})
