#' List bundled citation styles
#'
#' Returns a data frame describing the CSL files bundled with the package.
#' Each row corresponds to one style file in `inst/csl/`.
#'
#' @return A data.frame with one row per bundled CSL, columns:
#'   `name`, `url`, `retrieved`, `sha256`.
#' @export
#' @examples
#' list_csl()
list_csl <- function() {
  manifest_path <- system.file("csl", "SOURCES.yml", package = "uomthesis")
  if (!nzchar(manifest_path)) {
    cli::cli_abort("CSL manifest not found in installed package.")
  }
  m <- yaml::read_yaml(manifest_path)
  do.call(rbind, lapply(m, as.data.frame, stringsAsFactors = FALSE))
}

#' Copy a bundled CSL into a directory
#'
#' Copies one of the bundled citation style files into a destination directory,
#' creating the directory if it does not already exist.
#'
#' @param name One of the names from `list_csl()$name`.
#' @param to   Destination directory (created if missing).
#' @return Invisible path to the copied file.
#' @export
#' @examples
#' \dontrun{
#' copy_csl("apa", to = ".")
#' }
copy_csl <- function(name, to = ".") {
  styles <- list_csl()
  if (!name %in% styles$name) {
    cli::cli_abort(
      c("Unknown CSL {.val {name}}.",
        i = "Use {.code list_csl()$name} to see the bundled styles."),
      class = "uomthesis_unknown_csl"
    )
  }
  src <- system.file("csl", paste0(name, ".csl"), package = "uomthesis")
  fs::dir_create(to)
  dest <- fs::path(to, paste0(name, ".csl"))
  fs::file_copy(src, dest, overwrite = TRUE)
  invisible(as.character(dest))
}
