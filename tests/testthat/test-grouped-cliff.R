test_that("Cliff pair counts match literal comparisons over ties and extremes", {
  evaluate <- function(a,b) {
    d<-data.frame(g="g",id=as.character(seq_len(length(a)+length(b))),
      arm=c(rep("A",length(a)),rep("B",length(b))),value=c(a,b))
    ContrastGroupedRanks(d,data.frame(g="g"),"g","id","arm","value",missing="available")
  }
  set.seed(813)
  cases<-list(list(c(2,4),c(1,2)),list(c(0,0),0),
    list(c(-.Machine$double.xmax,.Machine$double.xmax),c(0,.Machine$double.xmax)),
    list(c(-0,0,.Machine$double.xmin),c(0,-.Machine$double.xmin)))
  for(i in seq_len(100))cases[[length(cases)+1L]]<-list(sample(-5:5,sample(1:20,1),TRUE),sample(-5:5,sample(1:20,1),TRUE))
  for(z in cases) {
    a<-z[[1]];b<-z[[2]];got<-evaluate(a,b)
    greater<-sum(outer(a,b,">"));less<-sum(outer(a,b,"<"));tied<-sum(outer(a,b,"=="))
    expect_equal(got$n_a_greater,greater);expect_equal(got$n_a_less,less)
    expect_equal(got$n_tied,tied);expect_equal(got$n_pairs,length(a)*length(b))
    expect_identical(got$delta_a_vs_b,(greater-less)/(length(a)*length(b)))
    expect_equal(evaluate(b,a)$delta_a_vs_b,-got$delta_a_vs_b)
  }
})

test_that("Registry, missingness and returned keys remain explicit", {
  u<-intToUtf8(945);if(l10n_info()[["UTF-8"]])Encoding(u)<-"unknown"
  d<-data.frame(g=c(u,u,u,"only"),id=c("1","2","3","1"),arm=c("A","B","B","A"),value=c(3,1,NA,5))
  reg<-data.frame(g=c(u,"empty","only"));before<-serialize(list(d,reg),NULL)
  call<-function(m)ContrastGroupedRanks(d,reg,"g","id","arm","value",missing=m)
  x<-call("propagate");y<-call("available");at<-match(u,y$g)
  expect_identical(x$status,c("UNAVAILABLE","UNAVAILABLE","MISSING_VALUES"))
  expect_true(is.na(x$delta_a_vs_b[at]));expect_equal(y$delta_a_vs_b[at],1)
  expect_equal(y$n_pairs,c(0,0,1));expect_equal(y$n_b_unavailable,c(0,0,1))
  expect_identical(y$status[at],"PARTIAL");expect_identical(Encoding(y$g[at]),Encoding(u))
  expect_identical(serialize(list(d,reg),NULL),before)
  empty<-ContrastGroupedRanks(d[0,],reg[0,,drop=FALSE],"g","id","arm","value")
  expect_equal(nrow(empty),0);expect_type(empty$n_pairs,"double");expect_type(empty$delta_a_vs_b,"double")
  empty_arms<-ContrastGroupedRanks(d[0,],reg,"g","id","arm","value")
  expect_equal(empty_arms$n_pairs,rep(0,3));expect_true(all(is.na(empty_arms$delta_a_vs_b)))
  all_na<-d;all_na$value<-NA_real_
  expect_true(all(ContrastGroupedRanks(all_na,reg,"g","id","arm","value",missing="available")$status=="UNAVAILABLE"))
  permuted<-ContrastGroupedRanks(d[4:1,],reg[3:1,,drop=FALSE],"g","id","arm","value",missing="available")
  expect_identical(permuted,y)
})

test_that("Invalid contracts reject ambiguity instead of dropping rows", {
  d<-data.frame(g="g",id=c("a","b"),arm=c("A","B"),value=c(1,2));r<-data.frame(g="g")
  call<-function(data=d,reg=r,...)ContrastGroupedRanks(data,reg,"g","id","arm","value",...)
  expect_error(call(rbind(d,d)),"Duplicate observation")
  expect_error(call(reg=rbind(r,r)),"Duplicate registered")
  expect_error(call(reg=data.frame(g="other")),"unregistered")
  for(v in c(Inf,-Inf,NaN)){x<-d;x$value[1]<-v;expect_error(call(x),"finite numeric")}
  x<-d;x$arm[1]<-"C";expect_error(call(x),"arm must")
  x<-d;x$id[1]<-NA;expect_error(call(x),"Keys must")
  x<-d;x$g<-factor(x$g);expect_error(call(x),"Keys must")
  x<-d;x$value<-matrix(x$value,ncol=1);expect_error(call(x),"finite numeric")
  x<-d;x$g[1]<-paste0("g",intToUtf8(28));expect_error(call(x),"reserved separators")
  expect_error(call(missing="drop"),"arg")
  expect_error(ContrastGroupedRanks(d,r,"g","id","arm","id"),"distinct")
  expect_error(ContrastGroupedRanks(d,r,character(),"id","arm","value"),"group")
  expect_error(ContrastGroupedRanks(d,r,matrix("g"),"id","arm","value"),"group")
  expect_error(ContrastGroupedRanks(d,r,"g",c("id","x"),"arm","value"),"selected")
  names(d)[1]<-"status";names(r)[1]<-"status"
  expect_error(ContrastGroupedRanks(d,r,"status","id","arm","value"),"distinct")
})


test_that("User column names cannot bind paste control arguments", {
  for (group_name in c("sep", "collapse", "recycle0", "...")) {
    for (id_name in c("sep", "collapse", "recycle0", "...")) {
      if (identical(group_name, id_name)) next
      d <- data.frame(g = c("a", "a", "b", "b"), id = c("x", "y", "x", "y"),
        arm = c("A", "B", "A", "B"), value = c(2, 1, 1, 2))
      r <- data.frame(g = c("b", "a"))
      names(d)[1:2] <- c(group_name, id_name); names(r) <- group_name
      got <- ContrastGroupedRanks(d, r, group_name, id_name, "arm", "value")
      expect_identical(got$delta_a_vs_b, c(1, -1))
      expect_equal(got$n_pairs, c(1, 1))
      expect_identical(got[[group_name]], c("a", "b"))
    }
  }
  d <- data.frame(collapse = c("a", "a", "a", "a"), sep = c("x", "x", "y", "y"),
    recycle0 = c("i", "j", "i", "j"), arm = c("A", "B", "A", "B"), value = c(3, 1, 1, 3))
  r <- d[c(1, 3), c("collapse", "sep")]
  got <- ContrastGroupedRanks(d, r, c("collapse", "sep"), "recycle0", "arm", "value")
  expect_identical(got$delta_a_vs_b, c(1, -1))
  expect_equal(got$n_pairs, c(1, 1))
})
