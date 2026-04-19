test_that("predict returns expected dimensions", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)

  pred_response <- predict(fit, newx = x, type = "response")
  pred_class <- predict(fit, newx = x, type = "class")

  expect_equal(nrow(pred_response), nrow(x))
  expect_equal(length(pred_class), nrow(x))
})
