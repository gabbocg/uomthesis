# Check a uomthesis project against the Presentation of Theses Policy

Runs the source-phase rule registry against a scaffolded uomthesis
project, aggregates findings, and renders a report.

## Usage

``` r
check_thesis(
  project = ".",
  rendered_pdf = NULL,
  rules = NULL,
  format = c("console", "markdown", "json"),
  fail_on = c("none", "warning", "error")
)
```

## Arguments

- project:

  Path to project root.

- rendered_pdf:

  Optional path to a rendered PDF. **Not yet implemented** in v0.1 –
  supplying a value emits a warning and only source-phase rules run.
  Will be honored in v0.2.

- rules:

  Optional character vector of rule IDs to restrict the run.

- format:

  Output format: console, markdown, or json.

- fail_on:

  Threshold for raising an error after reporting: "none"
  (informational), "warning", or "error".

## Value

Invisibly, an object of class `uomthesis_check_report`.
