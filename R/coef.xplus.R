#' Extract coefficients from an xplus model
#'
#' @param object An `xplus` object.
#' @param s Penalty value name or numeric lambda.
#' @param ... Additional arguments.
#'
#' @return A sparse coefficient matrix.
#' @seealso [summary.xplus()], [print.xplus()]
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(100 * 5), ncol = 5)
#' y <- c(rep(1, 20), rep(0, 80))
#' fit <- xplus(x, y, max_iter = 5)
#' coef(fit)
#' @method coef xplus
#' @export
coef.xplus <- function(object, s = "lambda.min", ...) {
  glmnet::coef.glmnet(object$xplus, s = s, ...)
}
