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

test_that("xplus can stop on early label stability", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit <- xplus(
    x,
    y,
    learning_rate = 0,
    sample_use_time = 1e6,
    convergence_threshold = 0.9,
    max_iter = 10
  )

  expect_equal(fit$n_iter, 1)
})

test_that("final refit passes alpha = 0 (ridge) to cv.glmnet", {
  skip_if_not_installed("glmnet")
  set.seed(42)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit <- xplus(x, y, alpha = 0, max_iter = 2, seed = 42)

  expect_equal(fit$alpha, 0)
  # Ridge (alpha=0) never produces exact zeros; all non-intercept coefs should be non-zero
  coefs <- as.numeric(coef(fit))[-1]
  expect_true(all(coefs != 0))
})

test_that("final refit passes alpha = 1 (lasso) to cv.glmnet", {
  skip_if_not_installed("glmnet")
  set.seed(42)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit <- xplus(x, y, alpha = 1, max_iter = 2, seed = 42)

  expect_equal(fit$alpha, 1)
  # Lasso (alpha=1) should produce a sparse solution (at least one zero coef)
  coefs <- as.numeric(coef(fit))[-1]
  expect_true(any(coefs == 0))
})

test_that("final refit alpha is stored and consistent for alpha = 0.5", {
  skip_if_not_installed("glmnet")
  set.seed(42)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit <- xplus(x, y, alpha = 0.5, max_iter = 2, seed = 42)

  expect_equal(fit$alpha, 0.5)
  expect_s3_class(fit, "xplus")
  expect_true(inherits(fit$xplus, "cv.glmnet"))
})
