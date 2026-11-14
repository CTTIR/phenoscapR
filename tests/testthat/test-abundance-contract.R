abundance_contract_object <- function() {
 md<-data.frame(cell_id=letters[1:8],sample_id=rep(paste0('s',1:4),each=2),
                 arm=rep(c('ctrl','trt'),each=4),phenotype=rep(c('A','B'),4))
 CreateSpatialObject(matrix(1:8,8,1,dimnames=list(NULL,'m')),data.frame(x=1:8,y=0),md)
}

test_that('unknown phenotype summaries do not silently become inference denominators', {
 o<-abundance_contract_object();o@meta_data$phenotype[2]<-NA_character_;before<-o
 summary<-PhenotypeSummary(o)
 expect_equal(summary$proportion[summary$sample_id=='s1'],c(.5,.5))
 expect_true(anyNA(summary$phenotype))
 expect_error(DifferentialAbundance(o,'arm'),'complete, nonblank phenotype')
 expect_identical(o,before)
 for (value in c('','  ')) {
  o@meta_data$phenotype[2]<-value
  expect_error(DifferentialAbundance(o,'arm'),'complete, nonblank phenotype')
 }
})

test_that('differential abundance columns have one scalar label per cell', {
 for (name in c('sample_id','arm','phenotype')) {
  o<-abundance_contract_object();o@meta_data[[name]]<-matrix(o@meta_data[[name]])
  expect_error(DifferentialAbundance(o,'arm'),'dimensionless vector')
 }
 o<-abundance_contract_object()
 for(name in list(character(),c('arm','phenotype'),NA_character_,matrix('arm'))) {
  expect_error(DifferentialAbundance(o,name),'Selected columns')
 }
})

test_that('section composition rejects manufactured cell and area rows', {
 d<-data.frame(type=c('A','B'),area=c(10,20),flag=c(1,0))
 before<-d
 bad<-d;bad$type<-cbind(d$type,d$type)
 expect_error(SummarizeCellComposition(bad,'type',c('A','B')),'dimensionless vector')
 for(a in list(factor(c('10','20')),matrix(c(10,20)),c(10,NA),c(10,Inf),c(-1,2),c(1+1i,2))) {
  bad<-d;bad$area<-a;copy<-bad
  expect_error(SummarizeCellComposition(bad,'type',c('A','B'),area='area'),'Areas must')
  expect_identical(bad,copy)
 }
 for(divisor in list(0,-1,Inf,NA_real_,matrix(1),c(1,2),1+1i)) {
  expect_error(SummarizeCellComposition(d,'type',c('A','B'),area='area',area_divisor=divisor),'area_divisor')
 }
 for(a in list(c(0,0),rep(.Machine$double.xmax,2))) {
  bad<-d;bad$area<-a
  expect_error(SummarizeCellComposition(bad,'type',c('A','B'),area='area'),'aggregate area')
 }
 bad<-d;bad$flag<-cbind(d$flag,d$flag)
 expect_error(SummarizeCellComposition(bad,'type',c('A','B'),fractions=list(
  x=list(numerator='A',denominator=c('A','B'),flag='flag'))),'0/1')
 expect_identical(d,before)
})

test_that('registered subset membership is required even when counts coincide', {
 d<-data.frame(type=c('A','B'),area=c(0,20))
 expect_error(SummarizeCellComposition(d,'type',c('A','B'),fractions=list(
  x=list(numerator='A',denominator='B'))),'subset of denominator')
 expect_error(SummarizeCellComposition(d,'type',c('A','B'),fractions=list(
  x=list(numerator='absent',denominator=c('A','B','absent')))),'registered')
 out<-SummarizeCellComposition(d,'type',c('A','B','C'),area='area',fractions=list(
  x=list(numerator='C',denominator=c('A','B','C'))))
 expect_equal(out$value[out$endpoint=='x'],0)
 expect_equal(out$value[out$endpoint=='density|A'],1/20)
 empty<-SummarizeCellComposition(d[FALSE,],'type',c('A','B'))
 expect_true(all(is.na(empty$value[empty$measure=='fraction'])))
 expect_equal(empty$value[empty$measure=='total'],0)
 expect_error(SummarizeCellComposition(d[FALSE,],'type',c('A','B'),area='area'),'aggregate area')
})

test_that('declared sample units retain equal weight despite unequal cell counts', {
 size<-c(1L,3L,4L,10L);positive<-c(1L,1L,0L,8L)
 md<-do.call(rbind,lapply(1:4,function(i)data.frame(sample_id=paste0('s',i),
   patient_id=if(i<3)'p1'else'p2',arm=if(i<3)'ctrl'else'trt',
   phenotype=c(rep('A',positive[i]),rep('B',size[i]-positive[i])))))
 md$cell_id<-paste0('c',seq_len(nrow(md)))
 o<-CreateSpatialObject(matrix(seq_len(nrow(md)),ncol=1,dimnames=list(NULL,'m')),
                         data.frame(x=seq_len(nrow(md)),y=0),md)
 result<-DifferentialAbundance(o,'arm',test='t');a<-result[result$phenotype=='A',]
 x<-c(1,1/3);y<-c(0,.8);se2<-var(x)/2+var(y)/2
 statistic<-(mean(x)-mean(y))/sqrt(se2)
 df<-se2^2/((var(x)/2)^2+(var(y)/2)^2)
 expect_equal(a$mean_ctrl,mean(x));expect_equal(a$mean_trt,mean(y))
 expect_equal(a$statistic,statistic)
 expect_equal(a$p_value,2*pt(-abs(statistic),df))
 idx<-c(rep(which(md$sample_id=='s2'),5),which(md$sample_id!='s2'))
 expect_equal(DifferentialAbundance(o[idx,],'arm',test='t'),result)
 o@meta_data$patient_id<-seq_len(nrow(md))
 expect_equal(DifferentialAbundance(o,'arm',test='t'),result)
})
