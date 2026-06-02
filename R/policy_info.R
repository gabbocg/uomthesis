#' Information about the Presentation of Theses Policy this package version targets
#'
#' Returns the policy version number, dated, next review date, and source URL.
#' Use this to confirm whether a new policy revision is available.
#'
#' @return An object of class `uomthesis_policy_info` (a named list).
#' @export
#' @examples
#' policy_info()
policy_info <- function() {
  p <- policy_constants()
  out <- list(
    version     = p$version,
    dated       = p$dated,
    next_review = p$next_review,
    source_url  = p$source_url
  )
  class(out) <- c("uomthesis_policy_info", "list")
  out
}

#' @export
print.uomthesis_policy_info <- function(x, ...) {
  cli::cli_h1("Presentation of Theses Policy")
  cli::cli_bullets(c(
    "*" = "Version:       {.val {x$version}}",
    "*" = "Dated:         {.val {format(x$dated, '%B %Y')}}",
    "*" = "Next review:   {.val {format(x$next_review, '%B %Y')}}",
    "i" = "Source:        {.url {x$source_url}}"
  ))
  invisible(x)
}
