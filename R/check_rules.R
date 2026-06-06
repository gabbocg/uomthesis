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

# Find the source of a preliminary section. From v0.1 these live as chapter
# files (chapters/00-<name>.qmd); older projects had them as Pandoc partials
# (_extensions/uomthesis-<fmt>/partials/<name>.tex). Prefer the chapter form
# if both are present.
#
# `name` is the bare role name: "declaration", "copyright", "publications",
# "acknowledgements", "abstract".
find_prelim_source <- function(ctx, name) {
  chapter <- file.path(ctx$project_path, "chapters",
                       paste0("00-", name, ".qmd"))
  if (file.exists(chapter)) return(chapter)
  partial <- find_partial(ctx, paste0(name, ".tex"))
  partial
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
    # Also accept the unrendered scaffold form with Pandoc template variables
    pandoc_reference <- glue::glue(
      ctx$policy$title_page_statement,
      degree  = "$uomthesis.degree$",
      faculty = "$uomthesis.faculty$"
    )
    if (whitespace_contains(body, pandoc_reference)) return(NULL)
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
    path <- find_prelim_source(ctx, "declaration")
    if (is.null(path)) return(NULL)
    variant   <- ctx$metadata$declaration$variant %||% "either"
    reference <- if (variant == "or") ctx$policy$declaration_or
                 else                  ctx$policy$declaration_either
    # The policy text is stored verbatim and ends with `;` (the EITHER variant)
    # because the policy PDF uses `;` to separate EITHER from OR. Real
    # declarations terminate the sentence with `.` or nothing. Strip trailing
    # punctuation from the reference so either form passes.
    reference <- sub("[.;,]\\s*$", "", reference)
    body <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
    if (whitespace_contains(body, reference)) return(NULL)
    list(
      rule_id    = "declaration-text",
      severity   = "error",
      message    = cli::format_inline("Declaration source does not contain the policy {.val {variant}} text."),
      location   = list(file = sub(ctx$project_path, "", path, fixed = TRUE)),
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
    path <- find_prelim_source(ctx, "copyright")
    if (is.null(path)) return(NULL)
    body <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
    out <- list()
    for (i in seq_along(ctx$policy$copyright_bullets)) {
      bullet <- ctx$policy$copyright_bullets[[i]]
      if (whitespace_contains(body, bullet)) next
      out <- c(out, list(list(
        rule_id    = "copyright-text",
        severity   = "error",
        message    = cli::format_inline("Copyright source is missing or has altered bullet {i}."),
        location   = list(file = sub(ctx$project_path, "", path, fixed = TRUE)),
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
    path <- find_prelim_source(ctx, "copyright")
    if (is.null(path)) return(NULL)
    cand <- ctx$metadata$candidate
    if (is.null(cand) || is.null(cand$forename) || is.null(cand$surname)) return(NULL)
    body <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = " ")
    # Accept literal candidate name, Pandoc template variables (legacy scaffold),
    # or Quarto {{< meta >}} shortcodes (current chapter-based scaffold).
    uses_pandoc_vars <- grepl("$uomthesis.candidate.forename$", body, fixed = TRUE) &&
                        grepl("$uomthesis.candidate.surname$",  body, fixed = TRUE)
    uses_meta_shortcode <- grepl("uomthesis.candidate.forename", body, fixed = TRUE) &&
                           grepl("uomthesis.candidate.surname",  body, fixed = TRUE)
    if (uses_pandoc_vars || uses_meta_shortcode) return(NULL)
    has_forename <- grepl(cand$forename, body, fixed = TRUE)
    has_surname  <- grepl(cand$surname,  body, fixed = TRUE)
    if (has_forename && has_surname) return(NULL)
    # If neither the candidate's name nor any obvious placeholder is present,
    # the copyright page simply doesn't carry a signature (this is the pattern
    # used by many real AMBS theses). Treat as a pass; the candidate's identity
    # is established by the title page.
    has_placeholder <- grepl("\\[Author Name\\]|\\[Your Name\\]|Lorem ipsum", body)
    if (!has_forename && !has_surname && !has_placeholder) return(NULL)
    list(
      rule_id    = "copyright-author-match",
      severity   = "error",
      message    = cli::format_inline(
        "Copyright source does not appear to reference the candidate ({cand$forename} {cand$surname})."
      ),
      location   = list(file = sub(ctx$project_path, "", path, fixed = TRUE)),
      policy_ref = "\u00a78.1.g",
      hint       = paste0("The author named in the copyright statement should match index.qmd: ",
                          cand$forename, " ", cand$surname, ".")
    )
  },
  rationale  = "The copyright statement refers to 'the author of this thesis'; the author name in the partial should match the candidate metadata so a mismatch (e.g., from copy-pasting a previous candidate's project) is caught early."
)

#' Rule: prelim chapters must appear before body chapters before appendices
#' @return A rule spec list.
#' @keywords internal
rule_prelim_order <- function() list(
  id         = "prelim-order",
  policy_ref = "\u00a78.1",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    chapters <- names(ctx$qmd_files)
    if (length(chapters) < 2) return(NULL)
    roles <- vapply(ctx$qmd_files, function(f) f$role, character(1))
    # Strip index.qmd and bibliography entries from the order check
    keep <- !grepl("(^|/)index\\.qmd$", chapters) & roles %in% c("prelim", "body", "appendix")
    chapters <- chapters[keep]
    roles    <- roles[keep]
    if (length(chapters) < 2) return(NULL)
    # Verify ordering: prelim < body < appendix
    role_rank <- match(roles, c("prelim", "body", "appendix"))
    if (any(diff(role_rank) < 0)) {
      bad_idx <- which(diff(role_rank) < 0)[1] + 1L
      return(list(
        rule_id    = "prelim-order",
        severity   = "error",
        message    = cli::format_inline(
          "Chapter ordering violates \u00a78.1: {.path {chapters[bad_idx]}} ({roles[bad_idx]}) appears after a later-role chapter."
        ),
        location   = list(file = "_quarto.yml"),
        policy_ref = "\u00a78.1",
        hint       = "Reorder _quarto.yml book.chapters so all 00-prelim files come before 01-body files, and appendices come last (use 'appendices' for appendix files)."
      ))
    }
    NULL
  },
  rationale  = "Policy \u00a78.1 mandates a specific order of preliminary pages, then main body, then appendices."
)

#' Rule: abstract source must be short enough to fit on one rendered page
#' @return A rule spec list.
#' @keywords internal
rule_abstract_one_page <- function() list(
  id         = "abstract-one-page",
  policy_ref = "\u00a78.1.e",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "warning",
  check      = function(ctx) {
    chapters <- names(ctx$qmd_files)
    abstract_files <- chapters[grepl("00-abstract", chapters, ignore.case = TRUE)]
    if (length(abstract_files) == 0) return(NULL)
    f <- abstract_files[[1]]
    abs_path <- file.path(ctx$project_path, f)
    if (!file.exists(abs_path)) return(NULL)
    wc <- word_count_text(readLines(abs_path, warn = FALSE, encoding = "UTF-8"))
    if (wc <= 350) return(NULL)
    list(
      rule_id    = "abstract-one-page",
      severity   = "warning",
      message    = cli::format_inline(
        "abstract source is {.val {wc}} words; the rendered page may exceed one page (policy \u00a78.1.e)."
      ),
      location   = list(file = f),
      policy_ref = "\u00a78.1.e",
      hint       = "Tighten the abstract to under ~350 words for A4 / 12pt / 1.5 spacing."
    )
  },
  rationale  = "Policy \u00a78.1.e mandates that the abstract not exceed one page. The source-phase check is a heuristic; the PDF-phase rule (v0.2) confirms the rendered page count."
)

#' Rule: csl setting must be a bundled style or an existing file path
#' @return A rule spec list.
#' @keywords internal
rule_csl_bundled_or_path_exists <- function() list(
  id         = "csl-bundled-or-path-exists",
  policy_ref = "\u00a77.2",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    csl <- ctx$quarto_yaml$csl %||% ctx$front_matter$csl
    if (is.null(csl)) return(NULL)
    # csl may be a file path or a bundled style name (without .csl extension)
    bundled <- tryCatch(list_csl()$name, error = function(e) character(0))
    if (csl %in% bundled) return(NULL)
    # Try as relative path from project root
    abs <- file.path(ctx$project_path, csl)
    if (file.exists(abs)) return(NULL)
    # Try as absolute path
    if (file.exists(csl)) return(NULL)
    list(
      rule_id    = "csl-bundled-or-path-exists",
      severity   = "error",
      message    = cli::format_inline("csl {.val {csl}} is not a bundled style and the file does not exist."),
      location   = list(file = "_quarto.yml"),
      policy_ref = "\u00a77.2",
      hint       = paste0("Use one of the bundled styles (", paste(bundled, collapse = ", "),
                          ") or check the path.")
    )
  },
  rationale  = "Policy \u00a77.2 lets the candidate pick a citation style but it must be consistently applied; an unresolvable csl: setting means citations will silently fall back to Pandoc default."
)

#' Rule: every bibliography file listed must exist on disk
#' @return A rule spec list.
#' @keywords internal
rule_bibliography_exists <- function() list(
  id         = "bibliography-exists",
  policy_ref = "\u00a77.2",
  phase      = "source",
  formats    = c("standard", "journal"),
  severity   = "error",
  check      = function(ctx) {
    bib <- ctx$quarto_yaml$bibliography %||% ctx$front_matter$bibliography
    if (is.null(bib)) return(NULL)
    bib <- as.character(bib)
    out <- list()
    for (b in bib) {
      abs <- file.path(ctx$project_path, b)
      if (file.exists(abs) || file.exists(b)) next
      out <- c(out, list(list(
        rule_id    = "bibliography-exists",
        severity   = "error",
        message    = cli::format_inline("bibliography file {.path {b}} does not exist."),
        location   = list(file = "_quarto.yml"),
        policy_ref = "\u00a77.2",
        hint       = paste0("Create the file or remove it from bibliography:")
      )))
    }
    if (length(out) == 0) return(NULL)
    if (length(out) == 1) return(out[[1]])
    out
  },
  rationale  = "Bibliography files must exist on disk; a missing file means citations silently render as empty."
)

#' Rule: journal-format thesis must include a rationale for the format choice
#'
#' Policy section 13.10 mandates that journal-format theses include a
#' rationale section. From v0.1 the rationale lives as a section in the
#' introduction chapter (typically chapters/01-introduction.qmd) rather
#' than as a separate partial. The rule checks both locations.
#'
#' @return A rule spec list.
#' @keywords internal
rule_journal_rationale_present <- function() list(
  id         = "journal-rationale-present",
  policy_ref = "\u00a713.10",
  phase      = "source",
  formats    = "journal",
  severity   = "error",
  check      = function(ctx) {
    # New location: a "rationale" mention in the introduction chapter.
    intro_candidates <- c(
      file.path(ctx$project_path, "chapters", "01-introduction.qmd"),
      file.path(ctx$project_path, "chapters", "01-introduction.Rmd")
    )
    intro_path <- intro_candidates[file.exists(intro_candidates)][1]
    if (!is.na(intro_path)) {
      lines <- readLines(intro_path, warn = FALSE, encoding = "UTF-8")
      body  <- paste(lines, collapse = " ")
      has_rationale_section <- grepl("(?i)rationale|journal format", body, perl = TRUE)
      if (has_rationale_section && nchar(trimws(body)) >= 200) return(NULL)
    }
    # Legacy location: a rationale.tex partial in the extension.
    ext_dir <- file.path(ctx$project_path, "_extensions", "uomthesis-journal")
    if (!dir.exists(ext_dir)) return(NULL)
    partial <- file.path(ext_dir, "partials", "rationale.tex")
    if (!file.exists(partial)) {
      return(list(
        rule_id    = "journal-rationale-present",
        severity   = "error",
        message    = "Journal format thesis has no rationale section in the introduction and no rationale partial.",
        location   = list(file = "chapters/01-introduction.qmd"),
        policy_ref = "\u00a713.10",
        hint       = "Add a 'Rationale for journal format' section to chapters/01-introduction.qmd."
      ))
    }
    lines <- readLines(partial, warn = FALSE, encoding = "UTF-8")
    body  <- paste(lines, collapse = " ")
    body  <- gsub("[%].*", "", body)  # strip TeX comments
    if (nchar(trimws(body)) < 50) {
      return(list(
        rule_id    = "journal-rationale-present",
        severity   = "error",
        message    = "Rationale partial exists but is empty or near-empty.",
        location   = list(file = "_extensions/uomthesis-journal/partials/rationale.tex"),
        policy_ref = "\u00a713.10",
        hint       = paste0("Policy \u00a713.10 requires a rationale for journal-format submission ",
                            "and an account of how the thesis has been constructed.")
      ))
    }
    NULL
  },
  rationale  = paste0("Policy \u00a713.10 mandates that journal-format theses include a rationale ",
                      "section explaining the format choice and the thesis structure.")
)

#' Rule: journal body chapters must carry a contribution statement
#' @return A rule spec list.
#' @keywords internal
rule_journal_contribution_stmts <- function() list(
  id         = "journal-contribution-stmts",
  policy_ref = "\u00a713.3",
  phase      = "source",
  formats    = "journal",
  severity   = "warning",
  check      = function(ctx) {
    body_files <- vapply(ctx$qmd_files,
                         function(f) f$role == "body" &&
                                     !grepl("(^|/)index\\.qmd$", f$path) &&
                                     grepl("paper", basename(f$path), ignore.case = TRUE),
                         logical(1))
    body_files <- names(ctx$qmd_files)[body_files]
    if (length(body_files) == 0) return(NULL)
    missing <- character(0)
    for (f in body_files) {
      abs <- file.path(ctx$project_path, f)
      if (!file.exists(abs)) next
      lines <- readLines(abs, warn = FALSE, encoding = "UTF-8")
      # Match `contribution:` / `contribution=` (chunk option / attribute) or
      # `{.contribution}` (Quarto Div class) — both are accepted styles.
      has <- any(grepl(
        "(\\{\\.contribution\\b|(^|#\\|\\s*|\\{|\\s)contribution\\s*[:=])",
        lines
      ))
      if (!has) missing <- c(missing, f)
    }
    if (length(missing) == 0) return(NULL)
    list(
      rule_id    = "journal-contribution-stmts",
      severity   = "warning",
      message    = cli::format_inline(
        "{length(missing)} body chapter(s) lack a contribution statement: {paste(missing, collapse = ', ')}."
      ),
      location   = list(file = missing[[1]]),
      policy_ref = "\u00a713.3",
      hint       = paste0("Add a contribution declaration (chunk option, heading attribute, or YAML key) ",
                          "to each paper-chapter that has co-authors.")
    )
  },
  rationale  = paste0("Policy \u00a713.3 requires explicit clarity about the student's contribution to each ",
                      "paper-chapter in a journal-format thesis; omitting this is a common reason for examiner concern.")
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
    rule_copyright_author_match(),
    rule_prelim_order(),
    rule_abstract_one_page(),
    rule_csl_bundled_or_path_exists(),
    rule_bibliography_exists(),
    rule_journal_rationale_present(),
    rule_journal_contribution_stmts()
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
