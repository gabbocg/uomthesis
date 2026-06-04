#' Render a check report
#' @param report A `uomthesis_check_report`.
#' @param format "console" | "markdown" | "json".
#' @return Invisible character (markdown/json) or report (console).
#' @keywords internal
render_check_report <- function(report,
                                format = c("console", "markdown", "json")) {
  format <- match.arg(format)
  switch(format,
    console  = render_console(report),
    markdown = render_markdown(report),
    json     = render_json(report)
  )
}

render_console <- function(report) {
  errors   <- Filter(function(f) f$severity == "error",   report$findings)
  warnings <- Filter(function(f) f$severity == "warning", report$findings)
  passed   <- report$n_rules - length(report$findings)
  cli::cli_h1("uomthesis::check_thesis() - {report$format}")
  cli::cli_bullets(c(
    "v" = "{.val {passed}} rules passed",
    "x" = "{.val {length(errors)}} errors",
    "!" = "{.val {length(warnings)}} warnings"
  ))
  if (length(errors)) {
    cli::cli_h2("Errors")
    for (f in errors) print_finding(f)
  }
  if (length(warnings)) {
    cli::cli_h2("Warnings")
    for (f in warnings) print_finding(f)
  }
  invisible(report)
}

print_finding <- function(f) {
  cli::cli_li("{.strong {f$rule_id}}  {.emph {f$policy_ref}}")
  cli::cli_text(f$message)
  if (nzchar(f$hint %||% "")) cli::cli_alert_info(f$hint)
}

render_markdown <- function(report) {
  lines <- c(
    paste0("# uomthesis check report - ", report$format),
    "",
    paste0("- Rules run: ", report$n_rules),
    paste0("- Findings: ", length(report$findings)),
    ""
  )
  for (f in report$findings) {
    lines <- c(lines,
      paste0("## ", f$rule_id, " (", f$severity, " - ", f$policy_ref, ")"),
      "",
      f$message,
      "",
      paste0("**Fix:** ", f$hint),
      ""
    )
  }
  out_path <- "check-report.md"
  writeLines(lines, out_path)
  cli::cli_alert_success("Report written to {.path {out_path}}.")
  invisible(paste(lines, collapse = "\n"))
}

render_json <- function(report) {
  rlang::check_installed("jsonlite", reason = "JSON output requires jsonlite.")
  out <- jsonlite::toJSON(
    list(
      ok       = report$ok,
      findings = report$findings,
      n_rules  = report$n_rules,
      format   = report$format
    ),
    auto_unbox = TRUE, pretty = TRUE
  )
  invisible(unclass(out))
}

#' @importFrom rlang `%||%`
NULL
