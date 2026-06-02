test_that("parse_qmd_yaml returns parsed front-matter as a list", {
  out <- parse_qmd_yaml(fixture_path("single-qmd", "sample.qmd"))
  expect_type(out, "list")
  expect_equal(out$title, "Sample")
  expect_equal(out$uomthesis$degree, "PhD")
  expect_equal(out$uomthesis$year, 2027)
})

test_that("parse_qmd_yaml returns empty list when no front-matter", {
  tmp <- withr::local_tempfile(fileext = ".qmd")
  writeLines("# Just a heading", tmp)
  expect_equal(parse_qmd_yaml(tmp), list())
})

test_that("classify_qmd_file uses filename convention", {
  expect_equal(classify_qmd_file("chapters/00-abstract.qmd"), "prelim")
  expect_equal(classify_qmd_file("chapters/01-intro.qmd"),    "body")
  expect_equal(classify_qmd_file("chapters/appendix-a.qmd"),  "appendix")
  expect_equal(classify_qmd_file("references.bib"),           "bibliography")
  expect_equal(classify_qmd_file("chapters/09-discussion.qmd"), "body")
})

test_that("read_uomthesis_metadata reads the uomthesis block from index.qmd", {
  meta <- read_uomthesis_metadata(fixture_path("mini-project"))
  expect_equal(meta$degree, "PhD")
  expect_equal(meta$candidate$surname, "Doe")
})

test_that("parse_qmd_yaml returns empty list for a completely empty file", {
  tmp <- withr::local_tempfile(fileext = ".qmd")
  writeLines(character(0), tmp)
  expect_equal(parse_qmd_yaml(tmp), list())
})

test_that("read_uomthesis_metadata errors when index.qmd is absent", {
  tmp <- withr::local_tempdir()
  expect_error(read_uomthesis_metadata(tmp), class = "uomthesis_no_index")
})

test_that("read_uomthesis_metadata errors when uomthesis: block is missing", {
  tmp <- withr::local_tempdir()
  writeLines(c("---", "title: No block", "---"), file.path(tmp, "index.qmd"))
  expect_error(read_uomthesis_metadata(tmp), class = "uomthesis_no_metadata")
})
