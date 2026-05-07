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

test_that("xplus seed parameter produces reproducible results", {
  skip_if_not_installed("glmnet")
  set.seed(42)
  x <- matrix(rnorm(100 * 5), ncol = 5)
  y <- c(rep(1, 25), rep(0, 75))

  fit1 <- xplus(x, y, max_iter = 5, seed = 7)
  fit2 <- xplus(x, y, max_iter = 5, seed = 7)

  expect_equal(as.numeric(fit1$pred_y), as.numeric(fit2$pred_y))
  expect_equal(fit1$n_iter, fit2$n_iter)
})

test_that("xplus seed parameter validates input", {
  skip_if_not_installed("glmnet")
  set.seed(1)
  x <- matrix(rnorm(50 * 5), ncol = 5)
  y <- c(rep(1, 10), rep(0, 40))

  expect_error(xplus(x, y, max_iter = 2, seed = "abc"), "`seed` must be a single numeric value or NULL.")
  expect_error(xplus(x, y, max_iter = 2, seed = c(1, 2)), "`seed` must be a single numeric value or NULL.")
})
