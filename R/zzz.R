.onLoad <- function(libname, pkgname) {
  op <- options()
  op.xplus <- list(
    future.globals.maxSize = 8.0 * 1024^3
  )
  toset <- !(names(op.xplus) %in% names(op))
  if (any(toset)) options(op.xplus[toset])
  assign(".xplus_env", new.env(), envir = parent.env(environment()))
}

xplusStartupMessage <- function()
{
  msg <- c(paste0(
    "            _\n__  ___ __ | |_   _ ___\n\\ \\/ / '_ \\| | | | / __|\n >  <| |_) | | |_| \\__ \\\n/_/\\_\\ .__/|_|\\__,_|___/\n     |_|",
    "    version ",
    utils::packageVersion("xplus")),
    "\nType 'citation(\"xplus\")' for citing this R package in publications.\n"
  )

  return(msg)
}

.onAttach <- function(lib, pkg)
{
  unlockBinding(".xplus_env", asNamespace("xplus"))
  msg <- xplusStartupMessage()
  if (!interactive())
    msg[1] <- paste("Package 'xplus' version", utils::packageVersion("xplus"))
  packageStartupMessage(msg)
  invisible()
}

