test_that("rule_registry returns a list of properly-shaped rules", {
  rules <- rule_registry()
  expect_true(length(rules) >= 4)
  for (r in rules) {
    expect_named(r, c("id", "policy_ref", "phase", "formats",
                      "severity", "check", "rationale"),
                 ignore.order = TRUE)
    expect_true(r$phase %in% c("source", "pdf"))
    expect_true(r$severity %in% c("error", "warning"))
    expect_true(is.function(r$check))
  }
})

test_that("rule_registry has unique IDs", {
  ids <- vapply(rule_registry(), `[[`, character(1), "id")
  expect_false(any(duplicated(ids)))
})

test_that("get_rule returns the requested rule by id", {
  r <- get_rule("metadata-complete")
  expect_equal(r$id, "metadata-complete")
})

test_that("metadata-complete rule fires for missing surname", {
  rule <- get_rule("metadata-complete")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$candidate$surname <- NULL
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
  expect_equal(finding$rule_id, "metadata-complete")
  expect_equal(finding$severity, "error")
})

test_that("metadata-complete passes on full mini-project metadata", {
  rule <- get_rule("metadata-complete")
  ctx  <- build_ctx(fixture_path("mini-project"))
  expect_null(rule$check(ctx))
})

test_that("degree-faculty-school fires on out-of-set degree", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$degree <- "DPhil"
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
  expect_equal(finding$rule_id, "degree-faculty-school")
})

test_that("degree-faculty-school fires on out-of-set faculty", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$faculty <- "Engineering"
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
})

test_that("degree-faculty-school fires on out-of-set school", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$school <- "Hogwarts"
  finding <- rule$check(ctx)
  expect_false(is.null(finding))
})

test_that("degree-faculty-school passes on valid trio", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  expect_null(rule$check(ctx))
})

test_that("year-not-month fires when year is out of plausible range", {
  rule <- get_rule("year-not-month")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$year <- 1850
  expect_false(is.null(rule$check(ctx)))
  ctx$metadata$year <- 2150
  expect_false(is.null(rule$check(ctx)))
  ctx$metadata$year <- "May 2027"
  expect_false(is.null(rule$check(ctx)))
})

test_that("year-not-month passes on plausible integer year", {
  rule <- get_rule("year-not-month")
  ctx  <- build_ctx(fixture_path("mini-project"))
  expect_null(rule$check(ctx))
})

test_that("thesis-format fires on non-standard/journal value", {
  rule <- get_rule("thesis-format")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$thesis_format <- "practice-based"
  expect_false(is.null(rule$check(ctx)))
})

test_that("thesis-format passes for 'standard'", {
  rule <- get_rule("thesis-format")
  ctx  <- build_ctx(fixture_path("mini-project"))
  expect_null(rule$check(ctx))
})

test_that("degree-faculty-school accumulates findings for multiple wrong fields", {
  rule <- get_rule("degree-faculty-school")
  ctx  <- build_ctx(fixture_path("mini-project"))
  ctx$metadata$degree  <- "DPhil"
  ctx$metadata$faculty <- "Engineering"
  ctx$metadata$school  <- "Hogwarts"
  result <- rule$check(ctx)
  expect_type(result, "list")
  # The result is a list of three findings — confirm by checking it's a list-of-lists
  expect_true(length(result) == 3)
  # Each element should look like a finding (have $rule_id)
  for (f in result) expect_equal(f$rule_id, "degree-faculty-school")
})

test_that("get_rule errors with class uomthesis_unknown_rule on unknown id", {
  expect_error(get_rule("does-not-exist"), class = "uomthesis_unknown_rule")
})
