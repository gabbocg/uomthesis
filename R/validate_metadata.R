# Rule IDs that belong to the metadata-only validation pass.
metadata_rule_ids <- c(
  "metadata-complete",
  "degree-faculty-school",
  "year-not-month",
  "thesis-format"
)

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
  ctx  <- build_ctx(root)

  findings <- list()
  for (r in rule_registry()) {
    if (!r$id %in% metadata_rule_ids) next
    f <- r$check(ctx)
    if (!is.null(f)) findings <- c(findings, list(f))
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
