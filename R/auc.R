#' Compute area under the ROC curve
#'
#' @param y True binary labels.
#' @param prob Predicted probabilities.
#' @param w Optional sample weights.
#'
#' @return Numeric AUC value.
#' @seealso [auc_matrix()], [get_auc()]
#' @references Zhou et al. (2022). doi:10.1371/journal.pcbi.1009956
#' @examples
#' y <- c(0, 0, 1, 1)
#' p <- c(0.1, 0.3, 0.7, 0.9)
#' auc(y, p)
#' @export
auc <- function(y, prob, w) {
  if (missing(w)) {
    survival::concordance(y ~ prob)$concordance
  } else {
    survival::concordance(y ~ prob, weights = w)$concordance
  }
}
