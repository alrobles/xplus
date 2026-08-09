# xplus 0.1.1

* Fixed a crash when the pseudo-labels of the iterative training subset
  collapse to a single class: fitting now stops cleanly with
  `stop_reason = "degenerate_labels"` instead of failing inside
  `glmnet::cv.glmnet()`.
* Sampling probabilities are now clamped at zero when the unlabeled-sampling
  budget is decremented, and sampling is skipped once the budget is fully
  exhausted (avoids an uninformative `sample()` error).

# xplus 0.1.0

* Initial release.
* Implements the PLUS algorithm for positive-unlabeled learning
  (Zhou et al., 2022, doi:10.1371/journal.pcbi.1009956).
* Provides `xplus()` fitting function with iterative pseudo-label updates.
* S3 methods: `predict()`, `coef()`, `summary()`, `print()`, `assess()`,
  `get_auc()`, and `get_predictions()`.
* Ships bundled datasets: `lacs`, `lacsSample`, and `binexample`.
