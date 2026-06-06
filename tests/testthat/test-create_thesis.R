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

test_that("create_thesis substitutes placeholders in scaffolded files", {
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
  # Author and year metadata are substituted into index.qmd
  idx <- readLines(file.path(out, "index.qmd"))
  expect_false(any(grepl("\\{\\{[a-z_]+\\}\\}", idx)))
  expect_true(any(grepl("Carter", idx)))
  expect_true(any(grepl("2028", idx)))
  # The thesis title is substituted into _quarto.yml's book.title
  qy <- readLines(file.path(out, "_quarto.yml"))
  expect_false(any(grepl("\\{\\{[a-z_]+\\}\\}", qy)))
  expect_true(any(grepl("On the foo", qy)))
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

test_that("create_thesis num_papers shrinks the journal skeleton", {
  tmp <- withr::local_tempdir()
  out <- create_thesis(
    path = file.path(tmp, "thesis-n2"),
    format = "journal",
    author = list(forename = "Jane", surname = "Doe"),
    title = "Two papers",
    year = 2027,
    num_papers = 2L,
    open = FALSE
  )
  chap <- list.files(file.path(out, "chapters"), pattern = "\\.qmd$")
  expect_true("02-paper-one.qmd" %in% chap)
  expect_true("03-paper-two.qmd" %in% chap)
  expect_false("04-paper-three.qmd" %in% chap)
  expect_true("04-conclusion.qmd" %in% chap)
  qy <- readLines(file.path(out, "_quarto.yml"))
  expect_true(any(grepl("04-conclusion.qmd", qy)))
  expect_false(any(grepl("paper-three.qmd", qy)))
})

test_that("create_thesis num_papers grows the journal skeleton", {
  tmp <- withr::local_tempdir()
  out <- create_thesis(
    path = file.path(tmp, "thesis-n5"),
    format = "journal",
    author = list(forename = "Jane", surname = "Doe"),
    title = "Five papers",
    year = 2027,
    num_papers = 5L,
    open = FALSE
  )
  chap <- list.files(file.path(out, "chapters"), pattern = "\\.qmd$")
  expect_true(all(c("05-paper-four.qmd", "06-paper-five.qmd",
                    "07-conclusion.qmd") %in% chap))
  # Paper 1 (the rich demo) is preserved verbatim
  p1 <- readLines(file.path(out, "chapters", "02-paper-one.qmd"))
  expect_true(any(grepl("Title of the first paper", p1)))
  # New papers use ordinal adjectives in titles
  p4 <- readLines(file.path(out, "chapters", "05-paper-four.qmd"))
  expect_true(any(grepl("Title of the fourth paper", p4)))
  # New papers carry letter-prefixed appendix headings keyed to chapter number
  expect_true(any(grepl("5\\.A", p4)))
})

test_that("create_thesis rejects out-of-range num_papers", {
  tmp <- withr::local_tempdir()
  expect_error(
    create_thesis(file.path(tmp, "bad-zero"), format = "journal",
                  num_papers = 0L, open = FALSE),
    class = "uomthesis_invalid_num_papers"
  )
  expect_error(
    create_thesis(file.path(tmp, "bad-big"), format = "journal",
                  num_papers = 11L, open = FALSE),
    class = "uomthesis_invalid_num_papers"
  )
  expect_error(
    create_thesis(file.path(tmp, "bad-frac"), format = "journal",
                  num_papers = 2.5, open = FALSE),
    class = "uomthesis_invalid_num_papers"
  )
})
