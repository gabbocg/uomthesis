test_that("validate_metadata passes for the mini fixture", {
  res <- validate_metadata(fixture_path("mini-project"))
  expect_s3_class(res, "uomthesis_metadata_check")
  expect_true(res$ok)
  expect_length(res$findings, 0)
})

test_that("validate_metadata reports missing required field", {
  root <- withr::local_tempdir()
  fs::file_create(fs::path(root, "_quarto.yml"))
  writeLines(c(
    "---", "uomthesis:", "  degree: PhD", "---"
  ), fs::path(root, "index.qmd"))

  res <- validate_metadata(root)
  expect_false(res$ok)
  rule_ids <- vapply(res$findings, `[[`, character(1), "rule_id")
  expect_true("metadata-complete" %in% rule_ids)
})

test_that("validate_metadata flags out-of-set values", {
  root <- withr::local_tempdir()
  fs::file_create(fs::path(root, "_quarto.yml"))
  writeLines(c(
    "---", "uomthesis:",
    "  candidate:", "    forename: J", "    middle_initial: Q", "    surname: D",
    "  degree: DPhil",
    "  faculty: Humanities",
    "  school: Alliance Manchester Business School",
    "  year: 2027",
    "  thesis_format: standard",
    "---"
  ), fs::path(root, "index.qmd"))

  res <- validate_metadata(root)
  expect_false(res$ok)
  rule_ids <- vapply(res$findings, `[[`, character(1), "rule_id")
  expect_true("degree-faculty-school" %in% rule_ids)
})
