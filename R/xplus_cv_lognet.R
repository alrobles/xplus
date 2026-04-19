#' Internal cross-validation metrics for binomial models
#'
#' @param predmat Prediction matrix.
#' @param y Outcome values.
#' @param type.measure Metric type.
#' @param weights Optional sample weights.
#'
#' @return A list with raw metric values and metadata.
#' @seealso [assess()]
#' @references Robles et al. (2022). doi:10.1371/journal.pcbi.1009956
#' @examples
#' y <- factor(c(1, 1, 2, 2))
#' pred <- matrix(rnorm(4), ncol = 1)
#' xplus_cv_lognet(pred, y, type.measure = "class")
#' @export
xplus_cv_lognet <- function(predmat, y, type.measure = c("deviance", "class", "auc", "mse", "mae"), weights = NULL) {
  nc <- dim(y)
  if (is.null(nc)) {
    y <- as.factor(y)
    ntab <- table(y)
    nc <- as.integer(length(ntab))
    y <- diag(nc)[as.numeric(y), , drop = FALSE]
  }
  dimy <- dim(y)
  nrowy <- ifelse(is.null(dimy), length(y), dimy[1])
  foldid <- rep(1, nrowy)
  if (is.null(weights)) weights <- rep(1, nrowy)
  type.measure <- match.arg(type.measure)
  prob_min <- 1e-05
  prob_max <- 1 - prob_min
  N <- nrow(y)
  nfolds <- max(foldid)
  if ((N / nfolds < 10) && type.measure == "auc") {
    warning("Too few (< 10) observations per fold for type.measure='auc' in cv.lognet; changed to type.measure='deviance'. Alternatively, use smaller value for nfolds", call. = FALSE)
  }
  predmat <- 1 / (1 + exp(-predmat))
  nlambda <- ncol(predmat)
  nlams <- rep(nlambda, nfolds)
  if (type.measure == "auc") {
    cvraw <- matrix(NA, nfolds, nlambda)
    good <- matrix(0, nfolds, nlambda)
    for (i in seq(nfolds)) {
      good[i, seq(nlams[i])] <- 1
      fold_mask <- foldid == i
      for (j in seq(nlams[i])) {
        cvraw[i, j] <- auc_matrix(y[fold_mask, ], predmat[fold_mask, j], weights[fold_mask])
      }
    }
    N <- apply(good, 2, sum)
    weights <- tapply(weights, foldid, sum)
  } else {
    ywt <- apply(y, 1, sum)
    y <- y / ywt
    weights <- weights * ywt
    N <- nrow(y) - apply(is.na(predmat), 2, sum)
    cvraw <- switch(
      type.measure,
      mse = (y[, 1] - (1 - predmat))^2 + (y[, 2] - predmat)^2,
      mae = abs(y[, 1] - (1 - predmat)) + abs(y[, 2] - predmat),
      deviance = {
        predmat <- pmin(pmax(predmat, prob_min), prob_max)
        lp <- y[, 1] * log(1 - predmat) + y[, 2] * log(predmat)
        ly <- log(y)
        ly[y == 0] <- 0
        ly <- drop((y * ly) %*% c(1, 1))
        2 * (ly - lp)
      },
      class = y[, 1] * (predmat > 0.5) + y[, 2] * (predmat <= 0.5)
    )
  }
  list(cvraw = cvraw, weights = weights, N = N, type.measure = type.measure)
}
