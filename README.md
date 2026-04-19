# xplus

[![R-CMD-check](https://github.com/alrobles/xplus/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/alrobles/xplus/actions/workflows/R-CMD-check.yaml)

`xplus` implements the PLUS algorithm: **Positive and Unlabeled Learning from Unbalanced cases and Sparse structures**.

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

1. Sample unlabeled cases and fit penalized logistic regression.
2. Predict probabilities for all samples.
3. Rescale probabilities using a quantile cutoff from known positives.
4. Update pseudo-labels by Bernoulli sampling with a learning rate.
5. Stop when labels stabilize or sampling budget is exhausted.
6. Refit final model with relabeled data.

## Reference

Robles et al. (2022), PLoS Computational Biology, doi:10.1371/journal.pcbi.1009956.
