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

    # policy 7.3 — margin minima (mm)
    margins_mm = list(binding_edge = 40, other_min = 15),

    # policy 7.1 — approved typefaces
    allowed_fonts = c(
      "Arial", "Verdana", "Tahoma", "Trebuchet", "Calibri",
      "Times", "Times New Roman", "Palatino", "Garamond"
    ),

    # policy 7.1 — subset safe for pdflatex without extra package installs
    pdflatex_safe_fonts = c("Times New Roman", "Times"),

    # policy 7.1 — allowed line-spacing values
    allowed_linestretch = c(1.5, 2.0),

    # policy 4.6, policy 13.11 — word count upper limits (standard and journal formats)
    word_caps = list(
      standard = list(
        PhD = 80000L, MPhil = 50000L, DBA = 50000L, MD = 80000L,
        EngD = 80000L, `PhD by Enterprise` = 80000L,
        `Professional Doctorate` = 50000L
      ),
      journal = list(
        PhD = 90000L, MPhil = 60000L, DBA = 60000L, MD = 90000L,
        EngD = 90000L, `PhD by Enterprise` = 90000L,
        `Professional Doctorate` = 60000L
      )
    ),

    # policy 8.1 — required preliminary pages (in order)
    required_prelims = c(
      "covid_impact_statement",  # policy 8.1.a (optional; only when present)
      "title_page",              # policy 8.1.b
      "list_of_contents",        # policy 8.1.c
      "other_lists",             # policy 8.1.d
      "abstract",                # policy 8.1.e
      "declaration",             # policy 8.1.f
      "copyright_statement"      # policy 8.1.g
    ),

    # policy 8.1.b — title page statement template
    title_page_statement = "A thesis submitted to The University of Manchester for the degree of {degree} in the Faculty of {faculty}.",

    # policy 8.1.f EITHER variant — verbatim from policy (semicolon terminates the
    # enumeration item). The partial template will translate the trailing
    # semicolon to a period when rendering a standalone declaration.
    declaration_either = "that no portion of the work referred to in this thesis has been submitted in support of an application for another degree or qualification of this or any other university or other institute of learning;",

    # policy 8.1.f — declaration OR variant (no leading "I declare"; two sentences)
    declaration_or = "what portion of the work referred to in this thesis has been submitted in support of an application for another degree or qualification of this or any other university or other institute of learning. This should include reference to joint authorship of published materials which might have been included in a thesis submitted by another student to this university or any other university or other institute of learning.",

    # policy 8.1.g — copyright statement bullets (character vector of length 4)
    copyright_bullets = c(
      "The author of this thesis (including any appendices and/or schedules to this thesis) owns certain copyright or related rights in it (the \"Copyright\") and they have given the University of Manchester certain rights to use such Copyright, including for administrative purposes.",
      "Copies of this thesis, either in full or in extracts and whether in hard or electronic copy, may be made only in accordance with the Copyright, Designs and Patents Act 1988 (as amended) and regulations issued under it or, where appropriate, in accordance with licensing agreements which the University has from time to time. This page must form part of any such copies made.",
      "The ownership of certain Copyright, patents, designs, trademarks and other intellectual property (the \"Intellectual Property\") and any reproductions of copyright works in the thesis, for example graphs and tables (\"Reproductions\"), which may be described in this thesis, may not be owned by the author and may be owned by third parties. Such Intellectual Property and Reproductions cannot and must not be made available for use without the prior written permission of the owner(s) of the relevant Intellectual Property and/or Reproductions.",
      "Further information on the conditions under which disclosure, publication and commercialisation of this thesis, the Copyright and any Intellectual Property and/or Reproductions described in it may take place is available in the University IP Policy, in any relevant Thesis restriction declarations deposited in the University Library, the University Library's regulations and in the University's policy on the Presentation of Theses."
    ),

    # policy 9.1.d — AI disclosure sample text
    ai_disclosure_sample = "Generative AI Disclosure: I used [AI tool name] to assist in idea generation, image creation, and for feedback on grammar and content. I implemented some of its recommendations. I used [AI tool name] to explore ideas for visuals (one of which is used and cited on page 2)",

    # policy 8.1.b — degree titles per University Regulation XI
    allowed_degrees = c(
      "PhD", "MPhil", "DBA", "MD", "EngD",
      "PhD by Enterprise", "Professional Doctorate"
    ),

    # policy 8.1.b — Faculty titles per University Regulation X
    allowed_faculties = c(
      "Humanities",
      "Biology, Medicine and Health",
      "Science and Engineering"
    ),

    # policy 8.1.b — School titles per University Regulation X (Humanities schools)
    allowed_schools = c(
      "Alliance Manchester Business School",
      "School of Arts, Languages and Cultures",
      "School of Social Sciences",
      "School of Environment, Education and Development"
    ),

    # AMBS Doctoral Programmes PGR Handbook — divisional structure (A&F / IMP / MSM / PMO)
    ambs_divisions = c("A&F", "IMP", "MSM", "PMO")
  )
}
