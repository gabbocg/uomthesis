test_that("word_count counts body only, excludes prelim", {
  wc <- word_count(fixture_path("wc-project"))
  expect_s3_class(wc, "uomthesis_word_count")
  expect_equal(wc$total, 10)
  expect_equal(wc$cap, 80000)
  expect_equal(wc$format, "standard")
  expect_equal(wc$degree, "PhD")
  expect_false(wc$over)
  expect_named(wc$by_chapter, "chapters/01-intro.qmd")
})

test_that("print.uomthesis_word_count produces a one-screen summary", {
  expect_snapshot(print(word_count(fixture_path("wc-project"))))
})
