edge_count_fixture <- function() {
  nodes <- data.frame(sample = rep('A', 7), frame = rep('F', 7),
    id = c('s1', 's2', 's3', 't1', 't2', 't3', 'other'),
    source = c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE),
    target = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, FALSE))
  edges <- data.frame(sample = rep('A', 5), frame = rep('F', 5),
    from = c('s1', 't2', 's2', 's1', 'other'),
    to = c('t1', 's1', 't2', 's2', 't3'), distance = c(1, 100, 2, 3, 4))
  registry <- data.frame(sample = c('A','B'), frame = c('F','F'),
    geometry_source = c('frozen_import','supplied_edges'),
    geometry_reference = c('fixture-edges-v1','empty-fixture-v1'))
  list(nodes = nodes, edges = edges, registry = registry)
}
run_edge_count_fixture <- function(x, ...) do.call(CountDisjointEdges,
  c(x, list(groups='sample', frame='frame', id='id', from='from', to='to',
            source='source', target='target'), list(...)))

test_that('hand counted degrees include isolated and neither-membership nodes', {
  x <- edge_count_fixture(); o <- run_edge_count_fixture(x)
  expect_equal(o$n_nodes, c(7,0)); expect_equal(o$n_edges, c(5,0))
  expect_equal(o$n_source, c(3,0)); expect_equal(o$n_target, c(3,0))
  expect_equal(o$n_cross_edges, c(3,0))
  expect_equal(o$n_interacting_source, c(2,0))
  expect_equal(o$n_interacting_target, c(2,0))
  expect_equal(o$source_neighbor_mean, c(1.5,NA))
  expect_equal(o$target_neighbor_mean, c(1.5,NA))
  expect_equal(o$source_contact_fraction, c(2/3,NA))
  expect_equal(o$target_contact_fraction, c(2/3,NA))
  expect_identical(o$geometry_source, c('frozen_import','supplied_edges'))
  expect_true(all(!o$geometry_recomputed))
  expect_true(all(o$geometry_authentication == 'CALLER_DECLARED_NOT_VERIFIED'))
  x$edges$distance <- c(NA, Inf, -1, 0, 1e12)
  expect_identical(run_edge_count_fixture(x),o) # no implicit distance filter or units contract
})

test_that('independent dense adjacency oracle covers arbitrary tiny graphs', {
  set.seed(2701)
  for (trial in 1:30) {
    x <- edge_count_fixture(); n <- 7L
    choices <- sample(0:2,n,replace=TRUE)
    x$nodes$source <- choices==1L; x$nodes$target <- choices==2L
    adjacency <- matrix(FALSE,n,n)
    adjacency[upper.tri(adjacency)] <- sample(c(FALSE,TRUE),21,replace=TRUE)
    adjacency <- adjacency | t(adjacency)
    loc <- which(adjacency & upper.tri(adjacency),arr.ind=TRUE)
    x$edges <- data.frame(sample=rep('A',nrow(loc)),frame=rep('F',nrow(loc)),
      from=x$nodes$id[loc[,1]],to=x$nodes$id[loc[,2]])
    cross <- adjacency[x$nodes$source,x$nodes$target,drop=FALSE]
    ec <- sum(cross); ms <- sum(rowSums(cross)>0); mt <- sum(colSums(cross)>0)
    o <- run_edge_count_fixture(x)[1,]
    expect_equal(o$n_cross_edges,ec); expect_equal(o$n_interacting_source,ms)
    expect_equal(o$n_interacting_target,mt)
    expect_equal(o$source_neighbor_mean,if(ms) ec/ms else NA_real_)
    expect_equal(o$target_neighbor_mean,if(mt) ec/mt else NA_real_)
    baseline <- run_edge_count_fixture(x)
    x$nodes <- x$nodes[sample(n),]
    x$edges <- x$edges[rev(seq_len(nrow(x$edges))),]
    swap <- x$edges$from; x$edges$from <- x$edges$to; x$edges$to <- swap
    x$registry <- x$registry[2:1,]
    expect_identical(run_edge_count_fixture(x),baseline)
  }
})

test_that('observed zero and no denominator have separate statuses', {
  x <- edge_count_fixture(); x$edges <- x$edges[FALSE,]; o <- run_edge_count_fixture(x)
  expect_equal(o$source_contact_fraction,c(0,NA))
  expect_equal(o$source_neighbor_mean,c(NA_real_,NA_real_))
  expect_identical(o$source_contact_status,c('DEFINED','NO_SOURCE'))
  expect_true(all(o$source_neighbor_status=='NO_INTERACTING_SOURCE'))
  x$nodes$target <- FALSE; o <- run_edge_count_fixture(x)
  expect_identical(o$target_contact_status,c('NO_TARGET','NO_TARGET'))
  x$nodes$source <- FALSE; expect_true(all(run_edge_count_fixture(x)$source_contact_status=='NO_SOURCE'))
})

test_that('IDs are scoped to full frame keys, with delimiter-safe encoding', {
  x <- edge_count_fixture(); y <- x$nodes; y$frame <- 'G'
  x$nodes <- rbind(x$nodes,y)
  x$registry <- rbind(x$registry,transform(x$registry[1,],frame='G'))
  expect_equal(run_edge_count_fixture(x)$n_nodes,c(7,7,0))
  y <- edge_count_fixture(); y$nodes$sample <- 'B'; y$edges$sample <- 'B'
  x <- edge_count_fixture(); x$nodes <- rbind(x$nodes,y$nodes); x$edges <- rbind(x$edges,y$edges)
  expect_equal(run_edge_count_fixture(x)$n_cross_edges,c(3,3))
  x <- edge_count_fixture(); x$nodes$id[1] <- 'a:1|\u00e9'; x$edges$from[x$edges$from=='s1'] <- 'a:1|\u00e9'
  x$edges$to[x$edges$to=='s1'] <- 'a:1|\u00e9'; expect_equal(run_edge_count_fixture(x)$n_cross_edges,c(3,0))
})

test_that('invalid graph and membership contracts fail closed', {
  x <- edge_count_fixture(); x$nodes <- rbind(x$nodes,x$nodes[1,]); expect_error(run_edge_count_fixture(x),'duplicate node')
  x <- edge_count_fixture(); x$edges <- rbind(x$edges,transform(x$edges[1,],from='t1',to='s1')); expect_error(run_edge_count_fixture(x),'duplicate undirected')
  x <- edge_count_fixture(); x$edges$to[1] <- 's1'; expect_error(run_edge_count_fixture(x),'self edges')
  x <- edge_count_fixture(); x$edges$to[1] <- 'unknown'; expect_error(run_edge_count_fixture(x),'unknown endpoint')
  x <- edge_count_fixture(); x$nodes$frame[4] <- 'G'; x$registry <- rbind(x$registry,transform(x$registry[1,],frame='G')); expect_error(run_edge_count_fixture(x),'unknown endpoint')
  x <- edge_count_fixture(); x$nodes$source[1] <- NA; expect_error(run_edge_count_fixture(x),'memberships')
  x <- edge_count_fixture(); x$nodes$target[1] <- TRUE; expect_error(run_edge_count_fixture(x),'overlap')
  x <- edge_count_fixture(); x$nodes$source <- as.integer(x$nodes$source); expect_error(run_edge_count_fixture(x),'memberships')
  x <- edge_count_fixture(); x$nodes$id[1] <- NA; expect_error(run_edge_count_fixture(x),'nonempty nonmissing')
  x <- edge_count_fixture(); x$nodes$id <- factor(x$nodes$id); expect_error(run_edge_count_fixture(x),'character')
  x <- edge_count_fixture(); x$nodes$id <- matrix(x$nodes$id,ncol=1); expect_error(run_edge_count_fixture(x),'character')
  x <- edge_count_fixture(); x$nodes$source <- matrix(x$nodes$source,ncol=1); expect_error(run_edge_count_fixture(x),'memberships')
  x <- edge_count_fixture(); x$registry <- rbind(x$registry,x$registry[1,]); expect_error(run_edge_count_fixture(x),'duplicate registry')
  x <- edge_count_fixture(); x$registry <- x$registry[2,]; expect_error(run_edge_count_fixture(x),'absent from registry')
  x <- edge_count_fixture(); x$registry$geometry_source[1] <- 'exact_recomputed'; expect_error(run_edge_count_fixture(x),'geometry_source')
})

test_that('reserved variable names are ordinary explicitly selected columns', {
  x <- edge_count_fixture(); baseline <- run_edge_count_fixture(x)
  for (name in c('.SD','.N','.I','.GRP','.BY','method','decreasing','na.last','collapse','recycle0')) {
    y <- x
    for (table in names(y)) names(y[[table]])[names(y[[table]])=='sample'] <- name
    o <- CountDisjointEdges(y$nodes,y$edges,y$registry,name,'frame','id','from','to','source','target')
    names(o)[names(o)==name] <- 'sample'; expect_identical(o,baseline)
  }
})

test_that('empty registry returns complete typed schema', {
  x <- edge_count_fixture(); x <- lapply(x,function(d)d[FALSE,]); o <- run_edge_count_fixture(x)
  expect_equal(nrow(o),0)
  expect_type(o$n_nodes,'double'); expect_type(o$source_neighbor_status,'character')
  expect_type(o$source_contact_fraction,'double'); expect_type(o$geometry_recomputed,'logical')
})
