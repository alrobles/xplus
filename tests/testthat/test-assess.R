test_that("assess returns all requested metrics", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)
  out <- assess(fit, newx = x, newy = y)

  expect_named(out, c("deviance", "class", "auc", "mse", "mae"))
})

test_that("assess uses linear predictor scale for xplus_cv_lognet metrics", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)
  out <- assess(fit, newx = x, newy = y)
  pred_link <- predict(fit, newx = x, type = "link")
  measures <- c("deviance", "class", "auc", "mse", "mae")

  expected <- lapply(measures, function(measure) {
    metric_result <- xplus_cv_lognet(pred_link, y, measure)
    drop(with(metric_result, apply(cvraw, 2, stats::weighted.mean, w = rep(1, length(y)), na.rm = TRUE)))
  })
  names(expected) <- measures

  for (measure in measures) {
    expect_equal(out[[measure]], expected[[measure]])
  }
})
