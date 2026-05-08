#!/usr/bin/env Rscript
#
# generate_zzz.R
# ---------------
# Reusable script to generate R/zzz.R with an ASCII art startup logo
# for any R package. Uses `figlet` (must be installed) to render the
# package name in ASCII art.
#
# Usage:
#   Rscript inst/tools/generate_zzz.R <package_name> [output_path] [--has-dynlib]
#
# Arguments:
#   package_name  Name of the R package (e.g. "xplus", "xsdm", "nicher")
#   output_path   Where to write the file (default: R/zzz.R)
#   --has-dynlib  Include .onUnload with library.dynam.unload (for packages
#                 with compiled C/C++ code)
#
# Examples:
#   Rscript inst/tools/generate_zzz.R xplus
#   Rscript inst/tools/generate_zzz.R xsdm R/zzz.R --has-dynlib
#   Rscript inst/tools/generate_zzz.R nicher ../nicher/R/zzz.R

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop(
    "Usage: Rscript generate_zzz.R <package_name> [output_path] [--has-dynlib]\n",
    call. = FALSE
  )
}

pkg_name    <- args[1]
has_dynlib  <- "--has-dynlib" %in% args
other_args  <- setdiff(args, c(pkg_name, "--has-dynlib"))
output_path <- if (length(other_args) >= 1) other_args[1] else "R/zzz.R"

# --- Generate ASCII art via figlet ----------------------------------------
figlet_check <- Sys.which("figlet")
if (figlet_check == "") {
  stop(
    "figlet is not installed. Install it with:\n",
    "  sudo apt-get install figlet   # Debian/Ubuntu\n",
    "  brew install figlet            # macOS\n",
    call. = FALSE
  )
}

ascii_raw <- system2("figlet", args = c("-f", "standard", pkg_name),
                      stdout = TRUE, stderr = TRUE)

# Remove trailing blank lines and trailing whitespace per line
ascii_lines <- sub("\\s+$", "", ascii_raw)
while (length(ascii_lines) > 0 && ascii_lines[length(ascii_lines)] == "") {
  ascii_lines <- ascii_lines[-length(ascii_lines)]
}

# Escape backslashes for embedding inside R double-quoted strings
ascii_for_r <- gsub("\\\\", "\\\\\\\\", ascii_lines)

# Build the multi-line art as it will appear inside the R source string
ascii_block <- paste(ascii_for_r, collapse = "\\n")

# --- Build zzz.R content via template -------------------------------------
# Use gsub with fixed=TRUE to avoid regex escaping issues

template <- '.onLoad <- function(libname, pkgname) {
  op <- options()
  op.<<PKG>> <- list(
    future.globals.maxSize = 8.0 * 1024^3
  )
  toset <- !(names(op.<<PKG>>) %in% names(op))
  if (any(toset)) options(op.<<PKG>>[toset])
  assign(".<<PKG>>_env", new.env(), envir = parent.env(environment()))
}

<<PKG>>StartupMessage <- function()
{
  msg <- c(paste0(
    "<<ASCII_ART>>",
    "    version ",
    utils::packageVersion("<<PKG>>")),
    "\\nType <<SQ>>citation(\\"<<PKG>>\\")<<SQ>> for citing this R package in publications.\\n"
  )

  return(msg)
}

.onAttach <- function(lib, pkg)
{
  unlockBinding(".<<PKG>>_env", asNamespace("<<PKG>>"))
  msg <- <<PKG>>StartupMessage()
  if (!interactive())
    msg[1] <- paste("Package <<SQ>><<PKG>><<SQ>> version", utils::packageVersion("<<PKG>>"))
  packageStartupMessage(msg)
  invisible()
}
'

dynlib_template <- '
.onUnload <- function(libpath) {
  library.dynam.unload("<<PKG>>", libpath)
}
'

# Substitute placeholders
zzz_content <- template
zzz_content <- gsub("<<PKG>>", pkg_name, zzz_content, fixed = TRUE)
zzz_content <- gsub("<<ASCII_ART>>", ascii_block, zzz_content, fixed = TRUE)
zzz_content <- gsub("<<SQ>>", "'", zzz_content, fixed = TRUE)

if (has_dynlib) {
  dynlib_block <- gsub("<<PKG>>", pkg_name, dynlib_template, fixed = TRUE)
  zzz_content <- paste0(zzz_content, dynlib_block)
}

# --- Write output ----------------------------------------------------------
output_dir <- dirname(output_path)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

writeLines(zzz_content, con = output_path)

cat(sprintf("Generated %s for package '%s'\n", output_path, pkg_name))
cat(sprintf("ASCII art font: standard (figlet)\n"))
if (has_dynlib) {
  cat("Included .onUnload with library.dynam.unload()\n")
}
cat("\nPreview of startup message:\n")
cat(paste(ascii_lines, collapse = "\n"), "\n")
