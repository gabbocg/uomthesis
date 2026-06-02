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

test_that("margins match policy §7.3 minima", {
  m <- policy_constants()$margins_mm
  expect_named(m, c("binding_edge", "other_min"))
  expect_equal(m$binding_edge, 40)
  expect_equal(m$other_min, 15)
})

test_that("allowed_fonts and pdflatex_safe_fonts match policy §7.1", {
  p <- policy_constants()
  expect_setequal(p$allowed_fonts,
    c("Arial", "Verdana", "Tahoma", "Trebuchet", "Calibri",
      "Times", "Times New Roman", "Palatino", "Garamond"))
  expect_setequal(p$pdflatex_safe_fonts, c("Times New Roman", "Times"))
})

test_that("allowed_linestretch matches policy §7.1", {
  expect_setequal(policy_constants()$allowed_linestretch, c(1.5, 2.0))
})

test_that("word_caps match policy §4.6 and §13.11", {
  w <- policy_constants()$word_caps
  expect_equal(w$standard$PhD, 80000)
  expect_equal(w$standard$MPhil, 50000)
  expect_equal(w$journal$PhD, 90000)
  expect_equal(w$journal$MPhil, 60000)
})

test_that("required_prelims matches policy §8.1 order", {
  rp <- policy_constants()$required_prelims
  expect_equal(rp,
    c("covid_impact_statement", "title_page", "list_of_contents",
      "other_lists", "abstract", "declaration", "copyright_statement"))
})

test_that("title page statement matches policy §8.1.b verbatim", {
  expect_snapshot(policy_constants()$title_page_statement)
})

test_that("declaration EITHER variant matches policy §8.1.f verbatim", {
  expect_snapshot(policy_constants()$declaration_either)
})

test_that("declaration OR variant matches policy §8.1.f verbatim", {
  expect_snapshot(policy_constants()$declaration_or)
})

test_that("copyright bullets match policy §8.1.g verbatim", {
  expect_snapshot(policy_constants()$copyright_bullets)
})

test_that("AI disclosure sample matches policy §9.1.d verbatim", {
  expect_snapshot(policy_constants()$ai_disclosure_sample)
})

test_that("allowed_degrees/faculties/schools/ambs_divisions are populated", {
  p <- policy_constants()
  expect_true("PhD" %in% p$allowed_degrees)
  expect_setequal(p$allowed_faculties,
    c("Humanities", "Biology, Medicine and Health", "Science and Engineering"))
  expect_true("Alliance Manchester Business School" %in% p$allowed_schools)
  expect_setequal(p$ambs_divisions, c("A&F", "IMP", "MSM", "PMO"))
})
