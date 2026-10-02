.ed_next_workspace <- getFromNamespace(".ed_next_workspace", "phenoscapR")
.ed_validate_supplied_edges <- getFromNamespace(".ed_validate_supplied_edges", "phenoscapR")
.ed_window <- getFromNamespace(".ed_window", "phenoscapR")
fixture <- function() {
 n<-data.frame(g='one',f='image',id=c('A','B','C'),x=c(0,4,0),y=c(0,0,3),ord=1:3,rank=c(3,1,2),geom=TRUE,ok=TRUE)
 e<-data.frame(g='one',f='image',ind1=c(1,1,2),ind2=c(2,3,3),x1=c(0,0,4),y1=c(0,0,0),x2=c(4,0,0),y2=c(0,3,3))
 list(nodes=n,raw_edges=e,frames=data.frame(g='one',f='image',unit='um'))
}
run <- function(z=fixture(), caps=c(r3=3,r4=4,r5=5)) .ed_validate_supplied_edges(z$nodes,z$raw_edges,z$frames,'g','f','id','x','y','ord','rank','geom','ok','unit','um','orientation_rank',caps)

test_that('workspace preflight matches independent arbitrary-integer calculations without allocation', {
 oracle<-jsonlite::read_json(test_path('fixtures','exact-graph-workspace.json'),simplifyVector=FALSE)
 for(row in oracle$rows) {
  if(!row$supported){expect_error(PlanExactDelaunayWorkspace(row$n,'bounded'),'length');next}
  p<-PlanExactDelaunayWorkspace(row$n,'bounded')
  expect_equal(p$stock_madj,row$stock_madj);expect_equal(p$stock_adjacency_length,row$stock_nadj)
  expect_identical(p$bounded_required,row$bounded_required);expect_equal(p$max_madj,row$max_madj)
  expect_equal(p$initial_madj_used,row$bounded_madj);expect_equal(p$segment_capacity,row$segment_capacity)
  expect_equal(p$native_lengths,unlist(row$lengths));expect_equal(p$adjacency_headroom_rows,row$bounded_headroom)
  expect_equal(p$native_buffer_bytes,row$buffer_bytes);expect_false(p$native_execution)
 }
 expect_identical(PlanExactDelaunayWorkspace(799799)$execution_path,'STOCK_WRAPPER')
 expect_identical(PlanExactDelaunayWorkspace(799800)$execution_path,'BOUNDED_REGISTERED_MASTER')
 expect_error(PlanExactDelaunayWorkspace(799800,'stock'),'spare')
 expect_error(PlanExactDelaunayWorkspace(3,'bounded',retain_tessellation=TRUE),'incomplete')
 expect_error(PlanExactDelaunayWorkspace(matrix(3)),'point');expect_error(PlanExactDelaunayWorkspace(2),'point')
 expect_error(PlanExactDelaunayWorkspace(3,initial_madj=20.5),'capacity')
 expect_error(PlanExactDelaunayWorkspace(3,max_retries=NA_real_),'retry')
 n<-.ed_next_workspace(100,64,0,32,1,0);expect_equal(n$madj,77);expect_equal(n$retries,1)
 expect_identical(.ed_next_workspace(100,64,0,0,0,0)$status,'NO_GROWTH_REQUESTED')
 expect_error(.ed_next_workspace(100,64,0,0,1,0),'ceiling')
 expect_error(.ed_next_workspace(100,64,0,32,0,1),'incomplete')
 expect_error(.ed_next_workspace(100,64,0,32,2,0),'flags')
 p<-PlanExactDelaunayWorkspace(799800,'bounded')
 expect_error(.ed_next_workspace(799800,p$max_madj,0,32,1,0),'No larger')
})

test_that('literal triangle validates coordinate identity and independent orientation rank', {
 z<-fixture();before<-serialize(z,NULL);r<-run(z)
 expect_identical(r$full_edges$from_id,c('B','B','C'));expect_identical(r$full_edges$to_id,c('C','A','A'))
 expect_equal(r$full_edges$distance,c(5,4,3));expect_equal(colSums(r$cap_flags),c(r3=1,r4=2,r5=3))
 expect_equal(r$frames$n_full_edges,3);expect_equal(r$frames$n_analysis_edges,3)
 expect_false(r$provenance$construction_performed);expect_identical(serialize(z,NULL),before)
 z$nodes<-z$nodes[c(3,1,2),];z$raw_edges<-z$raw_edges[3:1,]
 expect_identical(run(z)$full_edges,r$full_edges);expect_identical(run(z)$cap_flags,r$cap_flags)
 z<-fixture();z$nodes$ok<-c(TRUE,FALSE,FALSE);r<-run(z)
 expect_length(r$analysis_edge_rows,0);expect_equal(sum(r$nodes$ok),1);expect_equal(r$frames$n_full_edges,3)
 w<-.ed_window(c(0,4,0),c(0,0,3));expect_identical(w$bounds,c(-1e-6,4+1e-6,-1e-6,3+1e-6));expect_false(w$transformed)
})

test_that('center blocker edges are validated before inducing selected corner graph', {
 z<-fixture();z$nodes<-data.frame(g='one',f='image',id=c('A','B','C','D','O'),x=c(-2,2,2,-2,0),y=c(-2,-2,2,2,0),ord=1:5,rank=1:5,geom=TRUE,ok=c(TRUE,TRUE,TRUE,FALSE,FALSE))
 ends<-rbind(c(1,2),c(2,3),c(3,4),c(4,1),c(1,5),c(2,5),c(3,5),c(4,5))
 z$raw_edges<-data.frame(g='one',f='image',ind1=as.double(ends[,1]),ind2=as.double(ends[,2]),x1=z$nodes$x[ends[,1]],y1=z$nodes$y[ends[,1]],x2=z$nodes$x[ends[,2]],y2=z$nodes$y[ends[,2]])
 r<-run(z);e<-r$full_edges[r$analysis_edge_rows,]
 expect_equal(nrow(r$full_edges),8);expect_identical(paste(e$from_id,e$to_id),c('A B','B C'))
 z$nodes$ok<-z$nodes$id%in%c('A','C');r<-run(z);expect_length(r$analysis_edge_rows,0);expect_equal(r$frames$n_eligible,2)
 z$raw_edges$x1[8]<-99;expect_error(run(z),'exact declared')
})

test_that('full graph failures cannot be hidden by eligibility induction', {
 z<-fixture();z$nodes$ok<-FALSE;z$raw_edges$ind1[1]<-1.5;expect_error(run(z),'whole')
 z<-fixture();z$raw_edges[3,]<-z$raw_edges[1,];expect_error(run(z),'Duplicate unordered')
 z<-fixture();z$raw_edges$x1[1]<-.Machine$double.eps;expect_error(run(z),'exact declared')
 z<-fixture();z$nodes$x[2]<-0;z$nodes$y[2]<-0;expect_error(run(z),'Duplicate geometry')
 z<-fixture();z$nodes$x<-0:2;z$nodes$y<-0;expect_error(run(z),'Noncollinear')
 z<-fixture();z$nodes$rank[2]<-z$nodes$rank[1];expect_error(run(z),'Duplicate declared')
 z<-fixture();z$nodes$geom[1]<-FALSE;expect_error(run(z),'Eligible')
 z<-fixture();z$nodes$x[1]<-Inf;expect_error(run(z),'finite')
 # Two disjoint triangles have enough edges for the simple cardinality bound.
 z<-fixture();n<-z$nodes;m<-n;m$id<-paste0(m$id,'2');m$x<-m$x+10;m$ord<-m$ord+3;m$rank<-m$rank+3;m$ok<-FALSE;z$nodes<-rbind(n,m)
 e<-z$raw_edges;f<-e;f$ind1<-f$ind1+3;f$ind2<-f$ind2+3;f$x1<-f$x1+10;f$x2<-f$x2+10;z$raw_edges<-rbind(e,f)
 expect_error(run(z),'disconnected')
})

test_that('frames keys empty schemas and numeric guards are explicit', {
 z<-fixture();n<-z$nodes;n$g<-'two';z$nodes<-rbind(z$nodes,n);e<-z$raw_edges;e$g<-'two';z$raw_edges<-rbind(z$raw_edges,e);z$frames<-rbind(z$frames,data.frame(g='two',f='image',unit='um'))
 expect_equal(run(z)$frames$n_full_edges,c(3,3))
 for(nm in c('sep','collapse','recycle0','.SD','.N','.I','.GRP','.BY','...','method')) {
  a<-fixture();for(tab in names(a))names(a[[tab]])[names(a[[tab]])=='g']<-nm
  r<-.ed_validate_supplied_edges(a$nodes,a$raw_edges,a$frames,nm,'f','id','x','y','ord','rank','geom','ok','unit','um','orientation_rank')
  expect_equal(r$frames$n_full_edges,3);expect_identical(r$full_edges$from_id,c('B','B','C'))
 }
 z<-fixture();z$nodes<-z$nodes[FALSE,];z$raw_edges<-z$raw_edges[FALSE,];z$frames<-z$frames[FALSE,]
 r<-run(z);expect_equal(nrow(r$full_edges),0);expect_type(r$full_edges$distance,'double');expect_type(r$full_edges$analysis_edge,'logical')
 z<-fixture();z$frames$unit<-'mm';expect_error(run(z),'units')
 z<-fixture();z$nodes$rank<-matrix(z$nodes$rank);expect_error(run(z),'Orders')
 expect_error(run(caps=c(bad=Inf)),'Caps');expect_error(run(caps=c(1,2)),'Caps')
})


test_that('native and marked UTF8 transport keys preserve explicit rank semantics', {
 z<-fixture();z$nodes$id<-c('α','β','γ');z$nodes$g<-'ομάδα';z$raw_edges$g<-'ομάδα';z$frames$g<-'ομάδα'
 marked<-run(z)
 for(tab in names(z))for(k in names(z[[tab]]))if(is.character(z[[tab]][[k]]))Encoding(z[[tab]][[k]])<-'unknown'
 native<-run(z)
 expect_equal(native$full_edges,marked$full_edges);expect_identical(native$analysis_edge_rows,marked$analysis_edge_rows)
 expect_equal(native$cap_flags,marked$cap_flags)
 expect_identical(enc2utf8(native$full_edges$from_id),c('β','β','γ'))
})
