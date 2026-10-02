overlap_fixture <- function() {
  data.frame(group = 'A', stratum = rep(c('one','two','three','four','five'),c(3,4,2,1,2)),
    cell = paste0('cell',seq_len(12)),
    label = c(TRUE,TRUE,FALSE, TRUE,FALSE,FALSE,FALSE, TRUE,FALSE, TRUE, TRUE,FALSE),
    metric = c(10,14,2,20,4,8,12,NA,6,30,Inf,NaN))
}
run_overlap_fixture <- function(data=overlap_fixture(), quality=NULL,
                                registry=data.frame(group=c('A','B'))) {
  ContrastGroupedOverlap(data,registry,'group','stratum','cell','label','metric',quality)
}

test_that('hand-calculated unequal strata retain all three denominators', {
  r <- run_overlap_fixture(); s <- r$summary[1,]
  expect_equal(unname(unlist(s[c('n_policy','n_positive_policy','n_control_policy',
    'n_evaluable','n_positive_evaluable','n_control_evaluable','n_unavailable')])),
    c(12,6,6,9,4,5,3))
  expect_equal(unname(unlist(s[c('n_strata_policy','n_strata_evaluable','n_overlap_strata',
    'n_positive_overlap','n_control_overlap')])),c(5,4,2,3,4))
  expect_equal(s$positive_coverage_policy,1/2)
  expect_equal(s$positive_coverage_evaluable,3/4)
  expect_equal(s$positive_evaluable_fraction,2/3)
  expect_equal(s$control_evaluable_fraction,5/6)
  expect_equal(s$positive_mean,44/3)
  expect_equal(s$control_weighted_mean,4)
  expect_equal(s$contrast,32/3)
  expect_equal(s$control_weight_sum,3)
  expect_equal(s$control_effective_n,27/13)
  expect_identical(s$status,'DEFINED');expect_identical(s$availability_status,'PARTIAL')
  o <- r$observations; w <- setNames(o$weight,o$cell)
  expect_equal(unname(w[paste0('cell',1:7)]),c(1,1,2,1,1/3,1/3,1/3))
  expect_true(all(is.na(w[paste0('cell',8:12)])))
  expect_equal(nrow(r$strata),5);expect_equal(sum(r$strata$overlap),2)
  expect_equal(sum(o$status=='NONFINITE_VALUE'),3)
})

test_that('empty groups and no-overlap populations are not invented zeros', {
  r<-run_overlap_fixture();s<-r$summary[2,]
  expect_identical(s$status,'EMPTY_GROUP');expect_equal(s$n_policy,0)
  expect_true(is.na(s$positive_mean));expect_true(is.na(s$positive_coverage_policy))
  expect_equal(s$control_weight_sum,0);expect_true(is.na(s$control_effective_n))
  d<-overlap_fixture();d$metric<-NA_real_;s<-run_overlap_fixture(d)$summary[1,]
  expect_identical(s$status,'NO_EVALUABLE_VALUES');expect_equal(s$n_policy,12)
  expect_equal(s$positive_coverage_policy,0);expect_true(is.na(s$positive_coverage_evaluable))
  d<-overlap_fixture();d$label<-TRUE;s<-run_overlap_fixture(d)$summary[1,]
  expect_identical(s$status,'NO_OVERLAP');expect_equal(s$n_control_policy,0)
  d$label<-FALSE;expect_identical(run_overlap_fixture(d)$summary$status[1],'NO_OVERLAP')
  z<-run_overlap_fixture(d[FALSE,],registry=data.frame(group=character()))
  expect_equal(nrow(z$summary),0);expect_type(z$summary$status,'character')
  expect_type(z$observations$weight,'double');expect_type(z$strata$overlap,'logical')
})

test_that('quality criteria do not suppress finite contrasts or choose a population', {
  plain<-run_overlap_fixture()
  r<-run_overlap_fixture(quality=list(min_positive_policy=6,min_positive_evaluable=4,
    min_positive_overlap=4,min_policy_coverage=.5,min_evaluable_coverage=.75,min_control_ess=2))
  expect_identical(r$summary$contrast,plain$summary$contrast)
  expect_identical(r$summary$quality_status[1],'FAIL')
  expect_identical(r$summary$quality_reasons[1],'min_positive_overlap')
  expect_identical(run_overlap_fixture(quality=list(min_positive_overlap=3))$summary$quality_status[1],'PASS')
  expect_true(all(plain$summary$quality_status=='NOT_REQUESTED'))
  expect_error(run_overlap_fixture(quality=list(min_positive_policy=1.5)),'integers')
  expect_error(run_overlap_fixture(quality=list(min_policy_coverage=1.1)),'exceed one')
  expect_error(run_overlap_fixture(quality=list(unknown=1)),'supported')
})

test_that('observation, registry and stratum keys resist order and column capture', {
  d<-overlap_fixture();expected<-run_overlap_fixture(d)
  set.seed(19);expect_identical(run_overlap_fixture(d[sample(nrow(d)),],
    registry=data.frame(group=c('B','A'))),expected)
  for(name in c('.SD','.N','.I','.GRP','.BY','method','decreasing','na.last','collapse','recycle0')) {
    x<-d;r<-data.frame(group=c('A','B'));names(x)[1]<-name;names(r)[1]<-name
    actual<-ContrastGroupedOverlap(x,r,name,'stratum','cell','label','metric')
    for(table in c('summary','strata','observations'))names(actual[[table]])[1]<-'group'
    expect_identical(actual,expected)
  }
  clone<-d;clone$group<-'B';expect_equal(run_overlap_fixture(rbind(d,clone))$summary$n_policy,c(12,12))
  d<-overlap_fixture();d$cell[2]<-d$cell[1];d$stratum[2]<-'different'
  expect_error(run_overlap_fixture(d),'duplicate observation')
})

test_that('invalid schemas and ambiguous memberships fail closed', {
  d<-overlap_fixture();d$label[1]<-NA;expect_error(run_overlap_fixture(d),'membership')
  d<-overlap_fixture();d$label<-as.integer(d$label);expect_error(run_overlap_fixture(d),'membership')
  d<-overlap_fixture();d$group<-factor(d$group);expect_error(run_overlap_fixture(d),'character')
  d<-overlap_fixture();d$stratum[1]<-NA;expect_error(run_overlap_fixture(d),'nonmissing')
  d<-overlap_fixture();d$metric<-matrix(d$metric,ncol=1);expect_error(run_overlap_fixture(d),'real numeric')
  d<-overlap_fixture();d$metric<-as.complex(d$metric);expect_error(run_overlap_fixture(d),'real numeric')
  expect_error(run_overlap_fixture(registry=data.frame(group=c('A','A'))),'duplicate registry')
  expect_error(run_overlap_fixture(registry=data.frame(group='B')),'absent from registry')
})

test_that('stable means retain extremes and fail closed on unrepresentable output', {
  d<-data.frame(group='A',stratum='s',cell=letters[1:4],label=c(TRUE,TRUE,FALSE,FALSE),metric=0)
  high<-.Machine$double.xmax
  d$metric<-rep(high,4);s<-run_overlap_fixture(d)$summary[1,]
  expect_equal(s$positive_mean,high);expect_equal(s$control_weighted_mean,high)
  expect_identical(s$contrast,0)
  d$metric<-c(high,-high,0,0);expect_identical(run_overlap_fixture(d)$summary$contrast[1],0)
  d$metric<-c(high,high,-high,-high);expect_error(run_overlap_fixture(d),'range exceeded in contrast')
  tiny<-.Machine$double.xmin*.Machine$double.eps
  d$metric<-c(tiny,tiny,0,0);expect_identical(run_overlap_fixture(d)$summary$positive_mean[1],tiny)
  d$metric<-c(high,tiny,0,0);expect_error(run_overlap_fixture(d),'range exceeded scaling')
  d$metric<-c(tiny,0,0,0);expect_error(run_overlap_fixture(d),'range exceeded in metric mean')
})

test_that('unequal count ratios retain small positive weights and stable ESS', {
  n<-1024L
  d<-data.frame(group='A',stratum=rep(c('small','large'),each=n+1L),
    cell=paste0('id',seq_len(2L*(n+1L))),label=c(TRUE,rep(FALSE,n),rep(TRUE,n),FALSE),metric=1)
  r<-run_overlap_fixture(d);s<-r$summary[1,]
  expect_equal(s$control_weight_sum,n+1)
  expect_equal(s$control_effective_n,(n+1)^2/(n^2+1/n))
  expect_equal(s$control_weighted_mean,1)
  expect_identical(s$contrast,0)
  expect_equal(sort(unique(r$observations$weight)),c(1/n,1,n))
})


test_that('stratum and selected value names never capture implementation columns', {
  d<-overlap_fixture();r<-data.frame(group=c('A','B'));expected<-run_overlap_fixture(d)
  x<-d;names(x)<-c('group','.BY','.I','.N','.SD')
  actual<-ContrastGroupedOverlap(x,r,'group','.BY','.I','.N','.SD')
  names(actual$strata)[names(actual$strata)=='.BY']<-'stratum'
  names(actual$observations)[names(actual$observations)=='.BY']<-'stratum'
  names(actual$observations)[names(actual$observations)=='.I']<-'cell'
  expect_identical(actual,expected)
  d$cell<-matrix(d$cell,ncol=1);expect_error(run_overlap_fixture(d),'character vectors')
  expect_error(run_overlap_fixture(quality=list(min_control_ess=matrix(1))), 'scalars')
})

test_that('UTF-8 and separator-like keys preserve group identity', {
  d<-data.frame(group=rep(c('a:1','a','\u03b2'),each=2),
    stratum=rep(c('b','1:b','\u00e9|block'),each=2),
    cell=rep(c('\u00e9|1','\u00e9|2'),3),label=rep(c(TRUE,FALSE),3),
    metric=c(3,1,10,4,5,5))
  r<-run_overlap_fixture(d,registry=data.frame(group=c('a','a:1','\u03b2')))
  expect_equal(r$summary$contrast[match(c('a','a:1','\u03b2'),r$summary$group)],c(6,2,0))
  expect_equal(nrow(r$strata),3);expect_true(all(r$observations$weight==1))
  q<-run_overlap_fixture(quality=list(min_positive_policy=0))$summary
  expect_identical(q$status[2],'EMPTY_GROUP');expect_identical(q$quality_status[2],'PASS')
})
