#' Validate an xplus object
#'
#' @param xplus_object An object of class `"xplus"`.
#'
#' @return The validated `xplus` object.
#' @examples
#' \dontrun{
#' fit <- glmnet::cv.glmnet(matrix(rnorm(50), ncol = 5), c(rep(1, 5), rep(0, 5)), family = "binomial")
#' obj <- new_xplus(fit_xplus = fit, pred_y = matrix(0.5, 10, 1), cutoff = 0.5)
#' validate_xplus(obj)
#' }
#' @export
validate_xplus <- function(xplus_object) {
  stopifnot(inherits(xplus_object, "xplus"))
  values <- unclass(xplus_object)
  stopifnot(inherits(values$xplus, "cv.glmnet"))
  stopifnot(is.matrix(values$pred_y))
  stopifnot(is.numeric(values$cutoff))
  stopifnot(inherits(values$predicted_coefficients, "dgCMatrix"))
  stopifnot(is.numeric(values$n_iter), length(values$n_iter) == 1)
  stopifnot(is.matrix(values$x))
  stopifnot(length(values$y) == nrow(values$x))
  stopifnot(is.numeric(values$max_iter), length(values$max_iter) == 1)
  xplus_object
}
