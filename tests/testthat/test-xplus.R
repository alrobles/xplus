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

test_that("xplus errors when alpha is out of [0, 1]", {
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  expect_error(xplus(x, y, alpha = -0.1), "`alpha` must be a numeric scalar in \\[0, 1\\]\\.")
  expect_error(xplus(x, y, alpha = 2),    "`alpha` must be a numeric scalar in \\[0, 1\\]\\.")
  expect_error(xplus(x, y, alpha = "a"),  "`alpha` must be a numeric scalar in \\[0, 1\\]\\.")
})
