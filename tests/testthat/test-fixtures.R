# End-to-end compliance fixture tests.
#
# Each test runs check_thesis() against a fixture project under
# tests/testthat/fixtures/ and asserts on the resulting ok flag and rule IDs.
# Re-generate fixtures with dev/regenerate_fixtures.R when the scaffolder
# or rules change.

# ---------------------------------------------------------------------------
# Compliant fixtures
# ---------------------------------------------------------------------------

test_that("ok-std fixture passes all source-phase rules", {
  res <- check_thesis(fixture_path("ok-std"), format = "console")
  expect_true(res$ok)
  expect_equal(length(res$findings), 0)
})

test_that("ok-journal fixture passes all source-phase rules", {
  res <- check_thesis(fixture_path("ok-journal"), format = "console")
  expect_true(res$ok)
  expect_equal(length(res$findings), 0)
})

# ---------------------------------------------------------------------------
# Noncompliant fixtures
# ---------------------------------------------------------------------------

test_that("bad-no-cr fires copyright-text rule (multiple findings)", {
  res <- check_thesis(fixture_path("bad-no-cr"), format = "console")
  expect_false(res$ok)
  rule_ids <- vapply(res$findings, `[[`, character(1), "rule_id")
  expect_true("copyright-text" %in% rule_ids)
  # Expect at least one finding — typically 4 (one per missing bullet)
  cr_findings <- sum(rule_ids == "copyright-text")
  expect_true(cr_findings >= 1)
})

test_that("bad-decl fires declaration-text rule", {
  res <- check_thesis(fixture_path("bad-decl"), format = "console")
  expect_false(res$ok)
  rule_ids <- vapply(res$findings, `[[`, character(1), "rule_id")
  expect_true("declaration-text" %in% rule_ids)
})

test_that("bad-roman fires linespacing-allowed rule", {
  res <- check_thesis(fixture_path("bad-roman"), format = "console")
  expect_false(res$ok)
  rule_ids <- vapply(res$findings, `[[`, character(1), "rule_id")
  expect_true("linespacing-allowed" %in% rule_ids)
})
