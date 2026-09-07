# Validate an xplus object

Validate an xplus object

## Usage

``` r
validate_xplus(xplus_object)
```

## Arguments

- xplus_object:

  An object of class `"xplus"`.

## Value

The validated `xplus` object.

## Examples

``` r
if (FALSE) { # \dontrun{
fit <- glmnet::cv.glmnet(matrix(rnorm(50), ncol = 5), c(rep(1, 5), rep(0, 5)), family = "binomial")
obj <- new_xplus(fit_xplus = fit, pred_y = matrix(0.5, 10, 1), cutoff = 0.5)
validate_xplus(obj)
} # }
```
