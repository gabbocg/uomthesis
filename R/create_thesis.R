#' Scaffold a new uomthesis project
#'
#' Creates a directory tree containing a Quarto project (`_quarto.yml`,
#' `index.qmd`, chapter stubs), copies the appropriate Quarto extension
#' (standard or journal) and a chosen CSL file into the project's
#' `_extensions/` directory, and substitutes user-supplied metadata
#' into the scaffolded `index.qmd`.
#'
#' @param path Path to the new project directory.
#' @param format `"standard"` or `"journal"`.
#' @param degree One of the degrees in the policy allowed set.
#' @param faculty Faculty name. Default: `"Humanities"`.
#' @param school School name. Default: `"Alliance Manchester Business School"`.
#' @param division AMBS division code: `"A&F"` | `"IMP"` | `"MSM"` | `"PMO"`, or `NULL`.
#' @param author Named list with components `forename`, `middle_initial`,
#'   `surname`, `native_name` (optional). If `NULL`, placeholders are used.
#' @param title Thesis title. If `NULL`, a placeholder is used.
#' @param year Year of submission (integer). Defaults to current year.
#' @param reference_style One of `list_csl()$name`.
#' @param engine `"lualatex"` | `"xelatex"` | `"pdflatex"`.
#' @param mainfont One of the policy-allowed fonts.
#' @param list_of_publications For journal format: if `TRUE` (default for
#'   journal), a `chapters/00-publications.qmd` page is scaffolded and listed
#'   in `_quarto.yml`. Set to `FALSE` if you have no papers to list yet --
#'   the page is omitted from both the directory and the book chapters. Has
#'   no effect for `format = "standard"`.
#' @param force If `TRUE`, allow `path` to exist as long as it is empty.
#' @param open If `TRUE` and RStudio is available, open the new project.
#' @return Invisible path to the created project.
#' @export
#' @importFrom rlang `%||%`
create_thesis <- function(path,
                          format = c("standard", "journal"),
                          degree = "PhD",
                          faculty = "Humanities",
                          school = "Alliance Manchester Business School",
                          division = NULL,
                          author = NULL,
                          title = NULL,
                          year = NULL,
                          reference_style = c("harvard-manchester", "apa",
                                              "chicago-author-date", "mhra",
                                              "vancouver"),
                          engine = c("lualatex", "xelatex", "pdflatex"),
                          mainfont = "Times New Roman",
                          list_of_publications = NULL,
                          force = FALSE,
                          open = rlang::is_interactive()) {
  format          <- match.arg(format)
  engine          <- match.arg(engine)
  reference_style <- match.arg(reference_style)
  p <- policy_constants()

  # Validate font
  if (!mainfont %in% p$allowed_fonts) {
    cli::cli_abort(
      c("{.val {mainfont}} is not in the allowed font list.",
        i = paste0("Allowed: ", paste(p$allowed_fonts, collapse = ", "), ".")),
      class = "uomthesis_invalid_font"
    )
  }
  if (engine == "pdflatex" && !mainfont %in% p$pdflatex_safe_fonts) {
    cli::cli_abort(
      c("{.val {mainfont}} is not safe under pdflatex.",
        i = paste0("Use lualatex or xelatex, or pick from: ",
                   paste(p$pdflatex_safe_fonts, collapse = ", "), ".")),
      class = "uomthesis_engine_font_mismatch"
    )
  }
  if (!degree %in% p$allowed_degrees) {
    cli::cli_abort(
      "Degree {.val {degree}} not in allowed set.",
      class = "uomthesis_invalid_degree"
    )
  }

  # Validate path
  path <- normalizePath(path, mustWork = FALSE)
  if (file.exists(path)) {
    if (!force) {
      cli::cli_abort(
        c("{.path {path}} already exists.",
          i = "Pass {.code force = TRUE} to use an empty existing directory."),
        class = "uomthesis_path_exists"
      )
    }
    if (length(list.files(path)) > 0) {
      cli::cli_abort(
        "{.path {path}} is not empty.",
        class = "uomthesis_path_not_empty"
      )
    }
  } else {
    fs::dir_create(path)
  }

  # Copy skeleton
  skel <- system.file(
    if (format == "standard") "skeleton" else "skeleton-journal",
    package = "uomthesis"
  )
  if (!nzchar(skel)) {
    cli::cli_abort("Skeleton not found in installed package. Reinstall {.pkg uomthesis}.")
  }
  for (f in list.files(skel, recursive = TRUE, all.files = TRUE, no.. = TRUE)) {
    src  <- file.path(skel, f)
    dest <- file.path(path, f)
    fs::dir_create(dirname(dest))
    fs::file_copy(src, dest, overwrite = TRUE)
  }

  # Copy extension
  ext_src <- system.file(
    file.path("quarto", "_extensions", paste0("uomthesis-", format)),
    package = "uomthesis"
  )
  if (!nzchar(ext_src)) {
    cli::cli_abort("Quarto extension not found in installed package.")
  }
  ext_dest <- file.path(path, "_extensions", paste0("uomthesis-", format))
  fs::dir_create(ext_dest)
  for (f in list.files(ext_src, recursive = TRUE, all.files = TRUE, no.. = TRUE)) {
    src  <- file.path(ext_src, f)
    dest <- file.path(ext_dest, f)
    fs::dir_create(dirname(dest))
    fs::file_copy(src, dest, overwrite = TRUE)
  }

  # Also copy _shared/ alongside (so symlinks resolve)
  shared_src <- system.file("quarto/_extensions/_shared", package = "uomthesis")
  if (nzchar(shared_src)) {
    shared_dest <- file.path(path, "_extensions", "_shared")
    fs::dir_create(shared_dest)
    for (f in list.files(shared_src, recursive = TRUE, all.files = TRUE, no.. = TRUE)) {
      src  <- file.path(shared_src, f)
      dest <- file.path(shared_dest, f)
      fs::dir_create(dirname(dest))
      fs::file_copy(src, dest, overwrite = TRUE)
    }
  }

  # Copy the requested CSL into the extension's csl/ dir
  csl_dir <- file.path(ext_dest, "csl")
  fs::dir_create(csl_dir)
  copy_csl(reference_style, to = csl_dir)

  # Substitute mustache placeholders in index.qmd and _quarto.yml
  substitute_skeleton(
    path,
    title           = title %||% "Your thesis title",
    author          = author,
    degree          = degree,
    faculty         = faculty,
    school          = school,
    division        = division %||% "",
    year            = year %||% as.integer(format(Sys.Date(), "%Y")),
    reference_style = reference_style,
    engine          = engine,
    mainfont        = mainfont,
    thesis_format   = format
  )

  # Optional List of Publications page (journal format only). The default is
  # to include it; the user can set list_of_publications = FALSE if they
  # have no published or in-press papers yet.
  if (is.null(list_of_publications)) {
    list_of_publications <- (format == "journal")
  }
  if (format == "journal" && !isTRUE(list_of_publications)) {
    pubs_file <- file.path(path, "chapters", "00-publications.qmd")
    if (file.exists(pubs_file)) fs::file_delete(pubs_file)
    qy_path <- file.path(path, "_quarto.yml")
    if (file.exists(qy_path)) {
      qy_lines <- readLines(qy_path, warn = FALSE)
      qy_lines <- qy_lines[!grepl("00-publications.qmd", qy_lines)]
      writeLines(qy_lines, qy_path)
    }
  }

  if (isTRUE(open) &&
      requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    rstudioapi::openProject(path)
  } else {
    cli::cli_alert_success("Created uomthesis project at {.path {path}}.")
    cli::cli_alert_info(
      "Next: open {.file index.qmd}, then {.run quarto::quarto_render()}."
    )
  }
  invisible(path)
}

# Internal: substitute placeholders in scaffolded index.qmd + _quarto.yml.
# Uses fixed (literal) string substitution to avoid regex surprises.
substitute_skeleton <- function(path, title, author, degree, faculty, school,
                                division, year, reference_style, engine,
                                mainfont, thesis_format) {
  files <- c(file.path(path, "index.qmd"), file.path(path, "_quarto.yml"))
  for (f in files) {
    if (!file.exists(f)) next
    body <- readLines(f, warn = FALSE, encoding = "UTF-8")
    body <- gsub("{{title}}",           title,                             body, fixed = TRUE)
    body <- gsub("{{forename}}",        author$forename %||% "Forename",   body, fixed = TRUE)
    body <- gsub("{{middle_initial}}",  author$middle_initial %||% "M",    body, fixed = TRUE)
    body <- gsub("{{surname}}",         author$surname %||% "Surname",     body, fixed = TRUE)
    body <- gsub("{{native_name}}",     author$native_name %||% "",        body, fixed = TRUE)
    body <- gsub("{{degree}}",          degree,                            body, fixed = TRUE)
    body <- gsub("{{faculty}}",         faculty,                           body, fixed = TRUE)
    body <- gsub("{{school}}",          school,                            body, fixed = TRUE)
    body <- gsub("{{division}}",        division,                          body, fixed = TRUE)
    body <- gsub("{{year}}",            as.character(year),                body, fixed = TRUE)
    body <- gsub("{{thesis_format}}",   thesis_format,                     body, fixed = TRUE)
    body <- gsub("{{reference_style}}", reference_style,                   body, fixed = TRUE)
    body <- gsub("{{engine}}",          engine,                            body, fixed = TRUE)
    body <- gsub("{{mainfont}}",        mainfont,                          body, fixed = TRUE)
    writeLines(body, f)
  }
}
