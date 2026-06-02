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
