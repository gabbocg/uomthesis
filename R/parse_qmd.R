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

#' Classify a .qmd/.bib file by role
#' @param path File path or filename.
#' @return One of "prelim", "body", "appendix", "bibliography".
#' @keywords internal
classify_qmd_file <- function(path) {
  base <- basename(path)
  if (grepl("\\.bib$", base, ignore.case = TRUE)) return("bibliography")
  if (grepl("^appendix", base, ignore.case = TRUE)) return("appendix")
  if (grepl("^00-", base)) return("prelim")
  "body"
}

#' Read the uomthesis: metadata block from a project's index.qmd
#' @param project_path Path to project root (contains _quarto.yml + index.qmd).
#' @return A list of the uomthesis block; errors if missing.
#' @keywords internal
read_uomthesis_metadata <- function(project_path) {
  idx <- file.path(project_path, "index.qmd")
  if (!file.exists(idx)) {
    cli::cli_abort(c(
      "No {.file index.qmd} in {.path {project_path}}.",
      i = "Did you run {.run uomthesis::create_thesis()}?"
    ), class = "uomthesis_no_index")
  }
  fm <- parse_qmd_yaml(idx)
  if (is.null(fm$uomthesis)) {
    cli::cli_abort(c(
      "{.file index.qmd} has no {.field uomthesis:} block.",
      i = "Add the uomthesis metadata block; see {.run uomthesis::create_thesis()}."
    ), class = "uomthesis_no_metadata")
  }
  fm$uomthesis
}
