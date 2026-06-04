test_that("render_console produces a sensible cli-formatted output", {
  report <- list(
    ok = FALSE,
    findings = list(
      list(rule_id = "degree-faculty-school", severity = "error",
           message = "Degree X is not in the allowed set.",
           location = list(file = "index.qmd"),
           policy_ref = "section 8.1.b",
           hint = "Use one of: PhD, MPhil...")
    ),
    n_rules = 19,
    format = "standard"
  )
  class(report) <- c("uomthesis_check_report", "list")
  expect_snapshot(render_check_report(report, format = "console"))
})

test_that("render_markdown writes check-report.md", {
  withr::local_dir(withr::local_tempdir())
  report <- list(
    ok = FALSE,
    findings = list(
      list(rule_id = "year-not-month", severity = "error",
           message = "year must be an integer.",
           location = list(file = "index.qmd"),
           policy_ref = "section 8.1.b",
           hint = "year: 2027")
    ),
    n_rules = 19,
    format = "standard"
  )
  class(report) <- c("uomthesis_check_report", "list")
  render_check_report(report, format = "markdown")
  expect_true(file.exists("check-report.md"))
  content <- readLines("check-report.md")
  expect_true(any(grepl("year-not-month", content)))
})

test_that("render_json produces parseable JSON", {
  report <- list(
    ok = TRUE, findings = list(),
    n_rules = 19, format = "standard"
  )
  class(report) <- c("uomthesis_check_report", "list")
  out <- render_check_report(report, format = "json")
  parsed <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  expect_named(parsed, c("ok", "findings", "n_rules", "format"))
  expect_true(parsed$ok)
})
