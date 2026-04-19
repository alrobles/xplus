#' Compute AUC from matrix labels
#'
#' @param y One-hot encoded label matrix.
#' @param prob Predicted probabilities.
#' @param weights Optional sample weights.
#'
#' @return Numeric AUC value.
#' @seealso [auc()], [xplus_cv_lognet()]
#' @references Robles et al. (2022). doi:10.1371/journal.pcbi.1009956
#' @examples
#' y <- cbind(c(1, 1, 0, 0), c(0, 0, 1, 1))
#' p <- c(0.2, 0.3, 0.7, 0.8)
#' auc_matrix(y, p)
#' @export
auc_matrix <- function(y, prob, weights) {
  ny <- nrow(y)
  Y <- rep(c(0, 1), c(ny, ny))
  Prob <- c(prob, prob)
  if (missing(weights)) {
    auc(y = Y, prob = Prob)
  } else {
    Weights <- as.vector(weights * y)
    auc(y = Y, prob = Prob, w = Weights)
  }
}
