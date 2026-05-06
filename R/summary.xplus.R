#' Summarize an xplus model
#'
#' @param object An `xplus` object.
#' @param ... Additional arguments.
#'
#' @return A list of class `summary.xplus` with model details.
#' @seealso [print.xplus()], [coef.xplus()]
#' @references Zhou et al. (2022). doi:10.1371/journal.pcbi.1009956
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(100 * 5), ncol = 5)
#' y <- c(rep(1, 20), rep(0, 80))
#' fit <- xplus(x, y, max_iter = 5)
#' summary(fit)
#' @method summary xplus
#' @export
summary.xplus <- function(object, ...) {
  n_nonzero <- sum(as.matrix(object$predicted_coefficients) != 0)
  out <- list(
    n_obs = nrow(object$x),
    n_features = ncol(object$x),
    n_iter = object$n_iter,
    cutoff = object$cutoff,
    alpha = object$alpha,
    learning_rate = object$learning_rate,
    qq = object$qq,
    lambda_min = object$xplus$lambda.min,
    lambda_1se = object$xplus$lambda.1se,
    n_nonzero_coefficients = n_nonzero,
    convergence_reached = object$n_iter < object$max_iter
  )
  class(out) <- "summary.xplus"
  out
}

#' Print method for summary.xplus objects
#' @param x A `summary.xplus` object.
#' @param ... Additional arguments.
#' @method print summary.xplus
#' @return The input object \code{x} is returned invisibly (called for side
#' effects).
#' @export
print.summary.xplus <- function(x, ...) {
  cat("Summary of xplus model\n")
  cat("Observations:", x$n_obs, "\n")
  cat("Features:", x$n_features, "\n")
  cat("Iterations:", x$n_iter, "\n")
  cat("Converged:", x$convergence_reached, "\n")
  cat("Cutoff:", x$cutoff, "\n")
  cat("lambda.min:", x$lambda_min, "\n")
  cat("lambda.1se:", x$lambda_1se, "\n")
  cat("Non-zero coefficients:", x$n_nonzero_coefficients, "\n")
  invisible(x)
}
