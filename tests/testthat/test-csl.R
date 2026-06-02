test_that("list_csl returns one row per bundled CSL", {
  styles <- list_csl()
  expect_s3_class(styles, "data.frame")
  expect_named(styles, c("name", "url", "retrieved", "sha256"))
  expect_setequal(styles$name,
    c("harvard-manchester", "apa", "chicago-author-date", "mhra", "vancouver"))
})

test_that("copy_csl copies a bundled file into a destination", {
  tmp <- withr::local_tempdir()
  path <- copy_csl("apa", to = tmp)
  expect_true(file.exists(path))
  expect_true(grepl("apa\\.csl$", path))
})

test_that("copy_csl errors on unknown style", {
  tmp <- withr::local_tempdir()
  expect_error(copy_csl("nope", to = tmp), class = "uomthesis_unknown_csl")
})
