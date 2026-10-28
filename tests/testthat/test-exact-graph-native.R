graph_require_deldir <- function() {
 required <- identical(Sys.getenv('PHENOSCAP_REQUIRE_EXACT_NATIVE'), 'true')
 if(!requireNamespace('deldir', quietly=TRUE)) {
  if(required)stop('Required exact native backend unavailable')
  skip('Optional deldir backend unavailable')
 }
 invisible(TRUE)
}
graph_native_call<-function(nodes,frames,mode,caps=numeric())BuildExactDelaunayEdges(nodes,frames,'g','f','id','x','y','ord','rank','geom','ok','unit','um','orientation_rank','span_padding_v1','distance_leq',eps=1e-9,mode=mode,caps=caps)
graph_native_nodes<-function(x,y) data.frame(g='one',f='image',id=as.character(seq_along(x)),x=x,y=y,ord=seq_along(x),rank=seq_along(x),geom=TRUE,ok=TRUE)
graph_native_frames<-function()data.frame(g='one',f='image',unit='um')

test_that('native stock and bounded paths match independent literal and integer geometry',{
 graph_require_deldir()
 literal<-list(
  list(x=c(0,4,0),y=c(0,0,3),pairs=rbind(c(1,2),c(1,3),c(2,3))),
  list(x=c(0,4,3,0),y=c(0,0,3,1),pairs=rbind(c(1,2),c(1,4),c(2,3),c(2,4),c(3,4))),
  list(x=c(0,6,0,1),y=c(0,0,6,1),pairs=rbind(c(1,2),c(1,3),c(1,4),c(2,3),c(2,4),c(3,4))))
 z<-jsonlite::read_json(test_path('fixtures','exact-graph-integer.json'),simplifyVector=TRUE)
 literal[[4]]<-list(x=z$points[,1]/z$scale,y=z$points[,2]/z$scale,pairs=z$expected_pairs)
 for(fix in literal){
  nodes<-graph_native_nodes(fix$x,fix$y);a<-graph_native_call(nodes,graph_native_frames(),'stock')
  b<-graph_native_call(nodes,graph_native_frames(),'bounded')
  pairs<-unname(as.matrix(a$full_edges[c('from_geometry_index','to_geometry_index')]))
  expect_equal(pairs,fix$pairs);expect_identical(a$full_edges,b$full_edges)
  expect_identical(a$nodes,b$nodes)
  expect_true(a$provenance$native_execution);expect_identical(a$provenance$historical_parity,'NOT_ESTABLISHED')
 }
})

test_that('native complete frames retain blocker induction and exact inclusive caps',{
 graph_require_deldir()
 n<-graph_native_nodes(c(-2,2,2,-2,0),c(-2,-2,2,2,0));n$ok<-c(TRUE,FALSE,TRUE,FALSE,FALSE)
 other<-graph_native_nodes(c(0,4,0),c(0,0,3));other$f<-'triangle';other$rank<-c(3,1,2)
 n<-rbind(n,other);f<-rbind(graph_native_frames(),data.frame(g='one',f='triangle',unit='um'))
 a<-graph_native_call(n,f,'stock',c(r3=3,r4=4,r5=5))
 b<-graph_native_call(n,f,'bounded',c(r3=3,r4=4,r5=5))
 expect_identical(a$full_edges,b$full_edges);expect_identical(a$cap_flags,b$cap_flags)
 expect_equal(a$frames$n_full_edges,c(8,3));expect_equal(a$frames$n_analysis_edges,c(0,3));expect_equal(a$frames$n_eligible,c(2,3))
 expect_true(all(a$full_edges$f[a$analysis_edge_rows]=='triangle'))
 expect_equal(unname(a$cap_flags),unname(outer(a$full_edges$distance,c(3,4,5),'<=')))
})

test_that('high-degree hub completes after deldir enlarges its own workspace',{
 graph_require_deldir();angle<-2*pi*(0:69)/70
 nodes<-graph_native_nodes(c(0,cos(angle)),c(0,sin(angle)));frames<-graph_native_frames()
 expected<-rbind(cbind(1,2:71),cbind(2:70,3:71),c(2,71))
 expected<-expected[order(expected[,1],expected[,2]),,drop=FALSE]
 invoke<-function(mode)BuildExactDelaunayEdges(nodes,frames,'g','f','id','x','y','ord','rank','geom','ok','unit','um',
  'orientation_rank','span_padding_v1','distance_leq',eps=1e-9,mode=mode)
 # The stock initial capacity is 26 neighbours; deldir enlarges it and retries.
 for(mode in c('stock','bounded','auto')) {
  result<-invoke(mode)
  expect_equal(unname(as.matrix(result$full_edges[c('from_geometry_index','to_geometry_index')])),expected)
  expect_equal(nrow(result$full_edges),140)
  expect_gt(result$frame_construction[[1]]$provenance$workspace_growth,0)
 }
})
