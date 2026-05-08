test_that("xplus runs and returns xplus class", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit <- xplus(x, y, max_iter = 5)

  expect_s3_class(fit, "xplus")
  expect_true(inherits(fit$xplus, "cv.glmnet"))
  expect_equal(nrow(fit$pred_y), nrow(x))
  expect_equal(length(fit$pseudo_labels), nrow(x))
  expect_equal(fit$iterative_path, "current")
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
  expect_equal(fit$iterative_path, "continuous_enhancement")
  expect_equal(summary(fit)$iterative_path, "continuous_enhancement")
})

test_that("xplus stabilization is based on soft-label movement magnitude", {
  skip_if_not_installed("glmnet")
  set.seed(234)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit <- xplus(
    x,
    y,
    learning_rate = 1e-4,
    sample_use_time = 1e6,
    convergence_threshold = 0.99,
    max_iter = 10,
    seed = 234
  )

  expect_equal(fit$iterative_path, "continuous_enhancement")
  expect_equal(fit$n_iter, 1)
  expect_equal(fit$stop_reason, "label_stability")
})

test_that("continuous enhancement path keeps pseudo-labels continuous", {
  skip_if_not_installed("glmnet")
  set.seed(321)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit <- xplus(x, y, learning_rate = 0.5, max_iter = 3, seed = 321)

  expect_equal(fit$iterative_path, "continuous_enhancement")
  expect_true(all(fit$pseudo_labels >= 0 & fit$pseudo_labels <= 1))
  expect_true(any(fit$pseudo_labels[y == 0] > 0 & fit$pseudo_labels[y == 0] < 1))
})

test_that("continuous enhancement path is reproducible with fixed seed", {
  skip_if_not_installed("glmnet")
  set.seed(654)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit_a <- xplus(x, y, learning_rate = 0.5, max_iter = 3, seed = 999)
  fit_b <- xplus(x, y, learning_rate = 0.5, max_iter = 3, seed = 999)

  expect_equal(fit_a$iterative_path, "continuous_enhancement")
  expect_equal(fit_a$pseudo_labels, fit_b$pseudo_labels)
  expect_equal(fit_a$y, fit_b$y)
  expect_equal(fit_a$n_iter, fit_b$n_iter)
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

# Input validation tests

test_that("xplus rejects x with NA values", {
  skip_if_not_installed("glmnet")
  x <- matrix(rnorm(100 * 5), ncol = 5)
  x[1, 1] <- NA
  y <- c(rep(1, 25), rep(0, 75))

  expect_error(
    xplus(x, y, max_iter = 2),
    "`x` must not contain NA values.",
    fixed = TRUE
  )
})

test_that("xplus rejects x with Inf values", {
  skip_if_not_installed("glmnet")
  x <- matrix(rnorm(100 * 5), ncol = 5)
  x[2, 3] <- Inf
  y <- c(rep(1, 25), rep(0, 75))

  expect_error(
    xplus(x, y, max_iter = 2),
    "`x` must not contain Inf values.",
    fixed = TRUE
  )
})

test_that("xplus rejects x with -Inf values", {
  skip_if_not_installed("glmnet")
  x <- matrix(rnorm(100 * 5), ncol = 5)
  x[5, 2] <- -Inf
  y <- c(rep(1, 25), rep(0, 75))

  expect_error(
    xplus(x, y, max_iter = 2),
    "`x` must not contain Inf values.",
    fixed = TRUE
  )
})

test_that("xplus rejects non-integer-like sample_use_time", {
  skip_if_not_installed("glmnet")
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  expect_error(
    xplus(x, y, sample_use_time = 30.5, max_iter = 2),
    "`sample_use_time` must be an integer-like value.",
    fixed = TRUE
  )
})

test_that("xplus accepts integer-like sample_use_time as numeric", {
  skip_if_not_installed("glmnet")
  set.seed(42)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  # Should work with integer-like numeric values
  fit <- xplus(x, y, sample_use_time = 30.0, max_iter = 2, seed = 42)
  expect_s3_class(fit, "xplus")
})

test_that("xplus handles near-degenerate positive threshold", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  # Create data where predictions will be very close to cutoff
  x <- matrix(runif(100 * 5, min = -1e-8, max = 1e-8), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  # Should complete without error even if data is degenerate
  fit <- xplus(x, y, max_iter = 1, seed = 123)
  expect_s3_class(fit, "xplus")
})

test_that("xplus handles near-degenerate negative threshold", {
  skip_if_not_installed("glmnet")
  set.seed(456)
  # Create data where predictions will be very close to cutoff
  x <- matrix(runif(100 * 5, min = -1e-8, max = 1e-8), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  # Should complete without error even if data is degenerate
  fit <- xplus(x, y, max_iter = 1, seed = 456)
  expect_s3_class(fit, "xplus")
})

test_that("final fit uses stabilized continuous pseudo-labels with unchanged interfaces", {
  skip_if_not_installed("glmnet")
  set.seed(999)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, learning_rate = 1, max_iter = 1, seed = 999)

  expect_true(any(fit$y > 0 & fit$y < 1))

  pred_response <- predict(fit, newx = x, type = "response")
  pred_class <- predict(fit, newx = x, type = "class")
  out_summary <- summary(fit)
  out_assess <- assess(fit, newx = x, newy = y)
  out_coef <- coef(fit)

  expect_equal(nrow(pred_response), nrow(x))
  expect_equal(length(pred_class), nrow(x))
  expect_equal(out_summary$n_obs, nrow(x))
  expect_named(out_assess, c("deviance", "class", "auc", "mse", "mae"))
  expect_s4_class(out_coef, "dgCMatrix")
})
