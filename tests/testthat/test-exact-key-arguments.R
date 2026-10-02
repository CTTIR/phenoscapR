testthat::test_that('selected key/value names preserve weighted missingness and reject duplicate keys', {
  d <- data.frame(g=rep(c('alpha','beta'),each=3),id=rep(c('u','v','w'),2),x=c(1,NA,5,2,2,8),w=c(1,2,3,0,NA,2),y=c(5,NA,1,1,2,3))
  names_to_test <- c('sep','collapse','recycle0','...','.SD','.N','.I','.GRP','.BY','a space','grüppe','group_1','value_input','weight_input')
  expected <- SummarizeGroupedValues(d,'g','id','x','w',threshold=3,missing='available')
  testthat::expect_equal(expected$mean,c(3,4));testthat::expect_equal(expected$median,c(3,2));testthat::expect_equal(expected$fraction_at_least,c(.5,1/3));testthat::expect_equal(expected$weighted_mean,c(4,8));testthat::expect_equal(expected$weight_sum,c(4,2));testthat::expect_identical(expected$status,c('PARTIAL','COMPLETE'));testthat::expect_identical(expected$weighted_status,c('PARTIAL','PARTIAL'))
  expected_rank <- CorrelateGroupedRanks(d,'g','id','x','y',missing='available',min_pairs=2)
  testthat::expect_equal(expected_rank$rho,c(-1,sqrt(3)/2))
  for (nm in names_to_test) for (position in 1:5) {
    z<-d;names(z)[position]<-nm;before<-serialize(z,NULL);g<-names(z)[1];id<-names(z)[2];value<-names(z)[3];weight<-names(z)[4]
    result<-SummarizeGroupedValues(z,g,id,value,weight,threshold=3,missing='available');names(result)[1]<-'g';testthat::expect_identical(result,expected)
    rank<-CorrelateGroupedRanks(z,g,id,value,names(z)[5],missing='available',min_pairs=2);names(rank)[1]<-'g';testthat::expect_identical(rank,expected_rank);testthat::expect_identical(serialize(z,NULL),before)
    empty<-SummarizeGroupedValues(z[0,],g,id,value,weight,threshold=3);testthat::expect_equal(nrow(empty),0L);testthat::expect_identical(names(empty)[1],g)
    er<-CorrelateGroupedRanks(z[0,],g,id,value,names(z)[5]);testthat::expect_equal(nrow(er),0L)
    z[[id]][2]<-z[[id]][1];testthat::expect_error(SummarizeGroupedValues(z,g,id,value,weight),'Duplicate observation');testthat::expect_error(CorrelateGroupedRanks(z,g,id,value,names(z)[5]),'Duplicate observation')
  }
})
testthat::test_that('composite keys and named selectors preserve independent groups and input tables', {
 d<-data.frame(a=rep(c('ab','a'),each=3),b=rep(c('c','bc'),each=3),id=rep(letters[1:3],2),x=c(1,3,5,2,4,6),w=rep(1,6),y=c(5,3,1,2,4,6))
 for(nm in c('collapse','sep','recycle0','...','.SD','.N')){
  z<-d;names(z)[1:2]<-c(nm,'other group');before<-serialize(z,NULL)
  result<-SummarizeGroupedValues(z,setNames(c(nm,'other group'),c('collapse','sep')),'id','x','w',threshold=3)
  testthat::expect_equal(nrow(result),2L);testthat::expect_equal(sort(result$mean),c(3,4));testthat::expect_identical(serialize(z,NULL),before)
  rank<-CorrelateGroupedRanks(z,c(nm,'other group'),'id','x','y');testthat::expect_equal(sort(rank$rho),c(-1,1))
  dt<-data.table::as.data.table(z);prior<-data.table::copy(dt);SummarizeGroupedValues(dt,c(nm,'other group'),'id','x','w');testthat::expect_identical(dt,prior)
 }
})
testthat::test_that('missingness policy, minimum and zero weights retain explicit states', {
 d<-data.frame(g=rep(c('a','b'),each=3),id=rep(letters[1:3],2),x=c(1,NA,5,2,2,8),w=c(1,2,3,0,NA,2))
 p<-SummarizeGroupedValues(d,'g','id','x','w');testthat::expect_true(is.na(p$mean[1]));testthat::expect_equal(p$mean[2],4);testthat::expect_true(all(is.na(p$weighted_mean)))
 p<-SummarizeGroupedValues(d,'g','id','x','w',min_available=3,missing='available');testthat::expect_identical(p$status,c('INSUFFICIENT','COMPLETE'));testthat::expect_identical(p$weighted_status,rep('INSUFFICIENT',2));testthat::expect_true(all(is.na(p$weighted_mean)))
 d$w<-0;p<-SummarizeGroupedValues(d,'g','id','x','w',missing='available');testthat::expect_equal(p$weight_sum,c(0,0));testthat::expect_identical(p$weighted_status,rep('NO_POSITIVE_WEIGHT',2))
 d$g[1]<-'bad\034key';testthat::expect_error(SummarizeGroupedValues(d,'g','id','x'),'reserved separators')
})
testthat::test_that('Unicode values and unusual names preserve unweighted and paired summaries', {
  d<-data.frame(g=c('café','café','café','東京','東京','東京'),id=rep(c('á','β','中'),2),x=c(1,3,5,2,4,6),y=c(5,3,1,2,4,6))
  for(nm in c('collapse','sep','recycle0','...','.SD','.N')){
    z<-d;names(z)[1]<-nm;before<-serialize(z,NULL)
    value<-SummarizeGroupedValues(z,nm,'id','x',threshold=3);testthat::expect_equal(sort(value$mean),c(3,4));testthat::expect_true(all(value$weighted_status=='NOT_REQUESTED'));testthat::expect_true(all(is.na(value$weight_sum)));testthat::expect_identical(serialize(z,NULL),before)
    rank<-CorrelateGroupedRanks(z,nm,'id','x','y');testthat::expect_equal(sort(rank$rho),c(-1,1))
    z$id[2]<-enc2utf8(z$id[1]);testthat::expect_error(SummarizeGroupedValues(z,nm,'id','x'),'Duplicate observation');testthat::expect_error(CorrelateGroupedRanks(z,nm,'id','x','y'),'Duplicate observation')
  }
})
