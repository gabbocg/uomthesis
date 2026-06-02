test_that("policy_info() returns the documented shape", {
  p <- policy_info()
  expect_s3_class(p, "uomthesis_policy_info")
  expect_named(p, c("version", "dated", "next_review", "source_url"))
  expect_equal(p$version, "12")
  expect_equal(format(p$dated, "%Y-%m"), "2026-03")
})

test_that("print.uomthesis_policy_info produces a one-screen summary", {
  expect_snapshot(print(policy_info()))
})
