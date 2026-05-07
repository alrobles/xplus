test_that("xplus runs and returns xplus class", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit <- xplus(x, y, max_iter = 5)

  expect_s3_class(fit, "xplus")
  expect_true(inherits(fit$xplus, "cv.glmnet"))
  expect_equal(nrow(fit$pred_y), nrow(x))
  expect_true(fit$stop_reason %in% c("max_iter", "label_stability", "budget_exhausted"))
})

test_that("xplus records max_iter stop reason when no early stopping condition triggers", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(80 * 4), ncol = 4)
  y <- c(rep(1, 20), rep(0, 60))

  fit <- xplus(x, y, max_iter = 2, convergence_threshold = 1)
  out <- summary(fit)

  expect_equal(fit$stop_reason, "max_iter")
  expect_equal(out$stop_reason, "max_iter")
  expect_false("convergence_reached" %in% names(out))
})
