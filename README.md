# xplus

[![R-CMD-check](https://github.com/alrobles/xplus/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/alrobles/xplus/actions/workflows/R-CMD-check.yaml)

`xplus` implements the PLUS algorithm: **Positive and Unlabeled Learning from Unbalanced clases and Sparse structures**.

## Installation

```r
# install.packages("remotes")
remotes::install_github("alrobles/xplus")
```

## What is PU learning?

In Positive and Unlabeled (PU) learning, labels are available only for known positive cases. Unlabeled cases can include both true negatives and hidden positives. `xplus` iteratively relabels unlabeled cases and fits sparse logistic models to improve separation.

## Basic workflow

```r
library(xplus)
set.seed(1)
x <- matrix(rnorm(200 * 10), ncol = 10)
y <- c(rep(1, 40), rep(0, 160))

fit <- xplus(x, y, max_iter = 50)
head(predict(fit, type = "response"))
assess(fit, newx = x, newy = y)
```

## Algorithm summary

### Core PLUS behavior

1. Sample unlabeled cases and fit penalized logistic regression.
2. Predict probabilities for all samples.
3. Rescale probabilities using a quantile cutoff from known positives.
4. Iteratively relabel unlabeled cases.
5. Refit a final model with pseudo-label targets.

### Package-specific extensions in `continuous_enhancement` (`learning_rate < 1`)

- **Learning-rate smoothing** (`learning_rate`): pseudo-labels are updated as a convex combination of old and new values.
- **Sampling budget** (`sample_use_time`): each unlabeled case has a finite sampling budget.
- **Practical convergence heuristics** (`convergence_threshold`): stop when rolling soft-label stabilization is high enough or when the sampling budget is exhausted.

With `learning_rate = 1`, `xplus` keeps the `"current"` path behavior.

## Reproducible path comparison harness

You can benchmark the current and continuous-enhancement paths side by side with fixed seeds:

```bash
Rscript inst/tools/benchmark_paths.R
```

The script writes:

- `path_comparison_runs.csv` (machine-readable per-seed metrics)
- `path_comparison_summary.csv` (machine-readable aggregate metrics)
- `path_comparison_table.md` (human-readable comparison table)

Metrics include AUC, class error, coefficient support/sparsity, convergence iterations, runtime, and stability under fixed seeds.

## Reference

Zhou et al. (2022), PLoS Computational Biology, doi:10.1371/journal.pcbi.1009956.
