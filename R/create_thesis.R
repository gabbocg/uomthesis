#' Scaffold a new uomthesis project
#'
#' Creates a directory tree containing a Quarto project (`_quarto.yml`,
#' `index.qmd`, chapter stubs), copies the appropriate Quarto extension
#' (standard or journal) and a chosen CSL file into the project's
#' `_extensions/` directory, and substitutes user-supplied metadata
#' into the scaffolded `index.qmd`.
#'
#' @param path Path to the new project directory.
#' @param format `"standard"` or `"journal"`.
#' @param degree One of the degrees in the policy allowed set.
#' @param faculty Faculty name. Default: `"Humanities"`.
#' @param school School name. Default: `"Alliance Manchester Business School"`.
#' @param division AMBS division code: `"A&F"` | `"IMP"` | `"MSM"` | `"PMO"`, or `NULL`.
#' @param author Named list with components `forename`, `middle_initial`,
#'   `surname`, `native_name` (optional). If `NULL`, placeholders are used.
#' @param title Thesis title. If `NULL`, a placeholder is used.
#' @param year Year of submission (integer). Defaults to current year.
#' @param reference_style One of `list_csl()$name`.
#' @param engine `"lualatex"` | `"xelatex"` | `"pdflatex"`.
#' @param mainfont One of the policy-allowed fonts.
#' @param list_of_publications For journal format: if `TRUE` (default for
#'   journal), a `chapters/00-publications.qmd` page is scaffolded and listed
#'   in `_quarto.yml`. Set to `FALSE` if you have no papers to list yet --
#'   the page is omitted from both the directory and the book chapters. Has
#'   no effect for `format = "standard"`.
#' @param num_papers For journal format: integer 1-10, the number of
#'   constituent paper chapters to scaffold (Introduction + N papers +
#'   Conclusion). Default `3` (the typical AMBS journal-format thesis size
#'   per policy section 13.5). Paper 1 is always the rich example chapter
#'   that demonstrates citations, equations, tables, figures, and per-paper
#'   appendices; Papers 2..N are bare structural templates with letter-
#'   prefixed appendix headings (N.A, N.B). Has no effect for
#'   `format = "standard"`.
#' @param force If `TRUE`, allow `path` to exist as long as it is empty.
#' @param open If `TRUE` and RStudio is available, open the new project.
#' @return Invisible path to the created project.
#' @export
#' @importFrom rlang `%||%`
create_thesis <- function(path,
                          format = c("standard", "journal"),
                          degree = "PhD",
                          faculty = "Humanities",
                          school = "Alliance Manchester Business School",
                          division = NULL,
                          author = NULL,
                          title = NULL,
                          year = NULL,
                          reference_style = c("harvard-manchester", "apa",
                                              "chicago-author-date", "mhra",
                                              "vancouver"),
                          engine = c("lualatex", "xelatex", "pdflatex"),
                          mainfont = "Times New Roman",
                          list_of_publications = NULL,
                          num_papers = 3L,
                          force = FALSE,
                          open = rlang::is_interactive()) {
  format          <- match.arg(format)
  engine          <- match.arg(engine)
  reference_style <- match.arg(reference_style)
  p <- policy_constants()

  # Validate font
  if (!mainfont %in% p$allowed_fonts) {
    cli::cli_abort(
      c("{.val {mainfont}} is not in the allowed font list.",
        i = paste0("Allowed: ", paste(p$allowed_fonts, collapse = ", "), ".")),
      class = "uomthesis_invalid_font"
    )
  }
  if (engine == "pdflatex" && !mainfont %in% p$pdflatex_safe_fonts) {
    cli::cli_abort(
      c("{.val {mainfont}} is not safe under pdflatex.",
        i = paste0("Use lualatex or xelatex, or pick from: ",
                   paste(p$pdflatex_safe_fonts, collapse = ", "), ".")),
      class = "uomthesis_engine_font_mismatch"
    )
  }
  if (!degree %in% p$allowed_degrees) {
    cli::cli_abort(
      "Degree {.val {degree}} not in allowed set.",
      class = "uomthesis_invalid_degree"
    )
  }
  # Validate num_papers
  if (format == "journal") {
    if (!is.numeric(num_papers) || length(num_papers) != 1L ||
        is.na(num_papers) || num_papers < 1 || num_papers > 10 ||
        num_papers != as.integer(num_papers)) {
      cli::cli_abort(
        c("{.arg num_papers} must be an integer between 1 and 10.",
          i = "Got {.val {num_papers}}."),
        class = "uomthesis_invalid_num_papers"
      )
    }
    num_papers <- as.integer(num_papers)
  }

  # Validate path
  path <- normalizePath(path, mustWork = FALSE)
  if (file.exists(path)) {
    if (!force) {
      cli::cli_abort(
        c("{.path {path}} already exists.",
          i = "Pass {.code force = TRUE} to use an empty existing directory."),
        class = "uomthesis_path_exists"
      )
    }
    if (length(list.files(path)) > 0) {
      cli::cli_abort(
        "{.path {path}} is not empty.",
        class = "uomthesis_path_not_empty"
      )
    }
  } else {
    fs::dir_create(path)
  }

  # Copy skeleton
  skel <- system.file(
    if (format == "standard") "skeleton" else "skeleton-journal",
    package = "uomthesis"
  )
  if (!nzchar(skel)) {
    cli::cli_abort("Skeleton not found in installed package. Reinstall {.pkg uomthesis}.")
  }
  for (f in list.files(skel, recursive = TRUE, all.files = TRUE, no.. = TRUE)) {
    src  <- file.path(skel, f)
    dest <- file.path(path, f)
    fs::dir_create(dirname(dest))
    fs::file_copy(src, dest, overwrite = TRUE)
  }
  # The skeleton's empty `figures/` directory is dropped by R CMD build
  # (since `.keep` sentinel files are excluded via .Rbuildignore), so
  # recreate it explicitly here.
  fs::dir_create(file.path(path, "figures"))

  # Copy extension
  ext_src <- system.file(
    file.path("quarto", "_extensions", paste0("uomthesis-", format)),
    package = "uomthesis"
  )
  if (!nzchar(ext_src)) {
    cli::cli_abort("Quarto extension not found in installed package.")
  }
  ext_dest <- file.path(path, "_extensions", paste0("uomthesis-", format))
  fs::dir_create(ext_dest)
  for (f in list.files(ext_src, recursive = TRUE, all.files = TRUE, no.. = TRUE)) {
    src  <- file.path(ext_src, f)
    dest <- file.path(ext_dest, f)
    fs::dir_create(dirname(dest))
    fs::file_copy(src, dest, overwrite = TRUE)
  }

  # Also copy _shared/ alongside (so symlinks resolve)
  shared_src <- system.file("quarto/_extensions/_shared", package = "uomthesis")
  if (nzchar(shared_src)) {
    shared_dest <- file.path(path, "_extensions", "_shared")
    fs::dir_create(shared_dest)
    for (f in list.files(shared_src, recursive = TRUE, all.files = TRUE, no.. = TRUE)) {
      src  <- file.path(shared_src, f)
      dest <- file.path(shared_dest, f)
      fs::dir_create(dirname(dest))
      fs::file_copy(src, dest, overwrite = TRUE)
    }
  }

  # Copy the requested CSL into the extension's csl/ dir
  csl_dir <- file.path(ext_dest, "csl")
  fs::dir_create(csl_dir)
  copy_csl(reference_style, to = csl_dir)

  # Substitute mustache placeholders in index.qmd and _quarto.yml
  substitute_skeleton(
    path,
    title           = title %||% "Your thesis title",
    author          = author,
    degree          = degree,
    faculty         = faculty,
    school          = school,
    division        = division %||% "",
    year            = year %||% as.integer(format(Sys.Date(), "%Y")),
    reference_style = reference_style,
    engine          = engine,
    mainfont        = mainfont,
    thesis_format   = format
  )

  # Optional List of Publications page (journal format only). The default is
  # to include it; the user can set list_of_publications = FALSE if they
  # have no published or in-press papers yet.
  if (is.null(list_of_publications)) {
    list_of_publications <- (format == "journal")
  }
  if (format == "journal" && !isTRUE(list_of_publications)) {
    pubs_file <- file.path(path, "chapters", "00-publications.qmd")
    if (file.exists(pubs_file)) fs::file_delete(pubs_file)
    qy_path <- file.path(path, "_quarto.yml")
    if (file.exists(qy_path)) {
      qy_lines <- readLines(qy_path, warn = FALSE)
      qy_lines <- qy_lines[!grepl("00-publications.qmd", qy_lines)]
      writeLines(qy_lines, qy_path)
    }
  }

  # Adjust paper count (journal format only). The skeleton ships with 3
  # papers; if the user asked for fewer or more, we add/remove chapters
  # and rewrite _quarto.yml's chapter list accordingly.
  if (format == "journal" && num_papers != 3L) {
    adjust_journal_paper_count(path, num_papers)
  }

  if (isTRUE(open) &&
      requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    rstudioapi::openProject(path)
  } else {
    cli::cli_alert_success("Created uomthesis project at {.path {path}}.")
    cli::cli_alert_info(
      "Next: open {.file index.qmd}, then {.run quarto::quarto_render()}."
    )
  }
  invisible(path)
}

# Adjust the journal skeleton to have `n` paper chapters instead of the
# default 3. Adds or removes paper-N.qmd files and rewrites the chapter
# list in `_quarto.yml`. Paper 1 (the rich demo chapter) is preserved
# unless n == 0 (which the caller never asks for; we validate n >= 1).
#
# The skeleton ships with:
#   chapters/02-paper-one.qmd       (rich)
#   chapters/03-paper-two.qmd       (bare)
#   chapters/04-paper-three.qmd     (bare)
#   chapters/05-conclusion.qmd
#
# For n papers we produce:
#   chapters/02-paper-one.qmd       (rich, unchanged)
#   chapters/03-paper-two.qmd       (bare)            [if n >= 2]
#   chapters/04-paper-three.qmd     (bare)            [if n >= 3]
#   chapters/05-paper-four.qmd      (bare)            [if n >= 4]
#   ...
#   chapters/0{n+1}-paper-{nth}.qmd (bare)            [if n >= 4]
#   chapters/0{n+2}-conclusion.qmd
#
adjust_journal_paper_count <- function(path, n) {
  # File-name ordinals: 02-paper-one.qmd, 03-paper-two.qmd, ...
  ordinals <- c("one", "two", "three", "four", "five",
                "six", "seven", "eight", "nine", "ten")
  # Title ordinals: "Title of the first paper", "...second paper", ...
  ordinal_adjectives <- c("first", "second", "third", "fourth", "fifth",
                          "sixth", "seventh", "eighth", "ninth", "tenth")
  chap_dir <- file.path(path, "chapters")

  # Wipe existing paper-*.qmd files (Paper 1 will be regenerated below
  # only when adding papers; we don't touch it when shrinking, so the
  # rich demo is preserved). Conclusion is renamed.
  existing_papers <- list.files(chap_dir, pattern = "^0\\d-paper-",
                                full.names = TRUE)
  paper_one_path <- file.path(chap_dir, "02-paper-one.qmd")
  paper_one_body <- if (file.exists(paper_one_path)) {
    readLines(paper_one_path, warn = FALSE, encoding = "UTF-8")
  } else NULL

  # Remove all paper-*.qmd files
  for (f in existing_papers) fs::file_delete(f)

  # Recreate Paper 1 (rich body, unchanged)
  if (!is.null(paper_one_body)) {
    writeLines(paper_one_body, paper_one_path)
  }

  # Generate Papers 2..n (bare structural template)
  if (n >= 2) {
    for (i in seq.int(2L, n)) {
      ordinal <- ordinals[[i]]
      ordinal_adj <- ordinal_adjectives[[i]]
      chapter_number <- i + 1L  # paper 2 -> chapter 3, paper 3 -> chapter 4, ...
      filename <- sprintf("%02d-paper-%s.qmd", chapter_number, ordinal)
      body <- c(
        "---",
        sprintf("title: \"Title of the %s paper\"", ordinal_adj),
        "---",
        "",
        "\\begin{center}",
        "\\textbf{Abstract}",
        "\\end{center}",
        "",
        "\\begin{quote}",
        "\\itshape",
        "State the question, methods, principal findings, and contribution in 150--250 words.",
        "\\end{quote}",
        "",
        "## Introduction",
        "",
        "## Literature review",
        "",
        "## Methodology",
        "",
        "## Data",
        "",
        "## Results",
        "",
        "## Discussion",
        "",
        "## Conclusions",
        "",
        "## References {.unnumbered}",
        "",
        "::: {#refs}",
        ":::",
        "",
        "## Appendices {.unnumbered}",
        "",
        sprintf("### %d.A Supplementary material {.unnumbered}", chapter_number),
        "",
        sprintf("### %d.B Additional analysis {.unnumbered}", chapter_number)
      )
      writeLines(body, file.path(chap_dir, filename))
    }
  }

  # Move conclusion to its new position
  old_concl <- list.files(chap_dir, pattern = "-conclusion\\.qmd$",
                          full.names = TRUE)
  for (f in old_concl) fs::file_delete(f)
  conclusion_chapter_num <- n + 2L  # intro + n papers + conclusion
  conclusion_filename <- sprintf("%02d-conclusion.qmd",
                                 conclusion_chapter_num)
  conclusion_body <- c(
    "---",
    "title: \"Conclusions\"",
    "---",
    "",
    "## Implications and future research",
    "",
    "Summarise the implications of the constituent papers and outline directions for future research.",
    "",
    "## Summary",
    "",
    "Provide a brief summary of the overall contribution of the thesis.",
    "",
    "## References {.unnumbered}",
    "",
    "::: {#refs}",
    ":::"
  )
  writeLines(conclusion_body, file.path(chap_dir, conclusion_filename))

  # Rewrite the chapter list in _quarto.yml
  qy_path <- file.path(path, "_quarto.yml")
  if (!file.exists(qy_path)) return(invisible(NULL))
  qy_lines <- readLines(qy_path, warn = FALSE)
  # Locate the chapters: block and the next top-level key
  ch_start <- grep("^  chapters:", qy_lines)
  if (length(ch_start) != 1L) return(invisible(NULL))
  # Find the end of the chapters block (next line with same or lesser indent
  # that starts a new key, e.g. `format:` or `appendices:` etc.)
  after_start <- (ch_start + 1L):length(qy_lines)
  ch_end_rel <- which(grepl("^[A-Za-z]", qy_lines[after_start]) |
                      grepl("^[a-z][a-z-]*:", qy_lines[after_start]))
  ch_end <- if (length(ch_end_rel)) {
    after_start[[ch_end_rel[[1L]]]] - 1L
  } else {
    length(qy_lines)
  }

  # Keep all non-paper, non-conclusion entries (prelims, index, etc.)
  prelim_block <- qy_lines[(ch_start + 1L):ch_end]
  prelim_block <- prelim_block[
    !grepl("paper-[a-z]+\\.qmd", prelim_block) &
    !grepl("-conclusion\\.qmd", prelim_block)
  ]
  # Drop any trailing blank lines so the paper list joins cleanly
  while (length(prelim_block) &&
         !nzchar(trimws(prelim_block[[length(prelim_block)]]))) {
    prelim_block <- prelim_block[-length(prelim_block)]
  }
  # Build the new paper + conclusion lines (indent: 4 spaces)
  new_paper_lines <- character(0)
  for (i in seq_len(n)) {
    ordinal <- ordinals[[i]]
    chapter_number <- i + 1L
    new_paper_lines <- c(
      new_paper_lines,
      sprintf("    - chapters/%02d-paper-%s.qmd",
              chapter_number, ordinal)
    )
  }
  new_paper_lines <- c(
    new_paper_lines,
    sprintf("    - chapters/%02d-conclusion.qmd", conclusion_chapter_num)
  )

  new_qy <- c(
    qy_lines[seq_len(ch_start)],
    prelim_block,
    new_paper_lines,
    if (ch_end < length(qy_lines)) qy_lines[(ch_end + 1L):length(qy_lines)]
  )
  writeLines(new_qy, qy_path)
  invisible(NULL)
}

# Map abbreviated degree codes to the full degree name that conventionally
# appears on the title page (per the Presentation of Theses Policy section
# 8.1.b "the full title of the degree should be stated not the abbreviated
# form").
degree_full_name <- function(degree) {
  switch(degree,
    "PhD"                    = "Doctor of Philosophy",
    "MPhil"                  = "Master of Philosophy",
    "DBA"                    = "Doctor of Business Administration",
    "MD"                     = "Doctor of Medicine",
    "EngD"                   = "Doctor of Engineering",
    "PhD by Enterprise"      = "Doctor of Philosophy by Enterprise",
    "Professional Doctorate" = "Professional Doctorate",
    degree
  )
}

# Internal: substitute placeholders in scaffolded index.qmd + _quarto.yml.
# Uses fixed (literal) string substitution to avoid regex surprises.
substitute_skeleton <- function(path, title, author, degree, faculty, school,
                                division, year, reference_style, engine,
                                mainfont, thesis_format) {
  files <- c(file.path(path, "index.qmd"), file.path(path, "_quarto.yml"))
  degree_full <- degree_full_name(degree)
  for (f in files) {
    if (!file.exists(f)) next
    body <- readLines(f, warn = FALSE, encoding = "UTF-8")
    body <- gsub("{{title}}",           title,                             body, fixed = TRUE)
    body <- gsub("{{forename}}",        author$forename %||% "Forename",   body, fixed = TRUE)
    body <- gsub("{{middle_initial}}",  author$middle_initial %||% "",     body, fixed = TRUE)
    body <- gsub("{{surname}}",         author$surname %||% "Surname",     body, fixed = TRUE)
    body <- gsub("{{native_name}}",     author$native_name %||% "",        body, fixed = TRUE)
    body <- gsub("{{degree_full}}",     degree_full,                       body, fixed = TRUE)
    body <- gsub("{{degree}}",          degree,                            body, fixed = TRUE)
    body <- gsub("{{faculty}}",         faculty,                           body, fixed = TRUE)
    body <- gsub("{{school}}",          school,                            body, fixed = TRUE)
    body <- gsub("{{division}}",        division,                          body, fixed = TRUE)
    body <- gsub("{{year}}",            as.character(year),                body, fixed = TRUE)
    body <- gsub("{{thesis_format}}",   thesis_format,                     body, fixed = TRUE)
    body <- gsub("{{reference_style}}", reference_style,                   body, fixed = TRUE)
    body <- gsub("{{engine}}",          engine,                            body, fixed = TRUE)
    body <- gsub("{{mainfont}}",        mainfont,                          body, fixed = TRUE)
    writeLines(body, f)
  }
}
