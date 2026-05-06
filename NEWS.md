# xplus 0.1.0

* Initial release.
* Implements the PLUS algorithm for positive-unlabeled learning
  (Zhou et al., 2022, doi:10.1371/journal.pcbi.1009956).
* Provides `xplus()` fitting function with iterative pseudo-label updates.
* S3 methods: `predict()`, `coef()`, `summary()`, `print()`, `assess()`,
  `get_auc()`, and `get_predictions()`.
* Ships bundled datasets: `lacs`, `lacsSample`, and `binexample`.
