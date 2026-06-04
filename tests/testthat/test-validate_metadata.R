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

test_that("validate_metadata flags out-of-set school", {
  root <- withr::local_tempdir()
  fs::file_create(fs::path(root, "_quarto.yml"))
  writeLines(c(
    "---", "uomthesis:",
    "  candidate:", "    forename: J", "    middle_initial: Q", "    surname: D",
    "  degree: PhD",
    "  faculty: Humanities",
    "  school: Hogwarts School of Witchcraft and Wizardry",
    "  year: 2027",
    "  thesis_format: standard",
    "---"
  ), fs::path(root, "index.qmd"))
  res <- validate_metadata(root)
  expect_false(res$ok)
  rule_ids <- vapply(res$findings, `[[`, character(1), "rule_id")
  expect_true("degree-faculty-school" %in% rule_ids)
})

test_that("validate_metadata flags out-of-set thesis_format", {
  root <- withr::local_tempdir()
  fs::file_create(fs::path(root, "_quarto.yml"))
  writeLines(c(
    "---", "uomthesis:",
    "  candidate:", "    forename: J", "    middle_initial: Q", "    surname: D",
    "  degree: PhD",
    "  faculty: Humanities",
    "  school: Alliance Manchester Business School",
    "  year: 2027",
    "  thesis_format: practice-based",
    "---"
  ), fs::path(root, "index.qmd"))
  res <- validate_metadata(root)
  expect_false(res$ok)
  rule_ids <- vapply(res$findings, `[[`, character(1), "rule_id")
  expect_true("thesis-format" %in% rule_ids)
})

test_that("validate_metadata produces one finding per wrong field", {
  root <- withr::local_tempdir()
  fs::file_create(fs::path(root, "_quarto.yml"))
  writeLines(c(
    "---", "uomthesis:",
    "  candidate:", "    forename: J", "    middle_initial: Q", "    surname: D",
    "  degree: DPhil",
    "  faculty: Engineering",
    "  school: Hogwarts",
    "  year: 2027",
    "  thesis_format: standard",
    "---"
  ), fs::path(root, "index.qmd"))
  res <- validate_metadata(root)
  expect_false(res$ok)
  rule_ids <- vapply(res$findings, `[[`, character(1), "rule_id")
  expect_equal(sum(rule_ids == "degree-faculty-school"), 3)
})

test_that("print.uomthesis_metadata_check formats findings readably", {
  res <- validate_metadata(fixture_path("mini-project"))
  expect_snapshot(print(res))
})
