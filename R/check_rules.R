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
  if (!is.null(rendered_pdf)) {
    cli::cli_warn(c(
      "PDF-phase rules are not yet implemented (planned for v0.2).",
      i = "{.arg rendered_pdf} will be ignored; only source-phase rules will run."
    ))
  }
  idx          <- file.path(project_path, "index.qmd")
  front_matter <- parse_qmd_yaml(idx)
  meta         <- front_matter$uomthesis %||% list()
  qy           <- yaml::read_yaml(file.path(project_path, "_quarto.yml"))
  chapters     <- as.character(qy$book$chapters %||% c())
  qmd_files <- stats::setNames(
    lapply(chapters, function(f) {
      list(path = f, role = classify_qmd_file(f))
    }),
    chapters
  )
  list(
    project_path = project_path,
    metadata     = meta,
    front_matter = front_matter,
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
# Partial-file helpers
# ---------------------------------------------------------------------------

# Find a partial template file in the user's project. Returns the absolute
# path if present, NULL if not.
find_partial <- function(ctx, partial_name) {
  fmt <- ctx$metadata$thesis_format %||% "standard"
  rel <- file.path("_extensions", paste0("uomthesis-", fmt),
                   "partials", partial_name)
  abs <- file.path(ctx$project_path, rel)
  if (file.exists(abs)) abs else NULL
}

# Returns TRUE if `body` contains `pattern` after collapsing whitespace
# in both to single spaces (so newlines and indentation don't defeat the match).
whitespace_contains <- function(body, pattern) {
  norm <- function(s) gsub("\\s+", " ", trimws(s))
  grepl(norm(pattern), norm(body), fixed = TRUE)
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
      out  <- list()

      if (!is.null(meta$degree) && !meta$degree %in% p$allowed_degrees) {
        out <- c(out, list(list(
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
        )))
      }
      if (!is.null(meta$faculty) && !meta$faculty %in% p$allowed_faculties) {
        out <- c(out, list(list(
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
        )))
      }
      if (!is.null(meta$school) && !meta$school %in% p$allowed_schools) {
        out <- c(out, list(list(
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
        )))
      }
      if (length(out) == 0) return(NULL)
      if (length(out) == 1) return(out[[1]])
      out  # list of finding lists
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

#' Rule: mainfont must be in the allowed set
#' @return A rule spec list.
#' @keywords internal
rule_font_allowed <- function() list(
  id         = "font-allowed",
  policy_ref = "\u00a77.1",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    mf <- ctx$front_matter$mainfont
    if (is.null(mf) || mf %in% ctx$policy$allowed_fonts) return(NULL)
    list(
      rule_id    = "font-allowed",
      severity   = "error",
      message    = cli::format_inline("mainfont {.val {mf}} is not in the allowed list."),
      location   = list(file = "index.qmd"),
      policy_ref = "\u00a77.1",
      hint       = paste0("Use one of: ", paste(ctx$policy$allowed_fonts, collapse = ", "), ".")
    )
  },
  rationale  = "Policy \u00a77.1 lists the permitted fonts; any other choice will be rejected by the Doctoral Academy."
)

#' Rule: mainfont must be pdflatex-safe when pdf-engine is pdflatex
#' @return A rule spec list.
#' @keywords internal
rule_font_engine_compat <- function() list(
  id         = "font-engine-compat",
  policy_ref = "\u00a77.1",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    engine <- ctx$front_matter[["pdf-engine"]]
    mf     <- ctx$front_matter$mainfont
    if (is.null(engine) || engine != "pdflatex") return(NULL)
    if (is.null(mf) || mf %in% ctx$policy$pdflatex_safe_fonts) return(NULL)
    list(
      rule_id    = "font-engine-compat",
      severity   = "error",
      message    = cli::format_inline("mainfont {.val {mf}} is not safe under pdflatex."),
      location   = list(file = "index.qmd"),
      policy_ref = "\u00a77.1",
      hint       = paste0("Switch to lualatex/xelatex, or pick from: ",
                          paste(ctx$policy$pdflatex_safe_fonts, collapse = ", "), ".")
    )
  },
  rationale  = "Under pdflatex only a limited subset of policy \u00a77.1 fonts render correctly without extra packaging."
)

#' Rule: linestretch must be 1.5 or 2.0 when set
#' @return A rule spec list.
#' @keywords internal
rule_linespacing_allowed <- function() list(
  id         = "linespacing-allowed",
  policy_ref = "\u00a77.1",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    ls <- ctx$front_matter$linestretch
    if (is.null(ls)) return(NULL)
    if (ls %in% ctx$policy$allowed_linestretch) return(NULL)
    list(
      rule_id    = "linespacing-allowed",
      severity   = "error",
      message    = cli::format_inline("linestretch {.val {ls}} must be 1.5 or 2.0."),
      location   = list(file = "index.qmd"),
      policy_ref = "\u00a77.1",
      hint       = "Set linestretch: 1.5 or linestretch: 2.0."
    )
  },
  rationale  = "Policy \u00a77.1 mandates double or 1.5 line spacing for main text."
)

#' Rule: ai_disclosure.include=true requires a non-empty tools list
#' @return A rule spec list.
#' @keywords internal
rule_ai_disclosure_shape <- function() list(
  id         = "ai-disclosure-shape",
  policy_ref = "\u00a79.1.d",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "warning",
  check      = function(ctx) {
    ai <- ctx$metadata$ai_disclosure
    if (is.null(ai) || !isTRUE(ai$include)) return(NULL)
    tools <- ai$tools
    if (is.null(tools) || length(tools) == 0) {
      return(list(
        rule_id    = "ai-disclosure-shape",
        severity   = "warning",
        message    = "ai_disclosure.include is true but tools list is empty.",
        location   = list(file = "index.qmd"),
        policy_ref = "\u00a79.1.d",
        hint       = "Add the tool(s) you used, e.g., tools: [ChatGPT-5]."
      ))
    }
    NULL
  },
  rationale  = "Policy \u00a79.1.d expects authors who declare AI use to name the specific tool(s) used."
)

#' Rule: lang must be English when set
#' @return A rule spec list.
#' @keywords internal
rule_english_language <- function() list(
  id         = "english-language",
  policy_ref = "\u00a76.1",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "warning",
  check      = function(ctx) {
    lang <- ctx$front_matter$lang
    if (is.null(lang)) return(NULL)
    if (lang %in% c("en", "en-GB", "en-US")) return(NULL)
    list(
      rule_id    = "english-language",
      severity   = "warning",
      message    = cli::format_inline("lang {.val {lang}} is not English."),
      location   = list(file = "index.qmd"),
      policy_ref = "\u00a76.1",
      hint       = "Policy \u00a76.1 requires UK English unless prior approval. Use lang: en-GB."
    )
  },
  rationale  = "Policy \u00a76.1 requires the thesis to be written in UK English (US English allowed where discipline standards dictate); other languages require advance approval."
)

#' Rule: title-page.tex must contain the policy-mandated statement
#' @return A rule spec list.
#' @keywords internal
rule_title_page_statement <- function() list(
  id         = "title-page-statement",
  policy_ref = "\u00a78.1.b",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    path <- find_partial(ctx, "title-page.tex")
    if (is.null(path)) return(NULL)
    reference <- glue::glue(
      ctx$policy$title_page_statement,
      degree  = ctx$metadata$degree  %||% "<DEGREE>",
      faculty = ctx$metadata$faculty %||% "<FACULTY>"
    )
    body <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
    if (whitespace_contains(body, reference)) return(NULL)
    list(
      rule_id    = "title-page-statement",
      severity   = "error",
      message    = "title-page.tex does not contain the policy-mandated statement.",
      location   = list(file = "_extensions/uomthesis-*/partials/title-page.tex"),
      policy_ref = "\u00a78.1.b",
      hint       = paste0("Restore the policy statement: \"", reference, "\".")
    )
  },
  rationale  = "Policy \u00a78.1.b mandates the exact statement \"A thesis submitted to The University of Manchester for the degree of X in the Faculty of Y.\""
)

#' Rule: declaration.tex must contain the policy declaration text
#' @return A rule spec list.
#' @keywords internal
rule_declaration_text <- function() list(
  id         = "declaration-text",
  policy_ref = "\u00a78.1.f",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    path <- find_partial(ctx, "declaration.tex")
    if (is.null(path)) return(NULL)
    variant   <- ctx$metadata$declaration$variant %||% "either"
    reference <- if (variant == "or") ctx$policy$declaration_or
                 else                  ctx$policy$declaration_either
    body <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
    if (whitespace_contains(body, reference)) return(NULL)
    list(
      rule_id    = "declaration-text",
      severity   = "error",
      message    = cli::format_inline("declaration.tex does not contain the policy {.val {variant}} text."),
      location   = list(file = "_extensions/uomthesis-*/partials/declaration.tex"),
      policy_ref = "\u00a78.1.f",
      hint       = "Restore the policy text verbatim, or change uomthesis.declaration.variant if joint authorship applies."
    )
  },
  rationale  = "Policy \u00a78.1.f mandates one of two exact declaration texts (EITHER 'no portion' / OR 'what portion'); altering the text may cause the Doctoral Academy to reject the thesis."
)

#' Rule: copyright.tex must contain all four policy copyright bullets
#' @return A rule spec list.
#' @keywords internal
rule_copyright_text <- function() list(
  id         = "copyright-text",
  policy_ref = "\u00a78.1.g",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    path <- find_partial(ctx, "copyright.tex")
    if (is.null(path)) return(NULL)
    body <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
    out <- list()
    for (i in seq_along(ctx$policy$copyright_bullets)) {
      bullet <- ctx$policy$copyright_bullets[[i]]
      if (whitespace_contains(body, bullet)) next
      out <- c(out, list(list(
        rule_id    = "copyright-text",
        severity   = "error",
        message    = cli::format_inline("copyright.tex is missing or has altered bullet {i}."),
        location   = list(file = "_extensions/uomthesis-*/partials/copyright.tex"),
        policy_ref = "\u00a78.1.g",
        hint       = paste0("Restore bullet ", i, " verbatim: \"", substr(bullet, 1, 80), "...\".")
      )))
    }
    if (length(out) == 0) return(NULL)
    if (length(out) == 1) return(out[[1]])
    out
  },
  rationale  = "Policy \u00a78.1.g mandates four exact copyright bullets; missing or altered bullets may cause the Doctoral Academy to reject the thesis."
)

#' Rule: copyright.tex must reference the candidate's name
#' @return A rule spec list.
#' @keywords internal
rule_copyright_author_match <- function() list(
  id         = "copyright-author-match",
  policy_ref = "\u00a78.1.g",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    path <- find_partial(ctx, "copyright.tex")
    if (is.null(path)) return(NULL)
    cand <- ctx$metadata$candidate
    if (is.null(cand) || is.null(cand$forename) || is.null(cand$surname)) return(NULL)
    body <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
    has_forename <- grepl(cand$forename, body, fixed = TRUE)
    has_surname  <- grepl(cand$surname,  body, fixed = TRUE)
    if (has_forename && has_surname) return(NULL)
    list(
      rule_id    = "copyright-author-match",
      severity   = "error",
      message    = cli::format_inline(
        "copyright.tex does not appear to reference the candidate ({cand$forename} {cand$surname})."
      ),
      location   = list(file = "_extensions/uomthesis-*/partials/copyright.tex"),
      policy_ref = "\u00a78.1.g",
      hint       = paste0("The author named in the copyright statement should match index.qmd: ",
                          cand$forename, " ", cand$surname, ".")
    )
  },
  rationale  = "The copyright statement refers to 'the author of this thesis'; the author name in the partial should match the candidate metadata so a mismatch (e.g., from copy-pasting a previous candidate's project) is caught early."
)

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
    rule_thesis_format(),
    rule_font_allowed(),
    rule_font_engine_compat(),
    rule_linespacing_allowed(),
    rule_ai_disclosure_shape(),
    rule_english_language(),
    rule_title_page_statement(),
    rule_declaration_text(),
    rule_copyright_text(),
    rule_copyright_author_match()
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
