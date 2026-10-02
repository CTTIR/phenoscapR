graph_observed_contract <- function() {
 required <- identical(Sys.getenv('PHENOSCAP_REQUIRE_EXACT_NATIVE'), 'true')
 available <- requireNamespace('deldir', quietly=TRUE)
 if(!available) {
  if(required)stop('Required exact native backend unavailable')
  skip('Optional deldir backend unavailable')
 }
 ns<-asNamespace('deldir');desc<-file.path(getNamespaceInfo(ns,'path'),'DESCRIPTION')
 version<-as.character(read.dcf(desc,fields='Version')[[1]])
 if(!identical(version,'2.0-4')) {
  if(required)stop('Required supported deldir2.0-4 profile unavailable')
  skip('Installed deldir version is outside the supported exact profile')
 }
 dll<-getLoadedDLLs()[['deldir']];wrapper<-get('deldir',ns)
 funcs<-list(binsrtR=get('binsrtR',ns),wrapper=wrapper,
  digOutxy=get('digOutxy',environment(wrapper)),digOutz=get('digOutz',environment(wrapper)))
 hashfile<-function(p)digest::digest(file=p,algo='sha256',serialize=FALSE)
 pins<-list(package_version=version,description_sha256=hashfile(desc),native_library_sha256=hashfile(dll[['path']]),binsrt_num_parameters=9L,master_num_parameters=16L)
 for(k in names(funcs)) {
  pins[[paste0(k,'_body_serialized_sha256')]]<-digest::digest(body(funcs[[k]]),algo='sha256')
  pins[[paste0(k,'_body_deparse_sha256')]]<-digest::digest(paste(deparse(body(funcs[[k]]),width.cutoff=500L),collapse='\n'),algo='sha256',serialize=FALSE)
 }
 list(pins=pins,functions=funcs)
}
graph_native_call<-function(nodes,frames,pins,mode,caps=numeric())BuildExactDelaunayEdges(nodes,frames,'g','f','id','x','y','ord','rank','geom','ok','unit','um','orientation_rank','span_padding_v1','distance_leq',pins,1e-9,mode,caps)
graph_native_nodes<-function(x,y) data.frame(g='one',f='image',id=as.character(seq_along(x)),x=x,y=y,ord=seq_along(x),rank=seq_along(x),geom=TRUE,ok=TRUE)
graph_native_frames<-function()data.frame(g='one',f='image',unit='um')

test_that('native stock and bounded paths match independent literal and integer geometry',{
 observed<-graph_observed_contract()
 snap<-function()lapply(observed$functions,function(f)list(body=serialize(body(f),NULL),formals=serialize(formals(f),NULL),env=environment(f)))
 before<-snap()
 literal<-list(
  list(x=c(0,4,0),y=c(0,0,3),pairs=rbind(c(1,2),c(1,3),c(2,3))),
  list(x=c(0,4,3,0),y=c(0,0,3,1),pairs=rbind(c(1,2),c(1,4),c(2,3),c(2,4),c(3,4))),
  list(x=c(0,6,0,1),y=c(0,0,6,1),pairs=rbind(c(1,2),c(1,3),c(1,4),c(2,3),c(2,4),c(3,4))))
 z<-jsonlite::read_json(test_path('fixtures','exact-graph-integer.json'),simplifyVector=TRUE)
 literal[[4]]<-list(x=z$points[,1]/z$scale,y=z$points[,2]/z$scale,pairs=z$expected_pairs)
 for(fix in literal){
  nodes<-graph_native_nodes(fix$x,fix$y);a<-graph_native_call(nodes,graph_native_frames(),observed$pins,'stock')
  b<-graph_native_call(nodes,graph_native_frames(),observed$pins,'bounded')
  pairs<-unname(as.matrix(a$full_edges[c('from_geometry_index','to_geometry_index')]))
  expect_equal(pairs,fix$pairs);expect_identical(a$full_edges,b$full_edges)
  expect_identical(a$nodes,b$nodes);expect_identical(snap(),before)
  expect_true(a$provenance$native_execution);expect_identical(a$provenance$historical_parity,'NOT_ESTABLISHED')
 }
 backend<-getFromNamespace('.ed_backend','phenoscapR')
 for(k in names(observed$pins)[grepl('sha256$',names(observed$pins))]){
  bad<-observed$pins;bad[[k]]<-strrep('0',64);expect_error(backend(bad),'Backend pin mismatch')
 }
 expect_identical(snap(),before)
})

test_that('native complete frames retain blocker induction and exact inclusive caps',{
 observed<-graph_observed_contract()
 n<-graph_native_nodes(c(-2,2,2,-2,0),c(-2,-2,2,2,0));n$ok<-c(TRUE,FALSE,TRUE,FALSE,FALSE)
 other<-graph_native_nodes(c(0,4,0),c(0,0,3));other$f<-'triangle';other$rank<-c(3,1,2)
 n<-rbind(n,other);f<-rbind(graph_native_frames(),data.frame(g='one',f='triangle',unit='um'))
 a<-graph_native_call(n,f,observed$pins,'stock',c(r3=3,r4=4,r5=5))
 b<-graph_native_call(n,f,observed$pins,'bounded',c(r3=3,r4=4,r5=5))
 expect_identical(a$full_edges,b$full_edges);expect_identical(a$cap_flags,b$cap_flags)
 expect_equal(a$frames$n_full_edges,c(8,3));expect_equal(a$frames$n_analysis_edges,c(0,3));expect_equal(a$frames$n_eligible,c(2,3))
 expect_true(all(a$full_edges$f[a$analysis_edge_rows]=='triangle'))
 expect_equal(unname(a$cap_flags),unname(outer(a$full_edges$distance,c(3,4,5),'<=')))
})

test_that('high-degree hub requires bounded growth and refuses unexpected stock retries',{
 observed<-graph_observed_contract();angle<-2*pi*(0:69)/70
 nodes<-graph_native_nodes(c(0,cos(angle)),c(0,sin(angle)));frames<-graph_native_frames()
 expected<-rbind(cbind(1,2:71),cbind(2:70,3:71),c(2,71))
 expected<-expected[order(expected[,1],expected[,2]),,drop=FALSE]
 invoke<-function(mode,retries)BuildExactDelaunayEdges(nodes,frames,'g','f','id','x','y','ord','rank','geom','ok','unit','um',
  'orientation_rank','span_padding_v1','distance_leq',observed$pins,1e-9,mode,initial_madj=20L,max_retries=retries)
 # The stock initial capacity is26, so retry messages must fail closed.
 expect_error(invoke('stock',32L),'Unexpected backend message')
 result<-invoke('bounded',32L)
 expect_equal(unname(as.matrix(result$full_edges[c('from_geometry_index','to_geometry_index')])),expected)
 expect_equal(nrow(result$full_edges),140)
 expect_gt(result$frame_construction[[1]]$provenance$retries,0)
 expect_gt(result$frame_construction[[1]]$provenance$final_workspace$initial_madj_used,20)
 expect_error(invoke('bounded',0L),'retry ceiling')
})
