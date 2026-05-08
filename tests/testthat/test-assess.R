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

test_that("assess class metric matches manual and predict type='class' thresholding", {
  fit <- structure(
    list(
      pred_y = matrix(c(0.2, 0.5, 0.51, 0.8, 0.49, 0.75, 0.1, 0.95, 0.65, 0.35, 0.55, 0.45), ncol = 1),
      cutoff = 0.5,
      stop_reason = "max_iter"
    ),
    class = "xplus"
  )
  y <- c(0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0)

  pred_prob <- predict(fit, type = "response")
  manual_class <- as.integer(pred_prob > fit$cutoff)
  pred_class <- as.integer(predict(fit, type = "class")) - 1
  manual_error <- mean(manual_class != y)

  expect_equal(pred_class, manual_class)
  expect_equal(assess(fit, newy = y)$class, manual_error, tolerance = 1e-10)
})
