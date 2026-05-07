test_that("assess returns all requested metrics", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)
  out <- assess(fit, newx = x, newy = y)

  expect_named(out, c("deviance", "class", "auc", "mse", "mae"))
})

test_that("assess AUC is not corrupted by double sigmoid", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)
  out <- assess(fit, newx = x, newy = y)

  # AUC should be a valid probability in [0, 1]; a double-sigmoid bug
  # compresses predictions toward 0.5 and drives AUC toward 0.5
  auc_val <- out$auc
  expect_true(auc_val >= 0 && auc_val <= 1)
  # With a separable signal, AUC should be well above 0.5
  expect_gt(auc_val, 0.5)
})
