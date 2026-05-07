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

test_that("predict type='link' returns log-odds (linear predictor)", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)

  pred_link <- predict(fit, newx = x, type = "link")
  pred_response <- predict(fit, newx = x, type = "response")

  expect_equal(nrow(pred_link), nrow(x))
  # Link values are unbounded log-odds, not probabilities
  expect_true(any(pred_link < 0) || any(pred_link > 1))
  # sigmoid(link) should equal response
  expect_equal(1 / (1 + exp(-pred_link)), pred_response, tolerance = 1e-6)
})

test_that("predict type='link' without newx returns log-odds from stored pred_y", {
  skip_if_not_installed("glmnet")
  set.seed(123)
  x <- matrix(rnorm(120 * 4), ncol = 4)
  y <- c(rep(1, 30), rep(0, 90))

  fit <- xplus(x, y, max_iter = 5)

  pred_link_null <- predict(fit, newx = NULL, type = "link")
  stored_prob <- fit$pred_y
  stored_prob_clamped <- pmin(pmax(stored_prob, 1e-15), 1 - 1e-15)
  expected_link <- log(stored_prob_clamped / (1 - stored_prob_clamped))

  expect_equal(pred_link_null, expected_link)
})
