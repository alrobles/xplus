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

test_that("predict type='link' returns log-odds (values outside [0,1])", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)

  pred_link <- predict(fit, newx = x, type = "link")

  expect_equal(nrow(pred_link), nrow(x))
  # log-odds are not bounded to [0, 1]
  expect_true(any(pred_link < 0) || any(pred_link > 1))

  # link and response are consistent: sigmoid(link) == response
  pred_response <- predict(fit, newx = x, type = "response")
  expect_equal(1 / (1 + exp(-pred_link)), pred_response, tolerance = 1e-6)
})

test_that("predict type='link' works without newx (uses stored pred_y)", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)

  pred_link_null <- predict(fit, type = "link")
  pred_response_null <- predict(fit, type = "response")

  expect_equal(nrow(pred_link_null), nrow(x))
  expect_equal(1 / (1 + exp(-pred_link_null)), pred_response_null, tolerance = 1e-6)
})
