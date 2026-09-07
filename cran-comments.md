## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a resubmission of xplus 1.0.0.

## Test environments

* local: Ubuntu 22.04, R 4.1.2
* win-builder (via CRAN incoming pre-test): r-devel, r-release

## Why the first submission (1.0.0) failed the CRAN incoming pre-tests

The CRAN auto-check service reported 2 NOTEs:

1. **CRAN incoming feasibility**
   - `Description` in `DESCRIPTION` contained `Zhou et al. (2022)`, which the
     spell-checker flagged as `Zhou`, `et`, and `al`.
   - `README.md` and `NEWS.md` contained a URL to a private development
     repository (`https://github.com/alrobles/xplus-develeopment`) that
     returned 404 for the CRAN URL checker.

2. **top-level files**
   - `LICENSE.md` and `cran-comments.md` were present in the package tarball.
     They are repository-level files and should not be included in the source
     package.

## Fixes applied

* Reworded `Description` in `DESCRIPTION` to avoid the author name and the
  `et`/`al` strings, keeping the DOI reference.
* Removed the private development repository URL from `NEWS.md` and `README.md`.
* Ensured `LICENSE.md` and `cran-comments.md` are listed in `.Rbuildignore`
  so they do not enter the source tarball.
