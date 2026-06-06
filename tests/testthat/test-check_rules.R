test_that("rule_registry returns a list of properly-shaped rules", {
  rules <- rule_registry()
  expect_true(length(rules) >= 4)
  for (r in rules) {
    expect_named(r, c("id", "policy_ref", "phase", "formats",
                      "severity", "check", "rationale"),
                 ignore.order = TRUE)
    expect_true(r$phase %in% c("source", "pdf"))
    expect_true(r$severity %in% c("error", "warning"))
    expect_true(is.function(r$check))
  }
})

test_that("rule_registry has unique IDs", {
  ids <- vapply(rule_registry(), `[[`, character(1), "id")
  expect_false(any(duplicated(ids)))
})

test_that("get_rule returns the requested rule by id", {
  r <- get_rule("metadata-complete")
  expect_equal(r$id, "metadata-complete")
})

test_that("metadata-complete rule fires for missing surname", {
  rule <- get_rule("metadata-complete")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$candidate$surname <- NULL
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
  expect_equal(finding$rule_id, "metadata-complete")
  expect_equal(finding$severity, "error")
})

test_that("metadata-complete passes on full mini-project metadata", {
  rule <- get_rule("metadata-complete")
  ctx  <- build_ctx(fixture_path("mini-project"))
  expect_null(rule$check(ctx))
})

test_that("degree-faculty-school fires on out-of-set degree", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$degree <- "DPhil"
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
  expect_equal(finding$rule_id, "degree-faculty-school")
})

test_that("degree-faculty-school fires on out-of-set faculty", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$faculty <- "Engineering"
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
})

test_that("degree-faculty-school fires on out-of-set school", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$school <- "Hogwarts"
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
})

test_that("degree-faculty-school passes on valid trio", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  expect_null(rule$check(ctx))
})

test_that("year-not-month fires when year is out of plausible range", {
  rule <- get_rule("year-not-month")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$year <- 1850
  expect_false(is.null(rule$check(ctx)))
  ctx$metadata$year <- 2150
  expect_false(is.null(rule$check(ctx)))
  ctx$metadata$year <- "May 2027"
  expect_false(is.null(rule$check(ctx)))
})

test_that("year-not-month passes on plausible integer year", {
  rule <- get_rule("year-not-month")
  ctx  <- build_ctx(fixture_path("mini-project"))
  expect_null(rule$check(ctx))
})

test_that("thesis-format fires on non-standard/journal value", {
  rule <- get_rule("thesis-format")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$thesis_format <- "practice-based"
  expect_false(is.null(rule$check(ctx)))
})

test_that("thesis-format passes for 'standard'", {
  rule <- get_rule("thesis-format")
  ctx  <- build_ctx(fixture_path("mini-project"))
  expect_null(rule$check(ctx))
})

test_that("degree-faculty-school accumulates findings for multiple wrong fields", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$degree  <- "DPhil"
  ctx$metadata$faculty <- "Engineering"
  ctx$metadata$school  <- "Hogwarts"
  result <- rule$check(ctx)
  expect_type(result, "list")
  # The result is a list of three findings — confirm by checking it's a list-of-lists
  expect_true(length(result) == 3)
  # Each element should look like a finding (have $rule_id)
  for (f in result) expect_equal(f$rule_id, "degree-faculty-school")
})

test_that("get_rule errors with class uomthesis_unknown_rule on unknown id", {
  expect_error(get_rule("does-not-exist"), class = "uomthesis_unknown_rule")
})

# ---------------------------------------------------------------------------
# Phase 5B: YAML-knob rules
# ---------------------------------------------------------------------------

# build_ctx exposes ctx$front_matter

test_that("build_ctx exposes front_matter list", {
  ctx <- build_ctx(fixture_path("mini-project"))
  expect_true(is.list(ctx$front_matter))
  expect_true("uomthesis" %in% names(ctx$front_matter))
})

# 5.B.1 font-allowed

test_that("font-allowed fires on out-of-set font", {
  rule <- get_rule("font-allowed")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$mainfont <- "Comic Sans"
  expect_false(is.null(rule$check(ctx)))
  expect_equal(rule$check(ctx)$rule_id, "font-allowed")
  expect_equal(rule$check(ctx)$severity, "error")
})

test_that("font-allowed passes for an allowed font", {
  rule <- get_rule("font-allowed")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$mainfont <- "Times New Roman"
  expect_null(rule$check(ctx))
})

test_that("font-allowed passes when mainfont is unset (Quarto default)", {
  rule <- get_rule("font-allowed")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$mainfont <- NULL
  expect_null(rule$check(ctx))
})

# 5.B.2 font-engine-compat

test_that("font-engine-compat fires for pdflatex with unsafe font", {
  rule <- get_rule("font-engine-compat")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter[["pdf-engine"]] <- "pdflatex"
  ctx$front_matter$mainfont        <- "Arial"
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
  expect_equal(finding$rule_id, "font-engine-compat")
  expect_equal(finding$severity, "error")
})

test_that("font-engine-compat passes for pdflatex with pdflatex-safe font", {
  rule <- get_rule("font-engine-compat")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter[["pdf-engine"]] <- "pdflatex"
  ctx$front_matter$mainfont        <- "Times New Roman"
  expect_null(rule$check(ctx))
})

test_that("font-engine-compat passes for lualatex even with non-pdflatex-safe font", {
  rule <- get_rule("font-engine-compat")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter[["pdf-engine"]] <- "lualatex"
  ctx$front_matter$mainfont        <- "Arial"
  expect_null(rule$check(ctx))
})

test_that("font-engine-compat passes when pdf-engine is unset", {
  rule <- get_rule("font-engine-compat")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter[["pdf-engine"]] <- NULL
  ctx$front_matter$mainfont        <- "Arial"
  expect_null(rule$check(ctx))
})

# 5.B.3 linespacing-allowed

test_that("linespacing-allowed fires on non-allowed linestretch", {
  rule <- get_rule("linespacing-allowed")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$linestretch <- 1.0
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
  expect_equal(finding$rule_id, "linespacing-allowed")
  expect_equal(finding$severity, "error")
})

test_that("linespacing-allowed passes for linestretch 1.5", {
  rule <- get_rule("linespacing-allowed")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$linestretch <- 1.5
  expect_null(rule$check(ctx))
})

test_that("linespacing-allowed passes for linestretch 2.0", {
  rule <- get_rule("linespacing-allowed")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$linestretch <- 2.0
  expect_null(rule$check(ctx))
})

test_that("linespacing-allowed passes when linestretch is unset", {
  rule <- get_rule("linespacing-allowed")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$linestretch <- NULL
  expect_null(rule$check(ctx))
})

# 5.B.4 ai-disclosure-shape

test_that("ai-disclosure-shape fires when include is true but tools is empty", {
  rule <- get_rule("ai-disclosure-shape")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$ai_disclosure <- list(include = TRUE, tools = list())
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
  expect_equal(finding$rule_id, "ai-disclosure-shape")
  expect_equal(finding$severity, "warning")
})

test_that("ai-disclosure-shape fires when include is true and tools is missing", {
  rule <- get_rule("ai-disclosure-shape")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$ai_disclosure <- list(include = TRUE)
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
})

test_that("ai-disclosure-shape passes when include is true and tools is non-empty", {
  rule <- get_rule("ai-disclosure-shape")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$ai_disclosure <- list(include = TRUE, tools = list("ChatGPT-5"))
  expect_null(rule$check(ctx))
})

test_that("ai-disclosure-shape passes when include is false", {
  rule <- get_rule("ai-disclosure-shape")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$ai_disclosure <- list(include = FALSE, tools = list())
  expect_null(rule$check(ctx))
})

test_that("ai-disclosure-shape passes when ai_disclosure is absent", {
  rule <- get_rule("ai-disclosure-shape")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$ai_disclosure <- NULL
  expect_null(rule$check(ctx))
})

# 5.B.5 english-language

test_that("english-language fires on non-English lang", {
  rule <- get_rule("english-language")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$lang <- "fr"
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
  expect_equal(finding$rule_id, "english-language")
  expect_equal(finding$severity, "warning")
})

test_that("english-language passes for lang en-GB", {
  rule <- get_rule("english-language")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$lang <- "en-GB"
  expect_null(rule$check(ctx))
})

test_that("english-language passes for lang en-US", {
  rule <- get_rule("english-language")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$lang <- "en-US"
  expect_null(rule$check(ctx))
})

test_that("english-language passes for lang en", {
  rule <- get_rule("english-language")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$lang <- "en"
  expect_null(rule$check(ctx))
})

test_that("english-language passes when lang is unset", {
  rule <- get_rule("english-language")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$front_matter$lang <- NULL
  expect_null(rule$check(ctx))
})

# rule_registry now has 13 rules (updated in Phase 5C)

# ---------------------------------------------------------------------------
# Phase 5C: text-matching rules (partial template files)
# ---------------------------------------------------------------------------

# Helper: create a temporary mock project with optional partial files
# chapters: character vector of chapter file names (relative to root); default is c("index.qmd")
# quarto_yaml_extra: character vector of extra lines appended to _quarto.yml
# qmd_files: named list of extra qmd content to write; names are paths relative to root
make_mock_project <- function(thesis_format = "standard",
                              degree = "PhD",
                              faculty = "Humanities",
                              school = "Alliance Manchester Business School",
                              forename = "Jane",
                              middle_initial = "Q",
                              surname = "Doe",
                              year = 2027,
                              declaration_variant = "either",
                              partials = list(),
                              chapters = NULL,
                              quarto_yaml_extra = character(0),
                              qmd_files = list(),
                              create_extension_dir = TRUE) {
  root <- withr::local_tempdir(.local_envir = parent.frame())
  chapter_list <- if (!is.null(chapters)) chapters else c("index.qmd")
  chapter_lines <- vapply(chapter_list, function(f) paste0("    - ", f), character(1))
  fs::file_create(fs::path(root, "_quarto.yml"))
  writeLines(c(
    "project:", "  type: book",
    "book:", "  chapters:",
    chapter_lines,
    quarto_yaml_extra
  ), fs::path(root, "_quarto.yml"))
  writeLines(c(
    "---",
    "title: Mock",
    "uomthesis:",
    "  candidate:",
    paste0("    forename: ", forename),
    paste0("    middle_initial: ", middle_initial),
    paste0("    surname: ", surname),
    paste0("  degree: ", degree),
    paste0("  faculty: ", faculty),
    paste0("  school: ", school),
    paste0("  year: ", year),
    paste0("  thesis_format: ", thesis_format),
    "  declaration:",
    paste0("    variant: ", declaration_variant),
    "---"
  ), fs::path(root, "index.qmd"))
  if (create_extension_dir) {
    partial_dir <- fs::path(root, "_extensions", paste0("uomthesis-", thesis_format), "partials")
    fs::dir_create(partial_dir)
    for (nm in names(partials)) {
      writeLines(partials[[nm]], fs::path(partial_dir, nm))
    }
  }
  # Write any extra qmd files requested by the test
  for (nm in names(qmd_files)) {
    abs <- fs::path(root, nm)
    fs::dir_create(fs::path_dir(abs))
    writeLines(qmd_files[[nm]], abs)
  }
  root
}

# 5.C.1 — title-page-statement

test_that("title-page-statement passes when partial contains the policy statement", {
  policy_text <- glue::glue(
    policy_constants()$title_page_statement,
    degree = "PhD", faculty = "Humanities"
  )
  root <- make_mock_project(partials = list(
    "title-page.tex" = c("\\begin{titlepage}", policy_text, "\\end{titlepage}")
  ))
  rule <- get_rule("title-page-statement")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("title-page-statement fires when statement is altered", {
  root <- make_mock_project(partials = list(
    "title-page.tex" = c("\\begin{titlepage}", "A thesis for Manchester.", "\\end{titlepage}")
  ))
  rule <- get_rule("title-page-statement")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "title-page-statement")
  expect_equal(result$severity, "error")
})

test_that("title-page-statement returns NULL when partial doesn't exist", {
  root <- make_mock_project(partials = list())
  rule <- get_rule("title-page-statement")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("title-page-statement passes with whitespace-normalised statement", {
  # Statement split across lines (simulates realistic TeX indentation)
  policy_text <- "A thesis submitted to The University of Manchester\n  for the degree of PhD\n  in the Faculty of Humanities."
  root <- make_mock_project(partials = list(
    "title-page.tex" = c("\\begin{titlepage}", policy_text, "\\end{titlepage}")
  ))
  rule <- get_rule("title-page-statement")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

# 5.C.2 — declaration-text

test_that("declaration-text passes with correct 'either' variant", {
  decl_text <- policy_constants()$declaration_either
  root <- make_mock_project(
    declaration_variant = "either",
    partials = list(
      "declaration.tex" = c("\\section*{Declaration}", decl_text)
    )
  )
  rule <- get_rule("declaration-text")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("declaration-text passes with correct 'or' variant", {
  decl_text <- policy_constants()$declaration_or
  root <- make_mock_project(
    declaration_variant = "or",
    partials = list(
      "declaration.tex" = c("\\section*{Declaration}", decl_text)
    )
  )
  rule <- get_rule("declaration-text")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("declaration-text fires when text is altered", {
  root <- make_mock_project(
    declaration_variant = "either",
    partials = list(
      "declaration.tex" = c("I declare something different here.")
    )
  )
  rule <- get_rule("declaration-text")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "declaration-text")
  expect_equal(result$severity, "error")
})

test_that("declaration-text fires when 'or' text is used but variant is 'either'", {
  # Only contains the OR text but metadata says either
  decl_text <- policy_constants()$declaration_or
  root <- make_mock_project(
    declaration_variant = "either",
    partials = list(
      "declaration.tex" = c(decl_text)
    )
  )
  rule <- get_rule("declaration-text")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
})

test_that("declaration-text returns NULL when partial doesn't exist", {
  root <- make_mock_project(partials = list())
  rule <- get_rule("declaration-text")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

# 5.C.3 — copyright-text

test_that("copyright-text passes when all four bullets are present", {
  bullets <- policy_constants()$copyright_bullets
  root <- make_mock_project(partials = list(
    "copyright.tex" = c("\\section*{Copyright}", bullets)
  ))
  rule <- get_rule("copyright-text")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("copyright-text fires a single finding when one bullet is missing", {
  bullets <- policy_constants()$copyright_bullets
  root <- make_mock_project(partials = list(
    # Omit bullet 2 — keep 1, 3, 4
    "copyright.tex" = c(bullets[1], bullets[3], bullets[4])
  ))
  rule <- get_rule("copyright-text")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  # Single finding is returned as a plain list (not a list of lists)
  expect_equal(result$rule_id, "copyright-text")
  expect_equal(result$severity, "error")
})

test_that("copyright-text accumulates multiple findings when several bullets are missing", {
  bullets <- policy_constants()$copyright_bullets
  root <- make_mock_project(partials = list(
    # Only bullet 1 present
    "copyright.tex" = c(bullets[1])
  ))
  rule <- get_rule("copyright-text")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_type(result, "list")
  # Should have 3 findings (bullets 2, 3, 4 missing)
  expect_equal(length(result), 3L)
  for (f in result) expect_equal(f$rule_id, "copyright-text")
})

test_that("copyright-text returns NULL when partial doesn't exist", {
  root <- make_mock_project(partials = list())
  rule <- get_rule("copyright-text")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

# 5.C.4 — copyright-author-match

test_that("copyright-author-match passes when candidate name is in partial", {
  root <- make_mock_project(
    forename = "Jane", surname = "Doe",
    partials = list(
      "copyright.tex" = c("Copyright 2027 Jane Q. Doe. All rights reserved.")
    )
  )
  rule <- get_rule("copyright-author-match")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("copyright-author-match passes when no name is present", {
  # Policy section 8.1.g does not require an author signature on the copyright
  # page; the candidate's identity is established by the title page. Many real
  # AMBS theses use a "bullets-only" copyright page.
  root <- make_mock_project(
    forename = "Jane", surname = "Doe",
    partials = list(
      "copyright.tex" = c("Some bullet text without any author name signature.")
    )
  )
  rule <- get_rule("copyright-author-match")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("copyright-author-match fires on unsubstituted scaffold placeholder", {
  root <- make_mock_project(
    forename = "Jane", surname = "Doe",
    partials = list(
      "copyright.tex" = c("Copyright 2027 [Author Name]. All rights reserved.")
    )
  )
  rule <- get_rule("copyright-author-match")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "copyright-author-match")
  expect_equal(result$severity, "error")
})

test_that("copyright-author-match returns NULL when partial doesn't exist", {
  root <- make_mock_project(partials = list())
  rule <- get_rule("copyright-author-match")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("copyright-author-match returns NULL when candidate metadata is absent", {
  root <- make_mock_project(
    forename = "Jane", surname = "Doe",
    partials = list(
      "copyright.tex" = c("Copyright 2027 John Smith.")
    )
  )
  rule <- get_rule("copyright-author-match")
  ctx  <- build_ctx(root)
  # Remove candidate from context
  ctx$metadata$candidate <- NULL
  expect_null(rule$check(ctx))
})

# rule_registry now has 19 rules (17 from Phase 5D + 2 from Phase 5E)
test_that("rule_registry returns exactly 19 rules", {
  expect_equal(length(rule_registry()), 19L)
})

# ---------------------------------------------------------------------------
# Phase 5D: structure and resource rules
# ---------------------------------------------------------------------------

# 5.D.1 — prelim-order

test_that("prelim-order passes for correct 00- -> 01- -> appendix order", {
  root <- make_mock_project(
    chapters = c("index.qmd", "00-abstract.qmd", "00-acknowledgements.qmd",
                 "01-intro.qmd", "appendix-A.qmd"),
    qmd_files = list(
      "00-abstract.qmd"         = c("---", "title: Abstract", "---", "Short abstract."),
      "00-acknowledgements.qmd" = c("---", "title: Acknowledgements", "---", "Thanks."),
      "01-intro.qmd"            = c("---", "title: Introduction", "---", "Body text."),
      "appendix-A.qmd"          = c("---", "title: Appendix A", "---", "Appendix.")
    )
  )
  rule <- get_rule("prelim-order")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("prelim-order fires when a body chapter appears before a prelim", {
  root <- make_mock_project(
    chapters = c("index.qmd", "01-intro.qmd", "00-abstract.qmd"),
    qmd_files = list(
      "01-intro.qmd"    = c("---", "title: Introduction", "---", "Body text."),
      "00-abstract.qmd" = c("---", "title: Abstract", "---", "Short abstract.")
    )
  )
  rule <- get_rule("prelim-order")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "prelim-order")
  expect_equal(result$severity, "error")
})

test_that("prelim-order passes when only body chapters exist (no prelims)", {
  root <- make_mock_project(
    chapters = c("index.qmd", "01-intro.qmd", "02-methods.qmd"),
    qmd_files = list(
      "01-intro.qmd"   = c("---", "title: Introduction", "---", "Body."),
      "02-methods.qmd" = c("---", "title: Methods", "---", "Methods.")
    )
  )
  rule <- get_rule("prelim-order")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("prelim-order fires when appendix appears before body chapter", {
  root <- make_mock_project(
    chapters = c("index.qmd", "00-abstract.qmd", "appendix-A.qmd", "01-intro.qmd"),
    qmd_files = list(
      "00-abstract.qmd" = c("---", "title: Abstract", "---", "Abstract."),
      "appendix-A.qmd"  = c("---", "title: Appendix A", "---", "Appendix."),
      "01-intro.qmd"    = c("---", "title: Introduction", "---", "Body.")
    )
  )
  rule <- get_rule("prelim-order")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "prelim-order")
})

# 5.D.2 — abstract-one-page

test_that("abstract-one-page passes when abstract is short (under 350 words)", {
  root <- make_mock_project(
    chapters = c("index.qmd", "00-abstract.qmd"),
    qmd_files = list(
      "00-abstract.qmd" = c("---", "title: Abstract", "---", "This is a short abstract.")
    )
  )
  rule <- get_rule("abstract-one-page")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("abstract-one-page fires when abstract exceeds 350 words", {
  long_text <- paste(rep("word", 400), collapse = " ")
  root <- make_mock_project(
    chapters = c("index.qmd", "00-abstract.qmd"),
    qmd_files = list(
      "00-abstract.qmd" = c("---", "title: Abstract", "---", long_text)
    )
  )
  rule <- get_rule("abstract-one-page")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "abstract-one-page")
  expect_equal(result$severity, "warning")
})

test_that("abstract-one-page returns NULL when no 00-abstract.qmd chapter exists", {
  root <- make_mock_project(
    chapters = c("index.qmd", "01-intro.qmd"),
    qmd_files = list(
      "01-intro.qmd" = c("---", "title: Introduction", "---", "Body text.")
    )
  )
  rule <- get_rule("abstract-one-page")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

# 5.D.3a — csl-bundled-or-path-exists

test_that("csl-bundled-or-path-exists passes when csl is a bundled name", {
  root <- make_mock_project(
    quarto_yaml_extra = c("csl: apa")
  )
  rule <- get_rule("csl-bundled-or-path-exists")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("csl-bundled-or-path-exists passes when csl path resolves to an existing file", {
  root <- make_mock_project()
  csl_path <- fs::path(root, "my-style.csl")
  writeLines(c("<style/>"), csl_path)
  ctx <- build_ctx(root)
  ctx$quarto_yaml$csl <- "my-style.csl"
  rule <- get_rule("csl-bundled-or-path-exists")
  expect_null(rule$check(ctx))
})

test_that("csl-bundled-or-path-exists fires when csl points to a nonexistent path", {
  root <- make_mock_project(
    quarto_yaml_extra = c("csl: nonexistent-style.csl")
  )
  rule <- get_rule("csl-bundled-or-path-exists")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "csl-bundled-or-path-exists")
  expect_equal(result$severity, "error")
})

test_that("csl-bundled-or-path-exists returns NULL when csl is not set", {
  root <- make_mock_project()
  rule <- get_rule("csl-bundled-or-path-exists")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

# 5.D.3b — bibliography-exists

test_that("bibliography-exists passes when bib file exists on disk", {
  root <- make_mock_project()
  bib_path <- fs::path(root, "refs.bib")
  writeLines(c("@article{key, title={T}, author={A}, year={2020}, journal={J}}"), bib_path)
  ctx <- build_ctx(root)
  ctx$quarto_yaml$bibliography <- "refs.bib"
  rule <- get_rule("bibliography-exists")
  expect_null(rule$check(ctx))
})

test_that("bibliography-exists fires for a single missing bib file", {
  root <- make_mock_project(
    quarto_yaml_extra = c("bibliography: missing-refs.bib")
  )
  rule <- get_rule("bibliography-exists")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "bibliography-exists")
  expect_equal(result$severity, "error")
})

test_that("bibliography-exists accumulates findings for multiple missing bib files", {
  root <- make_mock_project()
  ctx <- build_ctx(root)
  ctx$quarto_yaml$bibliography <- c("missing1.bib", "missing2.bib", "missing3.bib")
  rule <- get_rule("bibliography-exists")
  result <- rule$check(ctx)
  expect_type(result, "list")
  expect_equal(length(result), 3L)
  for (f in result) expect_equal(f$rule_id, "bibliography-exists")
})

test_that("bibliography-exists returns NULL when bibliography is not set", {
  root <- make_mock_project()
  rule <- get_rule("bibliography-exists")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

# ---------------------------------------------------------------------------
# Phase 5E: journal-format-only rules
# ---------------------------------------------------------------------------

# 5.E.1 — journal-rationale-present

test_that("journal-rationale-present returns NULL when extension dir does not exist", {
  # create_extension_dir = FALSE means no _extensions/uomthesis-journal/ directory at all
  root <- make_mock_project(thesis_format = "journal", create_extension_dir = FALSE)
  rule <- get_rule("journal-rationale-present")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("journal-rationale-present fires when extension dir exists but rationale.tex is missing", {
  # Extension dir created (no partials arg), but rationale.tex not written
  root <- make_mock_project(thesis_format = "journal", partials = list())
  rule <- get_rule("journal-rationale-present")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "journal-rationale-present")
  expect_equal(result$severity, "error")
})

test_that("journal-rationale-present fires when rationale.tex exists but is empty or near-empty", {
  root <- make_mock_project(
    thesis_format = "journal",
    partials = list("rationale.tex" = c("% just a comment", ""))
  )
  rule <- get_rule("journal-rationale-present")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "journal-rationale-present")
  expect_equal(result$severity, "error")
  expect_match(result$message, "empty or near-empty")
})

test_that("journal-rationale-present passes when rationale.tex has substantive content (>50 chars)", {
  substantive <- paste0(
    "This thesis is submitted in journal format because the research has been ",
    "published in peer-reviewed outlets. Each chapter corresponds to one paper."
  )
  root <- make_mock_project(
    thesis_format = "journal",
    partials = list("rationale.tex" = c(substantive))
  )
  rule <- get_rule("journal-rationale-present")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

# 5.E.2 — journal-contribution-stmts

test_that("journal-contribution-stmts returns NULL when no body chapters exist", {
  # Only index.qmd in chapters — no body chapter files
  root <- make_mock_project(thesis_format = "journal")
  rule <- get_rule("journal-contribution-stmts")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("journal-contribution-stmts fires when a body chapter has no contribution marker", {
  root <- make_mock_project(
    thesis_format = "journal",
    chapters = c("index.qmd", "01-paper.qmd"),
    qmd_files = list(
      "01-paper.qmd" = c("---", "title: Paper One", "---", "No contribution marker here.")
    )
  )
  rule <- get_rule("journal-contribution-stmts")
  ctx  <- build_ctx(root)
  result <- rule$check(ctx)
  expect_false(is.null(result))
  expect_equal(result$rule_id, "journal-contribution-stmts")
  expect_equal(result$severity, "warning")
  expect_match(result$message, "01-paper.qmd")
})

test_that("journal-contribution-stmts passes when body chapter has chunk-option contribution marker", {
  root <- make_mock_project(
    thesis_format = "journal",
    chapters = c("index.qmd", "01-paper.qmd"),
    qmd_files = list(
      "01-paper.qmd" = c(
        "---", "title: Paper One", "---",
        "```{r}",
        "#| contribution: \"I wrote 80% of this paper.\"",
        "1 + 1",
        "```"
      )
    )
  )
  rule <- get_rule("journal-contribution-stmts")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("journal-contribution-stmts passes when body chapter has heading-attribute contribution marker", {
  root <- make_mock_project(
    thesis_format = "journal",
    chapters = c("index.qmd", "01-paper.qmd"),
    qmd_files = list(
      "01-paper.qmd" = c(
        "---", "title: Paper One", "---",
        "# Paper Title {contribution=\"Lead author, experimental design and analysis.\"}"
      )
    )
  )
  rule <- get_rule("journal-contribution-stmts")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})

test_that("journal-contribution-stmts passes when body chapter has YAML contribution key", {
  root <- make_mock_project(
    thesis_format = "journal",
    chapters = c("index.qmd", "01-paper.qmd"),
    qmd_files = list(
      "01-paper.qmd" = c(
        "---",
        "title: Paper One",
        "contribution: \"I conducted all experiments and wrote the manuscript.\"",
        "---",
        "Body text."
      )
    )
  )
  rule <- get_rule("journal-contribution-stmts")
  ctx  <- build_ctx(root)
  expect_null(rule$check(ctx))
})
