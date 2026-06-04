#' @importFrom rlang `%||%`
NULL

# ---------------------------------------------------------------------------
# Context helpers
# ---------------------------------------------------------------------------

#' Build a validation context object for a given project
#'
#' @param project_path Path to the project root (must contain _quarto.yml and
#'   index.qmd).
#' @param rendered_pdf Optional path to a rendered PDF file.
#' @return A named list used as the context argument to each rule's check
#'   function.
#' @keywords internal
build_ctx <- function(project_path, rendered_pdf = NULL) {
  meta     <- read_uomthesis_metadata(project_path)
  qy       <- yaml::read_yaml(file.path(project_path, "_quarto.yml"))
  chapters <- as.character(qy$book$chapters %||% c())
  qmd_files <- stats::setNames(
    lapply(chapters, function(f) {
      list(path = f, role = classify_qmd_file(f))
    }),
    chapters
  )
  list(
    project_path = project_path,
    metadata     = meta,
    quarto_yaml  = qy,
    qmd_files    = qmd_files,
    qmd_text     = new.env(parent = emptyenv()),
    pdf_pages    = NULL,
    pdf_toc      = NULL,
    policy       = policy_constants()
  )
}

#' Lazily read a QMD file into the context cache
#'
#' @param ctx A context object produced by [build_ctx()].
#' @param file Path to the file, relative to the project root.
#' @return Character vector of lines.
#' @keywords internal
ctx_read <- function(ctx, file) {
  abs <- file.path(ctx$project_path, file)
  if (is.null(ctx$qmd_text[[file]])) {
    ctx$qmd_text[[file]] <- readLines(abs, warn = FALSE, encoding = "UTF-8")
  }
  ctx$qmd_text[[file]]
}

# ---------------------------------------------------------------------------
# Individual rule constructors
# ---------------------------------------------------------------------------

#' Rule: all required metadata fields must be present and non-empty
#' @return A rule spec list.
#' @keywords internal
rule_metadata_complete <- function() {
  list(
    id         = "metadata-complete",
    policy_ref = "\u00a78.1.b",
    phase      = "source",
    formats    = c("standard", "journal"),
    severity   = "error",
    rationale  = "The title page and thesis records require a complete set of metadata fields (candidate name, degree, faculty, school, year, format). Missing or empty values prevent automated title-page generation and compliance checking.",
    check      = function(ctx) {
      meta     <- ctx$metadata
      required <- c("candidate.surname", "degree", "faculty", "school",
                    "year", "thesis_format")
      for (key in required) {
        parts <- strsplit(key, "\\.")[[1]]
        val   <- Reduce(
          function(acc, k) if (is.null(acc)) NULL else acc[[k]],
          parts, init = meta
        )
        if (is.null(val) || identical(val, "")) {
          return(list(
            rule_id    = "metadata-complete",
            severity   = "error",
            message    = cli::format_inline(
              "Required field {.field {key}} is missing or empty."
            ),
            location   = list(file = "index.qmd"),
            policy_ref = "\u00a78.1.b",
            hint       = "Add the field under the uomthesis: block in index.qmd."
          ))
        }
      }
      NULL
    }
  )
}

#' Rule: degree, faculty, and school must each belong to the allowed set
#' @return A rule spec list.
#' @keywords internal
rule_degree_faculty_school <- function() {
  list(
    id         = "degree-faculty-school",
    policy_ref = "\u00a78.1.b",
    phase      = "source",
    formats    = c("standard", "journal"),
    severity   = "error",
    rationale  = "The University only recognises specific degree titles, faculty names, and school names on the title page. Unrecognised values fail the examinations office submission check.",
    check      = function(ctx) {
      meta <- ctx$metadata
      p    <- ctx$policy

      if (!is.null(meta$degree) && !meta$degree %in% p$allowed_degrees) {
        return(list(
          rule_id    = "degree-faculty-school",
          severity   = "error",
          message    = cli::format_inline(
            "Degree {.val {meta$degree}} is not in the allowed set."
          ),
          location   = list(file = "index.qmd"),
          policy_ref = "\u00a78.1.b",
          hint       = paste0(
            "Use one of: ", paste(p$allowed_degrees, collapse = ", "), "."
          )
        ))
      }
      if (!is.null(meta$faculty) && !meta$faculty %in% p$allowed_faculties) {
        return(list(
          rule_id    = "degree-faculty-school",
          severity   = "error",
          message    = cli::format_inline(
            "Faculty {.val {meta$faculty}} is not in the allowed set."
          ),
          location   = list(file = "index.qmd"),
          policy_ref = "\u00a78.1.b",
          hint       = paste0(
            "Use one of: ", paste(p$allowed_faculties, collapse = ", "), "."
          )
        ))
      }
      if (!is.null(meta$school) && !meta$school %in% p$allowed_schools) {
        return(list(
          rule_id    = "degree-faculty-school",
          severity   = "error",
          message    = cli::format_inline(
            "School {.val {meta$school}} is not in the allowed set."
          ),
          location   = list(file = "index.qmd"),
          policy_ref = "\u00a78.1.b",
          hint       = paste0(
            "Use one of: ", paste(p$allowed_schools, collapse = ", "), "."
          )
        ))
      }
      NULL
    }
  )
}

#' Rule: year must be a plausible integer (2000-2100), not a month name
#' @return A rule spec list.
#' @keywords internal
rule_year_not_month <- function() {
  list(
    id         = "year-not-month",
    policy_ref = "\u00a78.1.b",
    phase      = "source",
    formats    = c("standard", "journal"),
    severity   = "error",
    rationale  = "The policy requires only the year of submission, not a month. Providing a month string or an implausible year breaks word-count deadline calculations and is rejected by the examiners office.",
    check      = function(ctx) {
      yr <- ctx$metadata$year
      if (is.null(yr)) return(NULL)
      if (!is.numeric(yr) || yr < 2000 || yr > 2100) {
        return(list(
          rule_id    = "year-not-month",
          severity   = "error",
          message    = "year must be an integer between 2000 and 2100.",
          location   = list(file = "index.qmd"),
          policy_ref = "\u00a78.1.b",
          hint       = "year: 2027 (no month)."
        ))
      }
      NULL
    }
  )
}

#' Rule: thesis_format must be "standard" or "journal"
#' @return A rule spec list.
#' @keywords internal
rule_thesis_format <- function() {
  list(
    id         = "thesis-format",
    policy_ref = "\u00a74.6",
    phase      = "source",
    formats    = c("standard", "journal"),
    severity   = "error",
    rationale  = "Only 'standard' and 'journal' formats are defined in the University Presentation of Theses Policy (section 4.6). Any other value is unrecognised and cannot be validated against format-specific rules.",
    check      = function(ctx) {
      fmt <- ctx$metadata$thesis_format
      if (is.null(fmt)) return(NULL)
      if (!fmt %in% c("standard", "journal")) {
        return(list(
          rule_id    = "thesis-format",
          severity   = "error",
          message    = cli::format_inline(
            "thesis_format {.val {fmt}} must be 'standard' or 'journal'."
          ),
          location   = list(file = "index.qmd"),
          policy_ref = "\u00a74.6",
          hint       = "Set thesis_format: standard or thesis_format: journal."
        ))
      }
      NULL
    }
  )
}

# ---------------------------------------------------------------------------
# Registry
# ---------------------------------------------------------------------------

#' Return all registered validation rules
#'
#' Each element is a named list with fields: `id`, `policy_ref`, `phase`,
#' `formats`, `severity`, `check`, and `rationale`. The `check` field is a
#' function that accepts a context object (see [build_ctx()]) and returns
#' either `NULL` (pass) or a finding list.
#'
#' @return A list of rule spec lists.
#' @keywords internal
rule_registry <- function() {
  list(
    rule_metadata_complete(),
    rule_degree_faculty_school(),
    rule_year_not_month(),
    rule_thesis_format()
  )
}

#' Retrieve a single rule by its ID
#'
#' @param id A character string matching a rule's `id` field.
#' @return The matching rule spec list; errors if not found.
#' @keywords internal
get_rule <- function(id) {
  registry <- rule_registry()
  for (r in registry) {
    if (identical(r$id, id)) return(r)
  }
  cli::cli_abort(
    c("No rule with id {.val {id}} found in the registry.",
      i = "Available ids: {.val {vapply(registry, `[[`, character(1), 'id')}}."),
    class = "uomthesis_unknown_rule"
  )
}
