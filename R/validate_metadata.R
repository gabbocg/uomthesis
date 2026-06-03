#' Validate the uomthesis: YAML block in a project
#'
#' Runs the metadata-level checks (a subset of `check_thesis()`'s source-phase
#' rules) without touching any chapter content.
#'
#' @param project Path to project root.
#' @return An object of class `uomthesis_metadata_check` (a named list with
#'   fields `ok` (logical) and `findings` (list of finding records)).
#' @export
#' @examples
#' \dontrun{
#' validate_metadata(".")
#' }
validate_metadata <- function(project = ".") {
  root <- locate_project(project)
  meta <- read_uomthesis_metadata(root)
  p <- policy_constants()
  findings <- list()

  required <- c("candidate.surname", "degree", "faculty", "school",
                "year", "thesis_format")
  for (key in required) {
    parts <- strsplit(key, "\\.")[[1]]
    val <- Reduce(function(acc, k) if (is.null(acc)) NULL else acc[[k]],
                  parts, init = meta)
    if (is.null(val) || identical(val, "")) {
      findings <- c(findings, list(list(
        rule_id    = "metadata-complete",
        severity   = "error",
        message    = cli::format_inline("Required field {.field {key}} is missing or empty."),
        location   = list(file = "index.qmd"),
        policy_ref = "\u00a78.1.b",
        hint       = "Add the field under the uomthesis: block in index.qmd."
      )))
    }
  }

  if (!is.null(meta$degree) && !meta$degree %in% p$allowed_degrees) {
    findings <- c(findings, list(list(
      rule_id    = "degree-faculty-school",
      severity   = "error",
      message    = cli::format_inline("Degree {.val {meta$degree}} is not in the allowed set."),
      location   = list(file = "index.qmd"),
      policy_ref = "\u00a78.1.b",
      hint       = paste0("Use one of: ", paste(p$allowed_degrees, collapse = ", "), ".")
    )))
  }
  if (!is.null(meta$faculty) && !meta$faculty %in% p$allowed_faculties) {
    findings <- c(findings, list(list(
      rule_id    = "degree-faculty-school",
      severity   = "error",
      message    = cli::format_inline("Faculty {.val {meta$faculty}} is not in the allowed set."),
      location   = list(file = "index.qmd"),
      policy_ref = "\u00a78.1.b",
      hint       = paste0("Use one of: ", paste(p$allowed_faculties, collapse = ", "), ".")
    )))
  }
  if (!is.null(meta$school) && !meta$school %in% p$allowed_schools) {
    findings <- c(findings, list(list(
      rule_id    = "degree-faculty-school",
      severity   = "error",
      message    = cli::format_inline("School {.val {meta$school}} is not in the allowed set."),
      location   = list(file = "index.qmd"),
      policy_ref = "\u00a78.1.b",
      hint       = paste0("Use one of: ", paste(p$allowed_schools, collapse = ", "), ".")
    )))
  }
  if (!is.null(meta$thesis_format) && !meta$thesis_format %in% c("standard", "journal")) {
    findings <- c(findings, list(list(
      rule_id    = "thesis-format",
      severity   = "error",
      message    = cli::format_inline("thesis_format {.val {meta$thesis_format}} must be 'standard' or 'journal'."),
      location   = list(file = "index.qmd"),
      policy_ref = "\u00a74.6",
      hint       = "Set thesis_format: standard or thesis_format: journal."
    )))
  }
  if (!is.null(meta$year)) {
    if (!is.numeric(meta$year) || meta$year < 2000 || meta$year > 2100) {
      findings <- c(findings, list(list(
        rule_id    = "year-not-month",
        severity   = "error",
        message    = "year must be an integer between 2000 and 2100.",
        location   = list(file = "index.qmd"),
        policy_ref = "\u00a78.1.b",
        hint       = "year: 2027 (no month)."
      )))
    }
  }

  out <- list(ok = length(findings) == 0, findings = findings)
  class(out) <- c("uomthesis_metadata_check", "list")
  out
}

#' @export
print.uomthesis_metadata_check <- function(x, ...) {
  if (x$ok) {
    cli::cli_alert_success("Metadata is valid - no findings.")
    return(invisible(x))
  }
  cli::cli_h1("Metadata findings ({length(x$findings)})")
  for (f in x$findings) {
    cli::cli_li("{.strong {f$rule_id}} ({f$severity}) {.emph {f$policy_ref}}")
    cli::cli_text("{f$message}")
    if (nzchar(f$hint)) cli::cli_alert_info("{f$hint}")
  }
  invisible(x)
}
