#' Find the nearest ancestor containing _quarto.yml
#' @param start Starting directory (defaults to working directory).
#' @return Absolute path to the project root.
#' @keywords internal
locate_project <- function(start = ".") {
  start_abs <- normalizePath(start, mustWork = TRUE)
  cur <- start_abs
  repeat {
    if (file.exists(file.path(cur, "_quarto.yml"))) return(cur)
    parent <- dirname(cur)
    if (parent == cur) {
      cli::cli_abort(
        c("No Quarto project found.",
          i = "Searched up from {.path {start_abs}} but did not find a {.file _quarto.yml}."),
        class = "uomthesis_no_project"
      )
    }
    cur <- parent
  }
}
