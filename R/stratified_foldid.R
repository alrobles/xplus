#' Build class-stratified cross-validation fold assignments
#'
#' Assigns each observation to one of `nfolds` folds so that both classes
#' are spread as evenly as possible across folds. This prevents a small
#' class from being concentrated in a single fold, which would leave a
#' cross-validation training split with fewer than the two observations
#' per class that [glmnet::glmnet()] requires for binomial fits.
#'
#' @param y Binary (0/1) vector of class labels.
#' @param nfolds Number of folds.
#'
#' @return Integer vector of fold assignments in `1:nfolds`, the same
#'   length as `y`, suitable for the `foldid` argument of
#'   [glmnet::cv.glmnet()].
#' @keywords internal
stratified_foldid <- function(y, nfolds) {
  foldid <- integer(length(y))
  for (cls in unique(y)) {
    idx <- which(y == cls)
    foldid[idx] <- sample(rep_len(seq_len(nfolds), length(idx)))
  }
  foldid
}
