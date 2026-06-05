#' Check a uomthesis project against the Presentation of Theses Policy
#'
#' Runs the source-phase rule registry against a scaffolded uomthesis project,
#' aggregates findings, and renders a report.
#'
#' @param project Path to project root.
#' @param rendered_pdf Optional path to a rendered PDF. **Not yet implemented**
#'   in v0.1 -- supplying a value emits a warning and only source-phase rules run.
#'   Will be honored in v0.2.
#' @param rules Optional character vector of rule IDs to restrict the run.
#' @param format Output format: console, markdown, or json.
#' @param fail_on Threshold for raising an error after reporting:
#'   "none" (informational), "warning", or "error".
#' @return Invisibly, an object of class `uomthesis_check_report`.
#' @export
check_thesis <- function(project = ".",
                         rendered_pdf = NULL,
                         rules  = NULL,
                         format = c("console", "markdown", "json"),
                         fail_on = c("none", "warning", "error")) {
  format  <- match.arg(format)
  fail_on <- match.arg(fail_on)
  root    <- locate_project(project)
  ctx     <- build_ctx(root, rendered_pdf = rendered_pdf)

  fmt <- ctx$metadata$thesis_format %||% "standard"
  applicable <- Filter(function(r) {
    (is.null(rules) || r$id %in% rules) &&
      fmt %in% r$formats &&
      (r$phase == "source" || !is.null(rendered_pdf))
  }, rule_registry())

  findings <- list()
  for (r in applicable) {
    f <- tryCatch(r$check(ctx),
                  error = function(e) list(
                    rule_id = r$id, severity = "error",
                    message = paste("Rule check errored:", conditionMessage(e)),
                    location = list(), policy_ref = r$policy_ref, hint = ""
                  ))
    if (is.null(f)) next
    # Distinguish single finding from list of findings
    if (!is.null(f$rule_id)) {
      findings <- c(findings, list(f))
    } else {
      findings <- c(findings, f)
    }
  }

  report <- list(
    ok       = length(findings) == 0,
    findings = findings,
    n_rules  = length(applicable),
    format   = fmt
  )
  class(report) <- c("uomthesis_check_report", "list")

  render_check_report(report, format = format)

  severities <- vapply(findings, `[[`, character(1), "severity")
  if (fail_on == "warning" && any(severities %in% c("warning", "error"))) {
    cli::cli_abort("uomthesis::check_thesis() found warnings or errors.")
  }
  if (fail_on == "error" && any(severities == "error")) {
    cli::cli_abort("uomthesis::check_thesis() found errors.")
  }
  invisible(report)
}

#' @importFrom rlang `%||%`
NULL
