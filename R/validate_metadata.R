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
