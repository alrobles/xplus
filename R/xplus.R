#' Fit an xplus model
#'
#' Fit the PLUS algorithm for positive-unlabeled learning.
#'
#' @param x Numeric feature matrix.
#' @param y Binary vector where `1` indicates known positives and `0` indicates unlabeled samples.
#' @param alpha Elastic-net mixing parameter passed to [glmnet::cv.glmnet()].
#' @param sample_use_time Package extension controlling the unlabeled-sampling budget:
#'   number of times each unlabeled sample can be selected before its sampling
#'   probability reaches zero.
#' @param learning_rate Package extension controlling pseudo-label smoothing in
#'   `[0, 1]`.
#' @param qq Quantile used to define the positive-reference cutoff.
#' @param verbose Logical; print iterative progress messages.
#' @param nfolds Number of CV folds used in the iterative fit.
#' @param max_iter Maximum number of pseudo-labeling iterations.
#' @param convergence_threshold Proportion threshold for soft-label stabilization and sampling exhaustion checks.
#' @param seed Optional random seed for reproducibility.
#'
#' @details
#' Core PLUS behavior alternates between fitting penalized logistic models on known
#' positives plus sampled unlabeled cases, calibrating predictions with a positive
#' quantile cutoff, and iteratively relabeling unlabeled samples.
#'
#' `xplus` also provides package-specific extensions in the
#' `"continuous_enhancement"` path (`learning_rate < 1`):
#' - pseudo-label smoothing via `learning_rate`
#' - global unlabeled updates each iteration (instead of only sampled cases)
#' - practical stopping heuristics based on a rolling soft-label stabilization
#'   score and unlabeled-sampling budget exhaustion (`sample_use_time`)
#'
#' User-facing semantics are:
#' - `learning_rate = 1` keeps the `"current"` path behavior
#' - `learning_rate < 1` enables the `"continuous_enhancement"` extensions
#'
#' @return An object of class `"xplus"`.
#' @references Zhou et al. (2022). doi:10.1371/journal.pcbi.1009956
#' @seealso [predict.xplus()], [summary.xplus()], [assess.xplus()]
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(200 * 10), ncol = 10)
#' y <- c(rep(1, 40), rep(0, 160))
#' fit <- xplus(x, y, max_iter = 20)
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
  convergence_threshold = 0.9,
  seed = NULL
) {
  this.call <- match.call()

  if (!is.null(seed)) {
    set.seed(seed)
  }

  if (!is.matrix(x)) stop("`x` must be a matrix.", call. = FALSE)
  if (nrow(x) != length(y)) stop("`x` and `y` must have matching dimensions.", call. = FALSE)
  if (anyNA(x)) stop("`x` must not contain NA values.", call. = FALSE)
  if (any(is.infinite(x))) stop("`x` must not contain Inf values.", call. = FALSE)
  if (!all(y %in% c(0, 1))) stop("`y` must contain only 0 and 1.", call. = FALSE)
  if (!is.numeric(alpha) || length(alpha) != 1) stop("`alpha` must be a scalar numeric value.", call. = FALSE)
  if (!is.numeric(sample_use_time) || sample_use_time <= 0) stop("`sample_use_time` must be > 0.", call. = FALSE)
  if (sample_use_time != round(sample_use_time)) stop("`sample_use_time` must be an integer-like value.", call. = FALSE)
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
  iterative_path <- if (learning_rate < 1) "continuous_enhancement" else "current"
  prob_chosen <- rep(1, length(unlabeled_id))
  names(prob_chosen) <- unlabeled_id
  change_proportion <- rep(0, 5)
  # Residuals below this threshold are effectively at numerical precision.
  degenerate_threshold <- 1e-6
  pseudo_label_cutoff <- 0.5
  n_iter <- 0
  # If no early stopping condition triggers, fitting stops at max_iter.
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

    map_pred_y <- normalize_residuals(map_pred_y, degenerate_threshold)

    pred_y <- 1 / (1 + exp(-10 * map_pred_y))
    update_indices <- if (identical(iterative_path, "continuous_enhancement")) unlabeled_id else sample_id
    pseudo_labels_before_update <- pseudo_labels[update_indices]
    pseudo_labels[update_indices] <- pred_y[update_indices] * learning_rate + (1 - learning_rate) * pseudo_labels[update_indices]

    if (identical(iterative_path, "continuous_enhancement")) {
      y[update_indices] <- as.integer(pseudo_labels[update_indices] >= pseudo_label_cutoff)
    } else {
      y[update_indices] <- stats::rbinom(length(update_indices), 1, pseudo_labels[update_indices])
    }

    soft_label_deltas <- abs(pseudo_labels_before_update - pseudo_labels[update_indices])
    # Pseudo-labels are probabilities in [0, 1], so mean absolute movement is in [0, 1].
    stabilization_score <- 1 - mean(soft_label_deltas)

    prob_chosen[prob_chosen <= 0] <- 0
    change_proportion <- c(change_proportion[-1], stabilization_score)
    n_iter <- i

    if (isTRUE(verbose) && (i %% 10 == 0 || i == 1)) {
      message(sprintf("Iteration %d: stabilization=%.3f", i, stabilization_score))
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

  fit_pi <- glmnet::cv.glmnet(x, pseudo_labels, family = "binomial", alpha = alpha, nfolds = nfolds)
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
    y = pseudo_labels,
    alpha = alpha,
    learning_rate = learning_rate,
    pseudo_labels = pseudo_labels,
    iterative_path = iterative_path,
    qq = qq,
    stop_reason = stop_reason,
    max_iter = max_iter,
    call = this.call
  )

  validate_xplus(xplus_model)
}
