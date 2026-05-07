#' Fit an xplus model
#'
#' Fit the PLUS algorithm for positive-unlabeled learning.
#'
#' @param x Numeric feature matrix.
#' @param y Binary vector where `1` indicates known positives and `0` indicates unlabeled samples.
#' @param alpha Elastic-net mixing parameter passed to [glmnet::cv.glmnet()].
#' @param sample_use_time Number of times each unlabeled sample can be selected before its sampling probability reaches zero.
#' @param learning_rate Learning-rate for pseudo-label updates in `[0, 1]`.
#' @param qq Quantile used to define the positive-reference cutoff.
#' @param verbose Logical; print iterative progress messages.
#' @param nfolds Number of CV folds used in the iterative fit.
#' @param max_iter Maximum number of pseudo-labeling iterations.
#' @param convergence_threshold Proportion threshold for label stability and sampling exhaustion checks.
#'
#' @details
#' The PLUS algorithm alternates between fitting penalized logistic models on known positives
#' and sampled unlabeled cases, then updating unlabeled pseudo-labels from calibrated
#' probabilities. Convergence is reached when pseudo-label changes stabilize above
#' `convergence_threshold` or the sampling budget is consumed.
#'
#' @return An object of class `"xplus"`.
#' @references Zhou et al. (2022). doi:10.1371/journal.pcbi.1009956
#' @seealso [predict.xplus()], [summary.xplus()], [assess.xplus()]
#' @importFrom stats predict
#' @examples
#' \donttest{
#' set.seed(1)
#' x <- matrix(rnorm(200 * 10), ncol = 10)
#' y <- c(rep(1, 40), rep(0, 160))
#' fit <- xplus(x, y, max_iter = 20)
#' }
#' @export
xplus <- function(
  x,
  y,
  alpha = 1,
  sample_use_time = 30,
  learning_rate = 1,
  qq = 0.1,
  verbose = FALSE,
  nfolds = 4,
  max_iter = 10000,
  convergence_threshold = 0.9
) {
  this.call <- match.call()

  if (!is.matrix(x)) stop("`x` must be a matrix.", call. = FALSE)
  if (nrow(x) != length(y)) stop("`x` and `y` must have matching dimensions.", call. = FALSE)
  if (!all(y %in% c(0, 1))) stop("`y` must contain only 0 and 1.", call. = FALSE)
  if (!is.numeric(alpha) || length(alpha) != 1) stop("`alpha` must be a scalar numeric value.", call. = FALSE)
  if (!is.numeric(sample_use_time) || sample_use_time <= 0) stop("`sample_use_time` must be > 0.", call. = FALSE)
  if (!is.numeric(learning_rate) || learning_rate < 0 || learning_rate > 1) stop("`learning_rate` must be in [0, 1].", call. = FALSE)
  if (!is.numeric(qq) || qq < 0 || qq > 1) stop("`qq` must be in [0, 1].", call. = FALSE)
  if (!is.numeric(nfolds) || nfolds < 2) stop("`nfolds` must be >= 2.", call. = FALSE)
  if (!is.numeric(max_iter) || max_iter < 1) stop("`max_iter` must be >= 1.", call. = FALSE)
  if (!is.numeric(convergence_threshold) || convergence_threshold <= 0 || convergence_threshold > 1) {
    stop("`convergence_threshold` must be in (0, 1].", call. = FALSE)
  }

  y <- as.integer(y)
  n <- nrow(x)
  positive_id <- which(y == 1)
  unlabeled_id <- seq_len(n)[-positive_id]

  if (length(positive_id) == 0) stop("`y` must contain at least one positive sample.", call. = FALSE)
  if (length(unlabeled_id) == 0) stop("`y` must contain at least one unlabeled sample.", call. = FALSE)

  pseudo_labels <- y
  prob_chosen <- rep(1, length(unlabeled_id))
  names(prob_chosen) <- unlabeled_id
  change_proportion <- rep(0, 5)
  n_iter <- 0
  stop_reason <- "max_iter"

  for (i in seq_len(max_iter)) {
    sample_id <- sample(unlabeled_id, length(positive_id), replace = TRUE, prob = prob_chosen)
    sample_id <- unique(sample_id)
    prob_chosen[as.character(sample_id)] <- prob_chosen[as.character(sample_id)] - (1 / sample_use_time)

    fit_pi <- glmnet::cv.glmnet(
      x = x[c(positive_id, sample_id), , drop = FALSE],
      y = y[c(positive_id, sample_id)],
      alpha = alpha,
      type.measure = "auc",
      nfolds = nfolds,
      thresh = 1e-3,
      maxit = 1e3,
      family = "binomial"
    )

    pred_y <- stats::predict(fit_pi, newx = x, s = "lambda.min", type = "response")
    cutoff <- stats::quantile(pred_y[positive_id], qq)
    map_pred_y <- pred_y - cutoff

    if (any(map_pred_y > 0)) {
      map_pred_y[map_pred_y > 0] <- map_pred_y[map_pred_y > 0] / max(map_pred_y[map_pred_y > 0])
    }
    if (any(map_pred_y < 0)) {
      map_pred_y[map_pred_y < 0] <- map_pred_y[map_pred_y < 0] / abs(min(map_pred_y[map_pred_y < 0]))
    }

    pred_y <- 1 / (1 + exp(-10 * map_pred_y))
    pseudo_labels[sample_id] <- pred_y[sample_id] * learning_rate + (1 - learning_rate) * pseudo_labels[sample_id]

    label_sample_id_old <- y[sample_id]
    y[sample_id] <- stats::rbinom(length(sample_id), 1, pseudo_labels[sample_id])
    label_sample_id_new <- y[sample_id]

    prob_chosen[prob_chosen <= 0] <- 0
    unchanged <- sum(label_sample_id_old == label_sample_id_new) / length(sample_id)
    change_proportion <- c(change_proportion[-1], unchanged)
    n_iter <- i

    if (isTRUE(verbose) && (i %% 10 == 0 || i == 1)) {
      message(sprintf("Iteration %d: unchanged=%.3f", i, unchanged))
    }

    if (sum(prob_chosen <= 0.01) > (convergence_threshold * length(prob_chosen))) {
      if (isTRUE(verbose)) message("Stopping: sampling budget exhausted.")
      stop_reason <- "budget_exhausted"
      break
    }

    if (mean(change_proportion) > convergence_threshold) {
      if (isTRUE(verbose)) message("Stopping: label stability reached.")
      stop_reason <- "label_stability"
      break
    }
  }

  fit_pi <- glmnet::cv.glmnet(x, y, family = "binomial")
  pred_y <- stats::predict(fit_pi, newx = x, s = "lambda.min", type = "response")
  cutoff <- stats::quantile(pred_y[positive_id], qq)
  pred_coef1 <- glmnet::coef.glmnet(fit_pi, s = "lambda.min")

  xplus_model <- new_xplus(
    fit_xplus = fit_pi,
    pred_y = pred_y,
    cutoff = cutoff,
    predicted_coefficients = pred_coef1,
    n_iter = n_iter,
    x = x,
    y = y,
    alpha = alpha,
    learning_rate = learning_rate,
    qq = qq,
    max_iter = max_iter,
    stop_reason = stop_reason,
    call = this.call
  )

  validate_xplus(xplus_model)
}
