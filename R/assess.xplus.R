#' Assess predictive performance
#'
#' @param object A model object.
#' @param newx Optional feature matrix.
#' @param newy True labels.
#' @param weights Optional sample weights.
#' @param ... Additional arguments passed to [predict()].
#'
#' @return A named list with `deviance`, `class`, `auc`, `mse`, and `mae`.
#' @seealso [xplus()], [get_auc()]
#' @references Zhou et al. (2022). doi:10.1371/journal.pcbi.1009956
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(100 * 5), ncol = 5)
#' y <- c(rep(1, 20), rep(0, 80))
#' fit <- xplus(x, y, max_iter = 5)
#' assess(fit, newx = x, newy = y)
#' @export
assess <- function(object, newx = NULL, newy, weights = NULL, ...) {
  UseMethod("assess")
}

#' @rdname assess
#' @method assess xplus
#' @export
assess.xplus <- function(object, newx = NULL, newy, weights = NULL, ...) {
  predmat <- predict(object, newx = newx, type = "link", ...)
  fam <- "binomial"
  attr(predmat, "family") <- fam
  type.measures <- c("deviance", "class", "auc", "mse", "mae")

  y <- drop(newy)
  dimy <- dim(y)
  nrowy <- ifelse(is.null(dimy), length(y), dimy[1])
  if (is.null(weights)) {
    weights <- rep(1, nrowy)
  }

  outlist <- as.list(type.measures)
  names(outlist) <- type.measures

  for (measure in type.measures) {
    teststuff <- do.call(xplus_cv_lognet, list(predmat, y, measure))
    out <- drop(with(teststuff, apply(cvraw, 2, stats::weighted.mean, w = weights, na.rm = TRUE)))
    attr(out, "measure") <- measure
    outlist[[measure]] <- out
  }

  outlist
}
