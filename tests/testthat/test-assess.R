test_that("assess returns all requested metrics", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)
  out <- assess(fit, newx = x, newy = y)

  expect_named(out, c("deviance", "class", "auc", "mse", "mae"))
})

test_that("assess AUC is in [0, 1] (no double-sigmoid corruption)", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)
  out <- assess(fit, newx = x, newy = y)

  expect_true(out$auc >= 0 && out$auc <= 1)
  # class error rate is in [0, 1]
  expect_true(out$class >= 0 && out$class <= 1)
  # deviance is non-negative
  expect_true(out$deviance >= 0)
  # MSE and MAE are non-negative
  expect_true(out$mse >= 0)
  expect_true(out$mae >= 0)
})
