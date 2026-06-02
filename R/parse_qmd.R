#' Parse the YAML front-matter of a .qmd file
#' @param path Path to a .qmd file.
#' @return A list, possibly empty.
#' @keywords internal
parse_qmd_yaml <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  if (length(lines) < 2L || !grepl("^---\\s*$", lines[[1L]])) {
    return(list())
  }
  end <- which(grepl("^---\\s*$", lines))[2L]
  if (is.na(end)) return(list())
  yaml::yaml.load(paste(lines[2:(end - 1L)], collapse = "\n"))
}
