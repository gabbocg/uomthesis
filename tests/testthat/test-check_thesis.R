test_that("check_thesis returns ok on the mini-project fixture", {
  res <- check_thesis(fixture_path("mini-project"), format = "console")
  expect_s3_class(res, "uomthesis_check_report")
  expect_true(res$ok)
  expect_length(res$findings, 0)
})

test_that("check_thesis aggregates findings from multiple failing rules", {
  # Use the mini-project but mutate index.qmd in a temp copy
  src  <- fixture_path("mini-project")
  tmp  <- withr::local_tempdir()
  fs::dir_copy(src, fs::path(tmp, "proj"))
  root <- fs::path(tmp, "proj")
  idx  <- fs::path(root, "index.qmd")
  meta <- readLines(idx)
  # Inject a bad degree
  meta <- gsub("degree: PhD", "degree: DPhil", meta)
  writeLines(meta, idx)
  res <- check_thesis(root, format = "console")
  expect_false(res$ok)
  rule_ids <- vapply(res$findings, `[[`, character(1), "rule_id")
  expect_true("degree-faculty-school" %in% rule_ids)
})

test_that("check_thesis respects the rules filter", {
  src  <- fixture_path("mini-project")
  tmp  <- withr::local_tempdir()
  fs::dir_copy(src, fs::path(tmp, "proj"))
  root <- fs::path(tmp, "proj")
  idx  <- fs::path(root, "index.qmd")
  meta <- readLines(idx)
  meta <- gsub("degree: PhD", "degree: DPhil", meta)
  writeLines(meta, idx)
  # Restrict to only the year-not-month rule -- should pass even though degree is bad
  res <- check_thesis(root, rules = "year-not-month", format = "console")
  expect_true(res$ok)
})

test_that("check_thesis fail_on='error' aborts when errors present", {
  src  <- fixture_path("mini-project")
  tmp  <- withr::local_tempdir()
  fs::dir_copy(src, fs::path(tmp, "proj"))
  root <- fs::path(tmp, "proj")
  idx  <- fs::path(root, "index.qmd")
  meta <- readLines(idx)
  meta <- gsub("degree: PhD", "degree: DPhil", meta)
  writeLines(meta, idx)
  expect_error(check_thesis(root, fail_on = "error"))
})

test_that("check_thesis fail_on='none' (default) does not abort", {
  src  <- fixture_path("mini-project")
  tmp  <- withr::local_tempdir()
  fs::dir_copy(src, fs::path(tmp, "proj"))
  root <- fs::path(tmp, "proj")
  idx  <- fs::path(root, "index.qmd")
  meta <- readLines(idx)
  meta <- gsub("degree: PhD", "degree: DPhil", meta)
  writeLines(meta, idx)
  expect_no_error(check_thesis(root, fail_on = "none"))
})

test_that("check_thesis applies journal-only rules when thesis_format is journal", {
  src  <- fixture_path("mini-project")
  tmp  <- withr::local_tempdir()
  fs::dir_copy(src, fs::path(tmp, "proj"))
  root <- fs::path(tmp, "proj")
  idx  <- fs::path(root, "index.qmd")
  meta <- readLines(idx)
  meta <- gsub("thesis_format: standard", "thesis_format: journal", meta)
  writeLines(meta, idx)
  # Mock-project doesn't have _extensions/uomthesis-journal/ so journal-rationale-present
  # returns NULL (graceful). journal-contribution-stmts may fire if there are body chapters
  # without contribution markers, but mini-project has no body chapters listed.
  res <- check_thesis(root, format = "console")
  # Just confirm it ran without crashing -- the exact findings depend on registry.
  expect_s3_class(res, "uomthesis_check_report")
})
