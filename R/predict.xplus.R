#' Predict from an xplus model
#'
#' @param object An `xplus` object.
#' @param ... Additional arguments (unused).
#' @param newx Optional new feature matrix.
#' @param s Penalty value name (`"lambda.min"`, `"lambda.1se"`) or numeric lambda.
#' @param type Prediction type: `"response"`, `"class"`, or `"link"`.
#'
#' @return A matrix of probabilities (`type = "response"`), class labels (`type = "class"`),
#' or linear predictors (`type = "link"`).
#' @seealso [xplus()], [print.xplus()]
#' @references Zhou et al. (2022). doi:10.1371/journal.pcbi.1009956
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(100 * 5), ncol = 5)
#' y <- c(rep(1, 20), rep(0, 80))
#' fit <- xplus(x, y, max_iter = 5)
#' predict(fit, newx = x, type = "response")
#' @method predict xplus
#' @export
predict.xplus <- function(object, ..., newx = NULL, s = "lambda.min", type = "response") {
  type <- match.arg(type, c("response", "class", "link"))

  if (is.numeric(s)) {
    lambda <- s
  } else if (is.character(s)) {
    s <- match.arg(s, c("lambda.min", "lambda.1se"))
    lambda <- object$xplus[[s]]
    names(lambda) <- s
  } else {
    stop("Invalid form for `s`.", call. = FALSE)
  }

  if (type == "link") {
    if (is.null(newx)) {
      newx <- object$x
    }
    return(stats::predict(object$xplus$glmnet.fit, newx, s = lambda, type = "link"))
  }

  if (is.null(newx)) {
    prob <- object$pred_y
  } else {
    prob <- stats::predict(object$xplus$glmnet.fit, newx, s = lambda, type = "response")
  }

  if (type == "response") {
    return(prob)
  }

  as.factor(prob > object$cutoff)
}
