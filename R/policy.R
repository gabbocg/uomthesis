#' Constants drawn from the University of Manchester Presentation of Theses Policy
#'
#' Single source of truth for every policy-derived constant used elsewhere in
#' the package. Each entry carries a comment with its policy section number so
#' future policy revisions can be applied surgically.
#'
#' @return A named list.
#' @keywords internal
policy_constants <- function() {
  list(
    version       = "12",
    dated         = as.Date("2026-03-01"),
    next_review   = as.Date("2028-11-01"),
    source_url    = "https://documents.manchester.ac.uk/display.aspx?DocID=7420",
    margins_mm    = NULL,
    allowed_fonts = NULL,
    pdflatex_safe_fonts  = NULL,
    allowed_linestretch  = NULL,
    word_caps     = NULL,
    required_prelims     = NULL,
    title_page_statement = NULL,
    declaration_either   = NULL,
    declaration_or       = NULL,
    copyright_bullets    = NULL,
    ai_disclosure_sample = NULL,
    allowed_degrees      = NULL,
    allowed_faculties    = NULL,
    allowed_schools      = NULL,
    ambs_divisions       = NULL
  )
}
