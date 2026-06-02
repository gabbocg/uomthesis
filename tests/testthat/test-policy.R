test_that("policy_constants() returns the documented top-level structure", {
  p <- policy_constants()

  expect_type(p, "list")
  expect_named(p, c("version", "dated", "next_review", "source_url",
                    "margins_mm", "allowed_fonts", "pdflatex_safe_fonts",
                    "allowed_linestretch", "word_caps",
                    "required_prelims", "title_page_statement",
                    "declaration_either", "declaration_or",
                    "copyright_bullets", "ai_disclosure_sample",
                    "allowed_degrees", "allowed_faculties",
                    "allowed_schools", "ambs_divisions"))

  expect_equal(p$version, "12")
  expect_s3_class(p$dated, "Date")
  expect_equal(format(p$dated, "%Y-%m"), "2026-03")
  expect_s3_class(p$next_review, "Date")
})
