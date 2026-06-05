test_that("create_thesis scaffolds a standard project with required files", {
  tmp <- withr::local_tempdir()
  out <- create_thesis(
    path = file.path(tmp, "my-thesis"),
    format = "standard",
    degree = "PhD",
    author = list(forename = "Jane", middle_initial = "Q", surname = "Doe"),
    title = "A test thesis",
    year = 2027,
    division = "MSM",
    open = FALSE
  )
  expect_true(file.exists(file.path(out, "_quarto.yml")))
  expect_true(file.exists(file.path(out, "index.qmd")))
  expect_true(dir.exists(file.path(out, "_extensions", "uomthesis-standard")))
  expect_true(dir.exists(file.path(out, "_extensions", "uomthesis-standard", "csl")))
  expect_true(file.exists(file.path(out, "_extensions", "uomthesis-standard", "csl",
                                    "harvard-manchester.csl")))
})

test_that("create_thesis substitutes placeholders in index.qmd", {
  tmp <- withr::local_tempdir()
  out <- create_thesis(
    path = file.path(tmp, "thesis"),
    format = "standard",
    degree = "PhD",
    author = list(forename = "Alice", middle_initial = "B", surname = "Carter"),
    title = "On the foo",
    year = 2028,
    open = FALSE
  )
  idx <- readLines(file.path(out, "index.qmd"))
  expect_false(any(grepl("\\{\\{title\\}\\}", idx)))
  expect_true(any(grepl("On the foo", idx)))
  expect_true(any(grepl("Carter", idx)))
  expect_true(any(grepl("2028", idx)))
})

test_that("create_thesis rejects an out-of-set font", {
  tmp <- withr::local_tempdir()
  expect_error(
    create_thesis(file.path(tmp, "bad"), mainfont = "Comic Sans", open = FALSE),
    class = "uomthesis_invalid_font"
  )
})

test_that("create_thesis rejects pdflatex with a non-safe font", {
  tmp <- withr::local_tempdir()
  expect_error(
    create_thesis(
      file.path(tmp, "bad"),
      engine = "pdflatex", mainfont = "Calibri", open = FALSE
    ),
    class = "uomthesis_engine_font_mismatch"
  )
})

test_that("create_thesis rejects an out-of-set degree", {
  tmp <- withr::local_tempdir()
  expect_error(
    create_thesis(file.path(tmp, "bad"), degree = "DPhil", open = FALSE),
    class = "uomthesis_invalid_degree"
  )
})

test_that("create_thesis errors when path exists and force is FALSE", {
  tmp <- withr::local_tempdir()
  fs::dir_create(file.path(tmp, "exists"))
  expect_error(
    create_thesis(file.path(tmp, "exists"), open = FALSE),
    class = "uomthesis_path_exists"
  )
})

test_that("create_thesis succeeds when path is an empty existing directory and force=TRUE", {
  tmp <- withr::local_tempdir()
  fs::dir_create(file.path(tmp, "empty"))
  expect_no_error(create_thesis(
    file.path(tmp, "empty"),
    force = TRUE, open = FALSE
  ))
})

test_that("create_thesis errors when path is non-empty and force=TRUE", {
  tmp <- withr::local_tempdir()
  fs::dir_create(file.path(tmp, "non-empty"))
  writeLines("hi", file.path(tmp, "non-empty", "stuff.txt"))
  expect_error(
    create_thesis(file.path(tmp, "non-empty"), force = TRUE, open = FALSE),
    class = "uomthesis_path_not_empty"
  )
})

test_that("create_thesis(format='journal') scaffolds the journal skeleton", {
  tmp <- withr::local_tempdir()
  out <- create_thesis(
    file.path(tmp, "journal-thesis"),
    format = "journal",
    author = list(forename = "Bob", middle_initial = "C", surname = "Daniels"),
    title = "Journal thesis",
    year = 2027,
    open = FALSE
  )
  expect_true(dir.exists(file.path(out, "_extensions", "uomthesis-journal")))
  expect_true(file.exists(file.path(out, "chapters", "02-paper-one.qmd")))
  idx <- readLines(file.path(out, "index.qmd"))
  expect_true(any(grepl("thesis_format: \"journal\"", idx)))
})

test_that("create_thesis-scaffolded project passes check_thesis()", {
  tmp <- withr::local_tempdir()
  out <- create_thesis(
    file.path(tmp, "scaffolded"),
    format = "standard",
    degree = "PhD",
    author = list(forename = "Jane", middle_initial = "Q", surname = "Doe"),
    title = "Integration test",
    year = 2027,
    division = "MSM",
    open = FALSE
  )
  res <- check_thesis(out, format = "console")
  expect_s3_class(res, "uomthesis_check_report")
  expect_true(res$ok)
  expect_length(res$findings, 0)
})
