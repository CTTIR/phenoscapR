testthat::test_that('summary keys reject matrix columns before composite-key construction', {
  for (key in c('g','id')) for (columns in 1:2) {
    d<-data.frame(g=rep('a',3),id=letters[1:3],x=1:3,y=3:1)
    d[[key]]<-matrix(letters[seq_len(3*columns)],nrow=3)
    testthat::expect_error(SummarizeGroupedValues(d,'g','id','x'),'Keys|dimension')
    testthat::expect_error(CorrelateGroupedRanks(d,'g','id','x','y'),'Keys|dimension')
  }
})
