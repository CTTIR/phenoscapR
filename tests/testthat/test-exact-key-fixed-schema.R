testthat::test_that('exact and family consumers reject dimensioned keys with ordinary controls', {
 e<-data.frame(endpoint_id='e',patient_id=letters[1:4],value=1:4,eligible=TRUE)
 d<-data.frame(contrast_id='c',patient_id=letters[1:4],group=c('A','A','B','B'))
 h<-data.frame(hypothesis_id='h',endpoint_id='e',contrast_id='c',family_id='f')
 before<-serialize(list(e,d,h),NULL);result<-ExactPatientTests(e,d,h)
 testthat::expect_equal(result$mean_difference,-2);testthat::expect_equal(result$p_value,1/3);testthat::expect_identical(serialize(list(e,d,h),NULL),before)
 for(which in 1:3)for(key in list(c('endpoint_id','patient_id'),c('contrast_id','patient_id','group'),c('hypothesis_id','endpoint_id','contrast_id','family_id'))[[which]])for(nc in 1:2){
  args<-list(e,d,h);args[[which]][[key]]<-matrix(rep(args[[which]][[key]],nc),ncol=nc);testthat::expect_error(do.call(ExactPatientTests,args),'Keys')
 }
 tests<-data.frame(hypothesis_id=c('h1','h2','h3'),family_id='f',p_value=c(.01,.04,NA));before<-serialize(tests,NULL);adj<-AdjustPatientFamilies(tests,'declared');testthat::expect_equal(adj$tests$p_adjusted,c(.03,.06,NA));testthat::expect_identical(serialize(tests,NULL),before)
 for(key in c('hypothesis_id','family_id'))for(nc in 1:2){z<-tests;z[[key]]<-matrix(rep(z[[key]],nc),ncol=nc);testthat::expect_error(AdjustPatientFamilies(z,'declared'),'Keys')}
})
testthat::test_that('fixed grid assignment and summary reject dimensioned registry keys', {
 cells<-data.frame(cell_id=c('a','b'),sample_id='s',frame_id='physical',x=c(-1,10),y=c(0,0))
 settings<-data.frame(setting_id='g',size_um=10,offset_x_um=0,offset_y_um=0)
 frames<-data.frame(sample_id='s',frame_id='physical',unit='um')
 before<-serialize(list(cells,settings,frames),NULL);m<-AssignFixedGrid(cells,settings,frames);testthat::expect_equal(m$grid_x,c(-1L,1L));testthat::expect_identical(serialize(list(cells,settings,frames),NULL),before)
 for(which in 1:3)for(key in list(c('cell_id','sample_id','frame_id'),'setting_id',c('sample_id','frame_id'))[[which]])for(nc in 1:2){args<-list(cells,settings,frames);args[[which]][[key]]<-matrix(rep(args[[which]][[key]],nc),ncol=nc);testthat::expect_error(do.call(AssignFixedGrid,args),'Keys')}
 ann<-data.frame(sample_id='s',cell_id=c('a','b'),type=c('A','B'),signal=c(TRUE,NA));before<-serialize(list(m,ann,settings),NULL);s<-SummarizeFixedGrid(m,ann,settings,'type','signal');testthat::expect_equal(s$bins$n_cells,c(1L,1L));testthat::expect_identical(serialize(list(m,ann,settings),NULL),before)
 for(which in 1:3)for(key in list(c('setting_id','sample_id','cell_id','frame_id'),c('sample_id','cell_id'),'setting_id')[[which]])for(nc in 1:2){args<-list(m,ann,settings,'type','signal');args[[which]][[key]]<-matrix(rep(args[[which]][[key]],nc),ncol=nc);testthat::expect_error(do.call(SummarizeFixedGrid,args),'Keys')}
})
