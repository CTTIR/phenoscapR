test_that("explicit patient omissions retain exact statistics and availability", {
  checks <- 0L
  ok <- function(x) {expect_true(isTRUE(x)); checks <<- checks + 1L}
  reject <- function(expr) ok(inherits(tryCatch(force(expr),error=function(e)e),'error'))
  e <- data.frame(endpoint_id='e',patient_id=letters[1:4],value=1:4,eligible=TRUE)
  d <- data.frame(contrast_id='c',patient_id=letters[1:4],group=c('A','A','B','B'))
  h <- data.frame(hypothesis_id='h',endpoint_id='e',contrast_id='c',family_id='f')
  o <- data.frame(hypothesis_id='h',patient_id=letters[1:4])
  x <- LeaveOnePatientOut(e,d,h,o)
  ok(x$full_tests$mean_difference == -2)
  ok(x$full_tests$p_value == 1/3 && x$full_tests$allocations == 6)
  ok(identical(x$omissions$mean_difference,c(-1.5,-2.5,-2.5,-1.5)))
  ok(identical(x$omissions$p_value,c(2/3,1/3,1/3,2/3)) && all(x$omissions$allocations == 3))
  ok(all(x$omissions$probability_grid_step == 1/3))
  ok(all(x$omissions$absolute_effect_change == .5))
  ok(all(x$omissions$effect_direction_preserved))
  ok(identical(x$omissions$omitted_patient,letters[1:4]))
  for (kind in c('missing','ineligible','absent')) {
   z <- e
   if (kind=='missing') z$value[1] <- NA_real_
   if (kind=='ineligible') z$eligible[1] <- FALSE
   if (kind=='absent') z <- z[-1,]
   y <- LeaveOnePatientOut(z,d,h,o)
   ok(all(y$omissions$reduced_status=='UNAVAILABLE_FULL_INCOMPLETE'))
   ok(all(is.na(y$omissions$p_value)) && all(is.na(y$omissions$allocations)))
   ok(y$omissions$n_a_evaluable[1]==1 && y$omissions$n_a_evaluable[2]==0)
   ok(y$omissions$n_a_supplied[2]==if(kind=='absent')0 else 1)
  }
  s <- LeaveOnePatientOut(e[1:3,],transform(d[1:3,],group=c('A','B','B')),h,o[1:3,])
  ok(s$omissions$empty_arm[1] && s$omissions$reduced_status[1]=='UNAVAILABLE_EMPTY_ARM')
  ok(is.na(s$omissions$allocations[1]) && s$omissions$n_a_expected[1]==0)
  se <- e[1:3,];se$value[1]<-NA_real_
  s <- LeaveOnePatientOut(se,transform(d[1:3,],group=c('A','B','B')),h,o[1:3,])
  ok(s$omissions$empty_arm[1] && s$omissions$reduced_status[1]=='UNAVAILABLE_FULL_INCOMPLETE')
  z <- e; z$value <- 1
  s <- LeaveOnePatientOut(z,d,h,o)
  ok(all(s$omissions$p_value==1) && all(s$omissions$full_effect_direction=='ZERO'))
  ok(all(s$omissions$reduced_effect_direction=='ZERO') && all(s$omissions$effect_direction_preserved))
  z$value <- c(0,4,1,3);s <- LeaveOnePatientOut(z,d,h,o)
  ok(all(s$omissions$full_effect_direction=='ZERO') && !any(s$omissions$effect_direction_preserved))
  empty <- LeaveOnePatientOut(e,d,h,o[FALSE,])$omissions
  ok(nrow(empty)==0 && identical(names(empty),names(x$omissions)))
  ok(is.character(empty$reduced_status) && is.logical(empty$empty_arm) && is.double(empty$p_value))
  reject(LeaveOnePatientOut(e,d,h,rbind(o,o[1,])))
  u<-o;u$hypothesis_id[1]<-'bad';reject(LeaveOnePatientOut(e,d,h,u))
  u<-o;u$patient_id[1]<-'outside';reject(LeaveOnePatientOut(e,d,h,u))
  u<-o;u$patient_id[1]<-NA;reject(LeaveOnePatientOut(e,d,h,u))
  u<-o;u$patient_id[1]<-' ';reject(LeaveOnePatientOut(e,d,h,u))
  u<-o;u$patient_id<-I(matrix(letters[1:4],4));reject(LeaveOnePatientOut(e,d,h,u))
  reject(LeaveOnePatientOut(e,d,h,o,max_allocations=5))
  reject(LeaveOnePatientOut(e,d,h,o,missingness='available'))
  snapshot <- serialize(list(e,d,h,o),NULL)
  y <- LeaveOnePatientOut(e[4:1,],d[c(2,4,1,3),],h,o[4:1,])
  ok(identical(y$omissions$mean_difference,rev(x$omissions$mean_difference)))
  ok(identical(y$omissions$omitted_patient,rev(o$patient_id)))
  ok(identical(snapshot,serialize(list(e,d,h,o),NULL)))
  edt <- data.table::as.data.table(e); edt[,ignored:=list(list(1),list(2),list(3),list(4))]
  before <- serialize(edt,NULL);y <- LeaveOnePatientOut(edt,d,h,o)
  ok(identical(before,serialize(edt,NULL)))
  ok(identical(y$omissions,x$omissions))
  # Additional endpoint observations outside the selected contrast must not leak.
  e2<-rbind(e,data.frame(endpoint_id='e',patient_id='extra',value=1000,eligible=TRUE))
  d2<-rbind(d,data.frame(contrast_id='other',patient_id=c('extra','a'),group=c('A','B')))
  h2<-rbind(h,data.frame(hypothesis_id='other',endpoint_id='e',contrast_id='other',family_id='f'))
  y<-LeaveOnePatientOut(e2,d2,h2,o)
  ok(identical(y$omissions,x$omissions))
  # Independent literal exhaustive enumeration for all 81 four-observation vectors.
  vv<-expand.grid(rep(list(c(-1,0,2)),4))
  for(i in seq_len(nrow(vv))) {
   z<-e;z$value<-as.numeric(vv[i,]);y<-LeaveOnePatientOut(z,d,h,o)
   literal<-function(v,a) {delta<-mean(v[a])-mean(v[-a]); alloc<-combn(seq_along(v),length(a));stats<-apply(alloc,2,function(k)mean(v[k])-mean(v[-k])); c(delta=delta,p=mean(abs(stats)>=abs(delta)-1e-12))}
   expected<-literal(z$value,1:2)
   ok(y$full_tests$mean_difference==expected[1] && y$full_tests$p_value==expected[2])
   for(j in 1:4) {val<-z$value[-j]; arm<-d$group[-j];ex<-literal(val,which(arm=='A'));ok(y$omissions$mean_difference[j]==ex[1] && y$omissions$p_value[j]==ex[2])}
  }
  # Isolated dependency probes exercise call discipline and the arithmetic guard.
  probe <- new.env(parent=environment(LeaveOnePatientOut))
  probe$LeaveOnePatientOut <- LeaveOnePatientOut
  environment(probe$LeaveOnePatientOut) <- probe
  calls <- 0L
  probe$ExactPatientTests <- function(...) {calls <<- calls+1L; phenoscapR::ExactPatientTests(...)}
  z<-e;z$value[1]<-NA_real_
  invisible(probe$LeaveOnePatientOut(z,d,h,o))
  ok(calls==1L)
  calls<-0L
  probe$ExactPatientTests <- function(...) {calls <<- calls+1L; ans<-phenoscapR::ExactPatientTests(...);ans$mean_difference<-if(calls==1L)-1e308 else 1e308;ans}
  reject(probe$LeaveOnePatientOut(e,d,h,o[1,,drop=FALSE]))
})
