#' Build a tidy prediction table
#'
#' @param object An `xplus` model object.
#' @param newx Feature matrix.
#' @param newy True labels.
#' @param use_cutoff Logical; if `TRUE`, classify with the model's cutoff. If `FALSE`,
#' classify with the default glmnet cutoff.
#'
#' @return A tibble with truth labels, probabilities and predicted classes.
#' @seealso [predict.xplus()], [assess()]
#' @references Robles et al. (2022). doi:10.1371/journal.pcbi.1009956
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(100 * 5), ncol = 5)
#' y <- c(rep(1, 20), rep(0, 80))
#' fit <- xplus(x, y, max_iter = 5)
#' get_predictions(fit, x, y)
#' @export
get_predictions <- function(object, newx, newy, use_cutoff = TRUE) {
  truth <- ifelse(newy == 1, "Class1", "Class2") |> as.factor()

  if (isTRUE(use_cutoff)) {
    predicted <- predict(object, newx = newx, s = "lambda.min", type = "class")
    predicted <- ifelse(predicted == 1, "Class1", "Class2") |> as.factor()
    class1 <- predict(object, newx = newx, s = "lambda.min", type = "response") |> as.numeric()
  } else {
    predicted <- predict(object$xplus, newx = newx, type = "class") |> as.factor()
    predicted <- ifelse(predicted == 1, "Class1", "Class2") |> as.factor()
    class1 <- predict(object$xplus, newx = newx, type = "response") |> as.numeric()
  }

  class2 <- 1 - class1

  tibble::as_tibble(
    data.frame(truth = truth, Class1 = class1, Class2 = class2, predicted)
  )
}
