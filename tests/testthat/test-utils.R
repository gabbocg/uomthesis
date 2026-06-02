test_that("locate_project walks up to find _quarto.yml", {
  root <- withr::local_tempdir()
  fs::file_create(fs::path(root, "_quarto.yml"))
  fs::dir_create(fs::path(root, "chapters"))
  expect_equal(
    normalizePath(locate_project(fs::path(root, "chapters"))),
    normalizePath(root)
  )
})

test_that("locate_project errors when no _quarto.yml found", {
  empty <- withr::local_tempdir()
  expect_error(locate_project(empty), class = "uomthesis_no_project")
})
