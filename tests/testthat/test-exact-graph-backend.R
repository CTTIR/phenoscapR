.ed_build_geometry <- getFromNamespace(".ed_build_geometry", "phenoscapR")
.ed_strict <- getFromNamespace(".ed_strict", "phenoscapR")
.ed_workspace_growth <- getFromNamespace(".ed_workspace_growth", "phenoscapR")

test_that('constructor arguments and strict conditions fail before any backend call',{
 expect_error(.ed_build_geometry(c(0,1,0),c(0,0,1),NULL,NA_real_,'stock'),'eps')
 expect_error(.ed_build_geometry(c(0,1,0),c(0,0,1),NULL,1e-9,'other'),'arg')
 expect_error(.ed_build_geometry(c(0,1,0,0),c(0,0,1,0),NULL,1e-9,'stock'),'Duplicate')
 expect_error(.ed_build_geometry(c(0,1,2),c(0,1,2),NULL,1e-9,'stock'),'Two-dimensional')
 expect_error(.ed_strict(warning('synthetic')),'Backend warning')
 expect_error(.ed_strict(message('synthetic')),'Unexpected backend message')
 expect_true(.ed_workspace_growth('Increasing madj from 26 to 32 and trying again.'))
 expect_true(.ed_workspace_growth('Increasing ndel and ndir from 351 to 422 and trying again.'))
 expect_false(.ed_workspace_growth('Some other message'))
})

test_that('frames beyond the integer workspace of deldir are refused before construction',{
 n<-799800
 expect_error(.ed_build_geometry(as.double(seq_len(n)),rep(0,n),NULL,1e-9,'auto'),'integer workspace')
 expect_error(.ed_build_geometry(as.double(seq_len(n)),rep(0,n),NULL,1e-9,'bounded'),'integer workspace')
 expect_error(.ed_build_geometry(as.double(seq_len(n)),rep(0,n),NULL,1e-9,'stock'),'spare')
})

test_that('construction uses public deldir and ignores a supplied backend contract',{
 skip_if_not_installed('deldir')
 x<-c(0,4,3,0,2);y<-c(0,0,3,1,1.5)
 a<-.ed_build_geometry(x,y,NULL,1e-9,'stock')
 b<-.ed_build_geometry(x,y,list(package_version='2.0-4'),1e-9,'bounded')
 expect_identical(a$raw_edges,b$raw_edges)
 dd<-deldir::deldir(x,y,rw=a$window$bounds,eps=1e-9,sort=TRUE,round=FALSE)
 expect_identical(a$raw_edges,dd$delsgs[c('ind1','ind2','x1','y1','x2','y2')])
 expect_identical(a$provenance$interface,'deldir::deldir')
 expect_identical(a$provenance$deldir_version,as.character(utils::packageVersion('deldir')))
 expect_identical(a$provenance$workspace_growth,0L)
 expect_identical(b$provenance$requested_mode,'bounded')
})
