test_that("xplus runs and returns xplus class", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit <- xplus(x, y, max_iter = 5)

  expect_s3_class(fit, "xplus")
  expect_true(inherits(fit$xplus, "cv.glmnet"))
  expect_equal(nrow(fit$pred_y), nrow(x))
})

test_that("xplus stops when sampling probabilities are exhausted", {
  skip_if_not_installed("glmnet")
  set.seed(1)
  x <- matrix(rnorm(25), ncol = 5)
  y <- c(rep(1, 4), 0)

  expect_no_error(
    fit <- xplus(
      x,
      y,
      sample_use_time = 1,
      convergence_threshold = 1,
      nfolds = 2,
      max_iter = 10
    )
  )
  expect_s3_class(fit, "xplus")
})
