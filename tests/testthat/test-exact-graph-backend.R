.ed_bind_calls <- getFromNamespace(".ed_bind_calls", "phenoscapR")
.ed_build_geometry <- getFromNamespace(".ed_build_geometry", "phenoscapR")
.ed_contract <- getFromNamespace(".ed_contract", "phenoscapR")
.ed_result <- getFromNamespace(".ed_result", "phenoscapR")
.ed_strict <- getFromNamespace(".ed_strict", "phenoscapR")
contract <- function()list(package_version='2.0-4',description_sha256=strrep('a',64),
 native_library_sha256=strrep('b',64),binsrtR_body_serialized_sha256=strrep('c',64),
 binsrtR_body_deparse_sha256=strrep('d',64),wrapper_body_serialized_sha256=strrep('e',64),wrapper_body_deparse_sha256=strrep('f',64),digOutxy_body_serialized_sha256=strrep('1',64),digOutxy_body_deparse_sha256=strrep('2',64),digOutz_body_serialized_sha256=strrep('3',64),digOutz_body_deparse_sha256=strrep('4',64),binsrt_num_parameters=9L,master_num_parameters=16L)
test_that('backend contract rejects pointers and malformed pins before backend access',{
 expect_true(.ed_contract(contract()))
 z<-contract();z$master_symbol<-list();expect_error(.ed_contract(z),'exactly')
 z<-contract();z$package_version<-'2.0-5';expect_error(.ed_contract(z),'profile')
 for(k in names(contract())[2:11])for(bad in list('',NA_character_,strrep('G',64),matrix(strrep('a',64)))){
  z<-contract();z[[k]]<-bad;expect_error(.ed_contract(z),'digest')
 }
 for(k in c('binsrt_num_parameters','master_num_parameters')) {
  z<-contract();z[[k]]<-matrix(z[[k]]);expect_error(.ed_contract(z),'arities')
 }
 expect_error(.ed_build_geometry(c(0,1,0),c(0,0,1),contract(),NA_real_,'stock'),'eps')
})
test_that('native output validation is pure and fails malformed lengths and flags',{
 p<-PlanExactDelaunayWorkspace(3,'bounded')
 r<-lapply(p$native_lengths,numeric);r$incAdj<-0L;r$incSeg<-0L
 expect_true(.ed_result(r,p))
 for(k in names(r)) {
  z<-r;z[[k]]<-c(z[[k]],0);expect_error(.ed_result(z,p),'lengths')
 }
 for(flag in c('incAdj','incSeg'))for(bad in c(NA_real_,Inf,-1,0.5,2)){
  z<-r;z[[flag]]<-bad;expect_error(.ed_result(z,p),'flags')
 }
 expect_error(.ed_strict(warning('synthetic')),'Backend warning')
 expect_error(.ed_strict(message('synthetic')),'Unexpected backend message')
})


test_that('cloned call environments leave originals unchanged and reject unsafe dispatch', {
 ns<-new.env(parent=baseenv());s<-function() .Fortran('other',PACKAGE='deldir')
 w<-function() binsrtR();environment(s)<-ns;environment(w)<-ns
 ns$binsrtR<-s;original_s<-environment(s);original_w<-environment(w)
 bound<-.ed_bind_calls(s,w,list(binsrt=NULL,master=NULL),ns)
 expect_identical(environment(s),original_s);expect_identical(environment(w),original_w)
 expect_identical(ns$binsrtR,s);expect_true(environmentIsLocked(environment(bound$sorter)))
 expect_false(identical(environment(bound$sorter),environment(bound$wrapper)))
 expect_identical(parent.env(environment(bound$sorter)),original_s)
 expect_identical(parent.env(environment(bound$wrapper)),original_w)
 expect_error(bound$sorter(),'Unapproved');expect_error(bound$wrapper(),'Unapproved')
 bridge<-get('.Fortran',environment(bound$wrapper))
 expect_error(bridge('master',PACKAGE='other'),'Unapproved')
 expect_error(bridge(list(),PACKAGE='deldir'),'Unapproved')
})


test_that('private lexical helpers remain available without namespace mutation', {
 ns<-new.env(parent=baseenv());private<-new.env(parent=ns)
 private$digOutxy<-function(x,y,znm)list(x=x,y=y)
 private$digOutz<-function(z1,znm,x)z1
 w<-function(x,y){xy<-digOutxy(x,y,'z');digOutz(NULL,'z',x);xy}
 environment(w)<-private;s<-function()NULL;environment(s)<-ns
 before<-ls(private);bound<-.ed_bind_calls(s,w,list(binsrt=NULL,master=NULL),ns)
 expect_identical(bound$wrapper(1:3,4:6),list(x=1:3,y=4:6))
 expect_identical(ls(private),before);expect_identical(environment(w),private)
 expect_identical(parent.env(environment(bound$wrapper)),private)
})
