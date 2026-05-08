#' Construct a new xplus object
#'
#' @param fit_xplus Fitted [glmnet::cv.glmnet()] object.
#' @param pred_y Predicted probabilities matrix.
#' @param cutoff Numeric classification cutoff.
#' @param predicted_coefficients Sparse coefficient matrix.
#' @param n_iter Number of iterations executed.
#' @param x Training feature matrix used to fit the model.
#' @param y Final relabeled response vector.
#' @param alpha Elastic-net alpha used during fitting.
#' @param learning_rate Learning rate used during pseudo-label updates.
#' @param pseudo_labels Final pseudo-label probabilities.
#' @param iterative_path Internal iterative path used for pseudo-label updates.
#' @param qq Quantile parameter used for cutoff calibration.
#' @param call Original function call.
#' @param max_iter Maximum number of iterations configured for fitting.
#' @param stop_reason Reason fitting stopped: `"max_iter"`, `"label_stability"`, or `"budget_exhausted"`.
#'
#' @return An object of class `"xplus"`.
#' @seealso [validate_xplus()]
#' @examples
#' \dontrun{
#' fit <- glmnet::cv.glmnet(matrix(rnorm(50), ncol = 5), c(rep(1, 5), rep(0, 5)), family = "binomial")
#' obj <- new_xplus(fit_xplus = fit, pred_y = matrix(0.5, 10, 1), cutoff = 0.5)
#' }
#' @keywords internal
new_xplus <- function(
  fit_xplus = list(),
  pred_y = matrix(),
  cutoff = numeric(),
  predicted_coefficients = Matrix::Matrix(),
  n_iter = integer(),
  x = matrix(),
  y = integer(),
  alpha = numeric(),
  learning_rate = numeric(),
  pseudo_labels = numeric(),
  iterative_path = character(),
  qq = numeric(),
  call = character(),
  max_iter = integer(),
  stop_reason = character()
) {
  predicted_coefficients <- Matrix::Matrix(predicted_coefficients, sparse = TRUE)
  stop_reason <- as.character(stop_reason)[1]

  structure(
    list(
      xplus = fit_xplus,
      pred_y = pred_y,
      cutoff = cutoff,
      predicted_coefficients = predicted_coefficients,
      n_iter = n_iter,
      x = x,
      y = y,
      alpha = alpha,
      learning_rate = learning_rate,
      pseudo_labels = pseudo_labels,
      iterative_path = as.character(iterative_path)[1],
      qq = qq,
      call = call,
      max_iter = max_iter,
      stop_reason = stop_reason
    ),
    class = "xplus"
  )
}
