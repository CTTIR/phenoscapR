.ed_build_geometry <- getFromNamespace(".ed_build_geometry", "phenoscapR")
.ed_number <- getFromNamespace(".ed_number", "phenoscapR")
.ed_text <- getFromNamespace(".ed_text", "phenoscapR")
pins<-list(package_version='2.0-4',description_sha256=strrep('a',64),native_library_sha256=strrep('b',64),
 binsrtR_body_serialized_sha256=strrep('c',64),binsrtR_body_deparse_sha256=strrep('d',64),
 wrapper_body_serialized_sha256=strrep('e',64),wrapper_body_deparse_sha256=strrep('f',64),
 digOutxy_body_serialized_sha256=strrep('1',64),digOutxy_body_deparse_sha256=strrep('2',64),
 digOutz_body_serialized_sha256=strrep('3',64),digOutz_body_deparse_sha256=strrep('4',64),
 binsrt_num_parameters=9L,master_num_parameters=16L)
fixture<-function(){list(nodes=data.frame(g='scope',f='image',id=c('A','B','C'),x=c(0,4,0),y=c(0,0,3),
 ord=1:3,rank=c(3,1,2),geom=TRUE,ok=TRUE),frames=data.frame(g='scope',f='image',unit='um'))}
# Pure orchestration test double returns independently specified literal edges.
# It is never used by production source or represented as actual native execution.
mock_env<-new.env(parent=environment(BuildExactDelaunayEdges));mock_env$calls<-list();mock_env$corrupt<-FALSE
mock_env$.ed_build_geometry<-function(x,y,backend_contract,eps,mode,initial_madj,max_retries){
 mock_env$calls[[length(mock_env$calls)+1L]]<-list(x=x,y=y)
 n<-length(x)
 ends<-if(n==3L)rbind(c(1,2),c(1,3),c(2,3))else rbind(c(1,2),c(2,3),c(3,4),c(4,1),c(1,5),c(2,5),c(3,5),c(4,5))
 a<-ends[,1];b<-ends[,2]
 raw<-data.frame(ind1=a,ind2=b,x1=x[a],y1=y[a],x2=x[b],y2=y[b])
 if(mock_env$corrupt)raw$x1[nrow(raw)]<-999
 list(raw_edges=raw,n_points=n,provenance=list(test_double=TRUE))
}
build<-BuildExactDelaunayEdges;environment(build)<-mock_env
run<-function(z=fixture(),group='g',caps=c(short=3,long=5))build(z$nodes,z$frames,group,'f','id','x','y','ord','rank','geom','ok','unit','um',
 'orientation_rank','span_padding_v1','distance_leq',pins,1e-9,'stock',caps)
reset<-function(){mock_env$calls<-list();mock_env$corrupt<-FALSE}
test_that('explicit ranks, transport order and caps have literal expected outputs',{
 reset();z<-fixture();before<-serialize(z,NULL);r<-run(z)
 expect_identical(r$full_edges$from_id,c('B','B','C'));expect_identical(r$full_edges$to_id,c('C','A','A'))
 expect_equal(r$full_edges$distance,c(5,4,3));expect_equal(colSums(r$cap_flags),c(short=1,long=3))
 expect_identical(serialize(z,NULL),before);expect_length(mock_env$calls,1)
 expect_equal(mock_env$calls[[1]],list(x=c(0,4,0),y=c(0,0,3)))
 z$nodes<-z$nodes[c(3,1,2),];q<-run(z);expect_identical(q$full_edges,r$full_edges)
 expect_equal(q$nodes$source_row,c(2,3,1));expect_identical(q$provenance$historical_parity,'NOT_ESTABLISHED')
})
test_that('full blocker geometry precedes eligible induction and retains excluded/isolated nodes',{
 reset();z<-fixture();z$nodes<-data.frame(g='scope',f='image',id=c('A','B','C','D','O','outside'),
 x=c(-2,2,2,-2,0,10),y=c(-2,-2,2,2,0,10),ord=1:6,rank=1:6,geom=c(rep(TRUE,5),FALSE),ok=c(TRUE,FALSE,TRUE,FALSE,FALSE,FALSE))
 r<-run(z);expect_equal(r$frames$n_nodes,6);expect_equal(r$frames$n_geometry,5);expect_equal(r$frames$n_eligible,2)
 expect_equal(nrow(r$full_edges),8);expect_length(r$analysis_edge_rows,0)
 expect_true(is.na(r$nodes$geometry_index[r$nodes$id=='outside']));expect_length(mock_env$calls[[1]]$x,5)
 mock_env$corrupt<-TRUE;expect_error(run(z),'exact declared');mock_env$corrupt<-FALSE
})
test_that('all-frame preflight rejects later malformed frame before any dispatch',{
 for(problem in c('duplicate','nonfinite','collinear','short','order','unit','eligibility')){
 reset();z<-fixture();n<-z$nodes;n$f<-'later';f<-z$frames;f$f<-'later';z$frames<-rbind(z$frames,f)
 if(problem=='duplicate')n$id[2]<-n$id[1]
 if(problem=='nonfinite')n$x[2]<-Inf
 if(problem=='collinear'){n$x<-0:2;n$y<-0}
 if(problem=='short')n<-n[1:2,]
 if(problem=='order')n$rank[2]<-n$rank[1]
 if(problem=='unit')z$frames$unit[2]<-'mm'
 if(problem=='eligibility')n$geom[1]<-FALSE
 z$nodes<-rbind(z$nodes,n);expect_error(run(z));expect_length(mock_env$calls,0)
 }
})
test_that('complete registry keys, empty outputs, reserved names and UTF8 are deterministic',{
 reset();z<-fixture();n<-z$nodes;n$g<-'α';n$id<-c('α','β','γ');z$nodes<-rbind(n,z$nodes);z$frames<-rbind(data.frame(g='α',f='image',unit='um'),z$frames)
 r<-run(z);expect_equal(r$frames$n_full_edges,c(3,3));expect_identical(r$frames$g,c('scope','α'))
 for(nm in c('sep','collapse','recycle0','.SD','.N','.I','.GRP','.BY','...','method')){
  reset();a<-fixture();names(a$nodes)[1]<-nm;names(a$frames)[1]<-nm
  q<-run(a,nm);expect_equal(q$frames$n_full_edges,3);expect_identical(q$full_edges$from_id,c('B','B','C'))
 }
 reset();z<-fixture();z$nodes<-z$nodes[FALSE,];z$frames<-z$frames[FALSE,];r<-run(z)
 expect_length(mock_env$calls,0);expect_equal(nrow(r$full_edges),0);expect_false(r$provenance$native_execution)
 expect_identical(r$provenance$empty_registry,'NO_BACKEND_LOADED_OR_EXECUTED')
 reset();z<-fixture();z$frames<-rbind(z$frames,data.frame(g='missing',f='none',unit='um'))
 expect_error(run(z),'three points');expect_length(mock_env$calls,0)
})


test_that('classed columns fail before dispatch while plain named vectors and table containers work', {
 for(field in c('g','id','x','y','ord','rank','geom','ok')){
  reset();z<-fixture();z$nodes[[field]]<-structure(z$nodes[[field]],class='custom_test_class')
  expect_error(run(z));expect_length(mock_env$calls,0)
 }
 reset();expect_error(run(caps=structure(c(a=3),class='custom_test_class')));expect_length(mock_env$calls,0)
 reset();z<-fixture();z$nodes$x<-structure(z$nodes$x,class='integer64');expect_error(run(z));expect_length(mock_env$calls,0)
 reset();z<-fixture();names(z$nodes$x)<-c('first','second','third');expect_equal(run(z)$frames$n_full_edges,3)
 reset();z<-fixture();z$nodes<-data.table::as.data.table(z$nodes);z$frames<-data.table::as.data.table(z$frames)
 expect_equal(run(z)$frames$n_full_edges,3)
 expect_false(.ed_number(structure(1,class='integer64')));expect_false(.ed_text(structure('a',class='custom_test_class')))
})
