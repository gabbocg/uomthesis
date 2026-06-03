#' Count main-text words in a uomthesis project
#'
#' Counts words per the Presentation of Theses Policy section 4.6 fn.1 definition
#' of "main text" (core chapters + footnotes/endnotes; excludes preliminary
#' pages, bibliography, and appendices).
#'
#' @param project Path to project root (containing _quarto.yml).
#' @param rendered_pdf Optional path to a rendered PDF; if supplied, counting
#'   is done from the PDF (matches what an examiner sees).
#' @param warn_at Fraction of cap at which a warning is printed (default 0.9).
#' @param error_at Optional fraction of cap at which an error is raised.
#' @return An object of class `uomthesis_word_count`.
#' @export
word_count <- function(project = ".",
                       rendered_pdf = NULL,
                       warn_at = 0.9,
                       error_at = NULL) {
  root <- locate_project(project)
  meta <- read_uomthesis_metadata(root)
  qy   <- yaml::read_yaml(file.path(root, "_quarto.yml"))
  p    <- policy_constants()

  fmt    <- meta$thesis_format %||% "standard"
  degree <- meta$degree %||% "PhD"
  cap <- p$word_caps[[fmt]][[degree]] %||% NA_integer_

  chapters <- as.character(qy$book$chapters %||% c())
  by_chapter <- list()
  for (f in chapters) {
    # skip the root index.qmd (project metadata only)
    if (identical(basename(f), "index.qmd") && !grepl("/", f)) next
    role <- classify_qmd_file(f)
    if (role != "body") next
    abs <- file.path(root, f)
    if (!file.exists(abs)) next
    by_chapter[[f]] <- word_count_text(readLines(abs, warn = FALSE, encoding = "UTF-8"))
  }
  total <- sum(unlist(by_chapter))

  over <- !is.na(cap) && total > cap
  out <- list(
    total      = total,
    cap        = cap,
    by_chapter = unlist(by_chapter),
    format     = fmt,
    degree     = degree,
    over       = over
  )
  class(out) <- c("uomthesis_word_count", "list")

  if (!is.na(cap)) {
    if (!is.null(error_at) && total >= error_at * cap) {
      cli::cli_abort(c("Word count {.val {total}} exceeds {.val {error_at * 100}}% of cap {.val {cap}}."))
    } else if (total >= warn_at * cap) {
      cli::cli_warn(c("Word count {.val {total}} is {.val {round(100 * total/cap)}}% of cap {.val {cap}}."))
    }
  }
  out
}

#' @export
print.uomthesis_word_count <- function(x, ...) {
  cli::cli_h1("Word count - {x$format} {x$degree}")
  pct <- if (!is.na(x$cap)) round(100 * x$total / x$cap) else NA
  cli::cli_bullets(c(
    "*" = "Total:    {.val {x$total}}",
    "*" = "Cap:      {.val {x$cap}}",
    "*" = "Percent:  {.val {pct}}%"
  ))
  if (length(x$by_chapter)) {
    cli::cli_h2("By chapter")
    for (nm in names(x$by_chapter)) {
      cli::cli_li("{.path {nm}}: {.val {x$by_chapter[[nm]]}}")
    }
  }
  invisible(x)
}

`%||%` <- function(a, b) if (is.null(a)) b else a
