test_that("internal constructor and validator are not exported", {
  exports <- getNamespaceExports("xplus")

  expect_false("new_xplus" %in% exports)
  expect_false("validate_xplus" %in% exports)
})
