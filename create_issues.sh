#!/usr/bin/env bash
# Run with: bash create_issues.sh
set -e
REPO="alrobles/xplus"

gh issue create --repo "$REPO" \
  --title "bug: Double sigmoid in assess.xplus corrupts all metrics" \
  --label "bug" \
  --body "## Summary
\`assess.xplus\` passes predicted probabilities (already in \`[0,1]\`) into \`xplus_cv_lognet()\`, which immediately applies a sigmoid again at line 35:

\`\`\`r
predmat <- 1 / (1 + exp(-predmat))
\`\`\`

\`xplus_cv_lognet\` expects log-odds (linear predictor), not probabilities. A raw probability of 0.9 gets compressed to σ(0.9) ≈ 0.71, and 0.1 to σ(0.1) ≈ 0.52. All five metrics (deviance, class, AUC, MSE, MAE) are therefore **systematically wrong**.

## Files / Lines
- \`R/assess.xplus.R:27\` — passes \`type=\"response\"\`
- \`R/xplus_cv_lognet.R:35\` — applies sigmoid again

## Fix
In \`assess.xplus\`, change:
\`\`\`r
predmat <- predict(object, newx = newx, ...)
\`\`\`
to:
\`\`\`r
predmat <- predict(object, newx = newx, type = \"link\", ...)
\`\`\`
(and ensure \`predict.xplus\` supports \`type=\"link\"\` via glmnet's linear predictor)

## Priority
Critical — all evaluation results are wrong."

gh issue create --repo "$REPO" \
  --title "bug: all-zero prob_chosen vector causes sample() crash" \
  --label "bug" \
  --body "## Summary
In \`xplus()\`, the vector \`prob_chosen\` is decremented each iteration and clamped to 0 (line 109). The convergence check (line 118) fires when >90% are ≤ 0.01, but if **all** elements reach exactly 0 before the threshold triggers, \`sample(..., prob = prob_chosen)\` on the next iteration throws:

\`\`\`
Error: NA values not permitted in 'prob'
\`\`\`

This can happen with small datasets or large \`sample_use_time\` relative to the unlabeled set size.

## Files / Lines
- \`R/xplus.R:76\` — \`sample()\` call
- \`R/xplus.R:109\` — clamping
- \`R/xplus.R:118\` — convergence check

## Fix
Add after line 109:
\`\`\`r
if (all(prob_chosen <= 0)) {
  if (isTRUE(verbose)) message(\"Stopping: all sampling probabilities exhausted.\")
  break
}
\`\`\`"

gh issue create --repo "$REPO" \
  --title "bug: alpha parameter not validated in [0,1] range" \
  --label "bug" \
  --body "## Summary
\`xplus()\` validates that \`alpha\` is numeric and scalar, but **not** that it is in \`[0, 1]\` (required by \`glmnet\`). Passing \`alpha = 2\` gives an unhelpful error from deep inside glmnet instead of a clear user-facing message.

## Files / Lines
- \`R/xplus.R:51\`

## Fix
\`\`\`r
if (!is.numeric(alpha) || length(alpha) != 1 || alpha < 0 || alpha > 1)
  stop(\"\`alpha\` must be a numeric scalar in [0, 1].\", call. = FALSE)
\`\`\`"

gh issue create --repo "$REPO" \
  --title "enhancement: add seed parameter for reproducibility" \
  --label "enhancement" \
  --body "## Summary
\`xplus()\` uses \`sample()\`, \`rbinom()\`, and \`cv.glmnet()\`'s internal fold assignment — all stochastic. Results vary substantially between runs with the same inputs unless the caller wraps in \`set.seed()\`.

Since this package targets scientific use, results should be reproducible by default.

## Proposed change
Add a \`seed = NULL\` parameter:
\`\`\`r
xplus <- function(x, y, ..., seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  ...
}
\`\`\`

## Files / Lines
- \`R/xplus.R:34\` — function signature"

gh issue create --repo "$REPO" \
  --title "enhancement: un-export xplus_cv_lognet (internal helper)" \
  --label "enhancement" \
  --body "## Summary
\`xplus_cv_lognet()\` is marked \`@export\` and appears in NAMESPACE, but it is an internal computation helper only called by \`assess.xplus\`. Exporting it pollutes the user API and means it must remain stable across versions.

## Fix
Change \`@export\` to \`@noRd\` in \`R/xplus_cv_lognet.R:14\`, regenerate NAMESPACE.

## Files / Lines
- \`R/xplus_cv_lognet.R:14\`
- \`NAMESPACE:19\`"

gh issue create --repo "$REPO" \
  --title "bug: convergence window initialized with zeros delays early stopping" \
  --label "bug" \
  --body "## Summary
The 5-element rolling-mean window for convergence is initialized as all zeros:
\`\`\`r
change_proportion <- rep(0, 5)  # R/xplus.R:72
\`\`\`
In the first 4 iterations the mean is depressed by 3–4 artificial zeros, preventing early stopping even when convergence is immediate.

## Fix
\`\`\`r
change_proportion <- rep(NA_real_, 5)
# later: mean(change_proportion, na.rm = TRUE) > convergence_threshold
\`\`\`

## Files / Lines
- \`R/xplus.R:72\`, \`R/xplus.R:123\`"

gh issue create --repo "$REPO" \
  --title "enhancement: distinguish convergence reasons in summary.xplus" \
  --label "enhancement" \
  --body "## Summary
\`summary.xplus\` stores:
\`\`\`r
convergence_reached = object\$n_iter < object\$max_iter
\`\`\`
This conflates two different stopping conditions: (a) label stability reached, and (b) sampling budget exhausted. Users need to know **why** the run stopped to interpret results.

## Proposed change
Add a \`stop_reason\` field (values: \`\"max_iter\"\`, \`\"label_stability\"\`, \`\"budget_exhausted\"\`) to the \`xplus\` object, stored during fitting and surfaced in \`summary.xplus\`.

## Files / Lines
- \`R/xplus.R\` — set stop_reason in each break condition
- \`R/new_xplus.R\` — add field to constructor
- \`R/summary.xplus.R:30\` — replace convergence_reached"

gh issue create --repo "$REPO" \
  --title "performance: x and y matrices stored verbatim in xplus object" \
  --label "performance" \
  --body "## Summary
\`new_xplus()\` stores the full training matrix \`x\` (n × p) and label vector \`y\` inside every fitted object. \`x\` is only used in \`summary.xplus\` for \`nrow()\`/\`ncol()\`. For high-dimensional data (the package's stated use case), this can use hundreds of megabytes per model.

## Proposed change
Store dimensions only: add \`n_obs = nrow(x)\` and \`n_features = ncol(x)\` to the object. If retraining helpers need \`x\`, document that explicitly.

## Files / Lines
- \`R/new_xplus.R:40-56\`
- \`R/summary.xplus.R:20\` — update to use stored dimensions"

gh issue create --repo "$REPO" \
  --title "bug: get_predictions() calls predict() twice unnecessarily" \
  --label "bug" \
  --body "## Summary
\`get_predictions()\` calls \`predict()\` twice on the same \`newx\`:
\`\`\`r
predicted <- predict(object, newx = newx, s = \"lambda.min\", type = \"class\")
class1    <- predict(object, newx = newx, s = \"lambda.min\", type = \"response\")
\`\`\`
Both could be derived from a single \`type=\"response\"\` call, halving compute cost.

## Fix
\`\`\`r
class1    <- as.numeric(predict(object, newx = newx, s = \"lambda.min\", type = \"response\"))
predicted <- as.factor(class1 > object\$cutoff)
\`\`\`

## Files / Lines
- \`R/get_predictions.R:23-25\`"

gh issue create --repo "$REPO" \
  --title "docs: dataset documentation is skeletal (lacs, binexample, lacsSample)" \
  --label "documentation" \
  --body "## Summary
The three bundled dataset R files contain only format notes with no column descriptions, no \`@source\`, and no usage context:

- \`R/lacs.R\` — just \`\"A data frame.\"\`
- \`R/binexample.R\` — just \`\"A data frame.\"\`
- \`R/lacsSample.R\` — just \`\"A data frame.\"\`

This is insufficient for CRAN submission and makes the datasets unusable without examining raw CSV files.

## Required for CRAN
Add column names, types, and \`@source\` to all three dataset documentation files."

gh issue create --repo "$REPO" \
  --title "docs: new_xplus example uses \\dontrun — not verified by R CMD check" \
  --label "documentation" \
  --body "## Summary
The example in \`R/new_xplus.R\` uses \`\\dontrun\`, which means it is **never executed** by \`R CMD check --run-donttest\`. This means the constructor example is completely unverified.

## Fix
Change \`\\dontrun\` to \`\\donttest\` so the example is checked during extended test runs.

## Files / Lines
- \`R/new_xplus.R:19\`"

gh issue create --repo "$REPO" \
  --title "docs: data-raw scripts reference stale function names (new_plus, fit_plus)" \
  --label "documentation" \
  --body "## Summary
The data-raw scripts reference old function names from before the package rename:
- \`plus_object_example_construction.R:1\` — calls \`new_plus()\` (doesn't exist, should be \`new_xplus()\`)
- \`use_fit_examples.R:1\` — references \`fit_plus_example\`, \`fit_plus\` (old names)

These scripts are not runnable and mislead future maintainers.

## Fix
Update scripts to use current names: \`new_xplus()\`, \`fit_xplus_example\`, etc."

gh issue create --repo "$REPO" \
  --title "tests: expand test suite (many code paths uncovered)" \
  --label "tests" \
  --body "## Summary
The current test suite has 3 files and ~30 lines, covering only the happy path. Identified gaps:

- No tests for any input validation error paths (\`non-matrix x\`, dim mismatch, invalid alpha)
- No tests for \`coef.xplus\`, \`summary.xplus\`, \`print.xplus\`, \`print.summary.xplus\`
- No tests for \`get_auc\`, \`get_predictions\`
- No tests for \`auc\`, \`auc_matrix\`
- No tests for \`new_xplus\` / \`validate_xplus\`
- No tests for \`xplus_cv_lognet\`
- No test for \`predict.xplus\` with \`newx = NULL\`
- No edge-case tests: single positive, all-positive, p > n, zero-variance columns

## Proposed test plan
\`\`\`
test-input-validation.R    — error paths for all validated args
test-coef-summary-print.R  — S3 method return shapes
test-get-auc-get-predictions.R
test-assess-metrics.R      — verify AUC ≥ 0.5 on separable data (regression for double-sigmoid bug)
test-auc.R                 — auc() = 1.0 on perfect separation, ≈ 0.5 on random
test-edge-cases.R          — p>n, single positive, newx=NULL consistency
\`\`\`"

gh issue create --repo "$REPO" \
  --title "ci: add multi-platform matrix and --as-cran check" \
  --label "ci" \
  --body "## Summary
The current CI workflow (\`.github/workflows/R-CMD-check.yaml\`) only runs on \`ubuntu-latest\` and does not pass \`--as-cran\` to \`R CMD check\`. CRAN submission requires multi-platform passing results.

## Proposed changes
1. Add macOS and Windows to the build matrix
2. Pass \`error-on: note\` or \`--as-cran\` to \`check-r-package\` action
3. Add code coverage step using \`covr\` (already listed in Suggests)

## Files / Lines
- \`.github/workflows/R-CMD-check.yaml\`"

gh issue create --repo "$REPO" \
  --title "enhancement: add sparse matrix input support for x" \
  --label "enhancement" \
  --body "## Summary
The package advertises 'sparse structures' in its title and description, but \`xplus()\` requires \`x\` to be a dense \`matrix\`. \`glmnet\` natively accepts sparse matrices (\`Matrix::sparseMatrix\`), so subsetting and passing \`x\` through the loop could avoid dense materialization.

Also: no check for zero-variance columns (glmnet silently drops them, which can cause predict/coef misalignment).

## Proposed changes
1. Accept \`x\` as \`matrix\` or \`sparseMatrix\`
2. Detect and warn on zero-variance columns before fitting
3. Detect and error on \`NA\` values in \`x\`

## Files / Lines
- \`R/xplus.R:48-50\` — input validation block"

gh issue create --repo "$REPO" \
  --title "enhancement: expose convergence tuning parameters (thresh, maxit)" \
  --label "enhancement" \
  --body "## Summary
The iterative \`cv.glmnet\` calls use tighter stopping criteria (\`thresh=1e-3\`, \`maxit=1e3\`) than the final fit (glmnet defaults). This is intentional for performance but undocumented and not configurable.

For large p datasets, users may need to tune these.

## Proposed change
Add \`thresh_iter = 1e-3\` and \`maxit_iter = 1e3\` to \`xplus()\` signature with documentation explaining the trade-off.

## Files / Lines
- \`R/xplus.R:86-87\` — iterative fit args
- \`R/xplus.R:34\` — function signature"

gh issue create --repo "$REPO" \
  --title "enhancement: add class prior estimation step" \
  --label "enhancement" \
  --body "## Summary
The PLUS paper (Zhou et al. 2022) describes estimating π (proportion of true positives among unlabeled observations). The current implementation skips this step; the algorithm treats all unlabeled samples symmetrically without accounting for the prior.

Adding a prior estimation step (e.g., using the 'spy' method or the TIcE estimator) would improve calibration and better match the reference algorithm.

## References
- Zhou et al. (2022) doi:10.1371/journal.pcbi.1009956
- du Plessis et al. (2014) — TIcE estimator
- Liu et al. (2002) — spy technique"

echo "All issues created!"
