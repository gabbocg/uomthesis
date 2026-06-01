# Helpers for locating test fixtures inside the package tree.
fixture_path <- function(...) {
  testthat::test_path("fixtures", ...)
}
