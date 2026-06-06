# dev/regenerate_fixtures.R
# Regenerate the compliance fixtures from scratch.
# Run after the scaffolder or rules change in a way that affects fixture content.

library(uomthesis)
library(fs)

fixtures_root <- "tests/testthat/fixtures"

# 1. compliant-standard
dst <- file.path(fixtures_root, "compliant-standard")
if (dir.exists(dst)) unlink(dst, recursive = TRUE)
create_thesis(
  dst, format = "standard", degree = "PhD",
  author = list(forename = "Jane", middle_initial = "Q", surname = "Doe"),
  title = "Compliance fixture (standard)",
  year = 2027, division = "MSM", open = FALSE
)

# 2. compliant-journal
dst <- file.path(fixtures_root, "compliant-journal")
if (dir.exists(dst)) unlink(dst, recursive = TRUE)
create_thesis(
  dst, format = "journal", degree = "PhD",
  author = list(forename = "Jane", middle_initial = "Q", surname = "Doe"),
  title = "Compliance fixture (journal)",
  year = 2027, division = "MSM", open = FALSE
)

# 3. noncompliant-missing-cr (copyright chapter file reduced to a stub)
src <- file.path(fixtures_root, "compliant-standard")
dst <- file.path(fixtures_root, "noncompliant-missing-cr")
if (dir.exists(dst)) unlink(dst, recursive = TRUE)
dir_copy(src, dst)
writeLines(
  c("---", "title: \"Copyright Statement\"", "unnumbered: true", "---", "",
    "(All four policy-mandated bullets have been removed for testing.)"),
  file.path(dst, "chapters/00-copyright.qmd")
)

# 4. noncompliant-altered-decl (declaration chapter file paraphrased)
dst <- file.path(fixtures_root, "noncompliant-altered-decl")
if (dir.exists(dst)) unlink(dst, recursive = TRUE)
dir_copy(src, dst)
writeLines(
  c("---", "title: \"Declaration of Originality\"", "unnumbered: true", "---", "",
    "I hereby declare that all the work in this thesis is original",
    "and entirely my own."),
  file.path(dst, "chapters/00-declaration.qmd")
)

# 5. noncompliant-roman (illegal linespacing in index.qmd YAML)
dst <- file.path(fixtures_root, "noncompliant-roman")
if (dir.exists(dst)) unlink(dst, recursive = TRUE)
dir_copy(src, dst)
idx <- file.path(dst, "index.qmd")
body <- readLines(idx)
body <- sub("linestretch: 1.5", "linestretch: 1.0", body)
writeLines(body, idx)

cat("All five fixtures regenerated under", fixtures_root, "\n")
