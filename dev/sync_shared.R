# dev/sync_shared.R
# Verify and (if needed) recreate symlinks from each extension's partials
# into _shared/. Use on Windows or in dev environments where symlinks
# need to be re-created. On macOS / Linux this is a no-op if the symlinks
# are already valid.

shared <- "inst/quarto/_extensions/_shared"
targets <- list(
  c("uomthesis-standard/partials/title-page.tex",      "title-page.tex"),
  c("uomthesis-standard/partials/declaration.tex",     "declaration.tex"),
  c("uomthesis-standard/partials/copyright.tex",       "copyright.tex"),
  c("uomthesis-standard/partials/ai-disclosure.tex",   "ai-disclosure.tex"),
  c("uomthesis-standard/theme/uomthesis.scss",         "theme.scss"),
  c("uomthesis-journal/partials/title-page.tex",       "title-page.tex"),
  c("uomthesis-journal/partials/declaration.tex",      "declaration.tex"),
  c("uomthesis-journal/partials/copyright.tex",        "copyright.tex"),
  c("uomthesis-journal/partials/ai-disclosure.tex",    "ai-disclosure.tex"),
  c("uomthesis-journal/theme/uomthesis.scss",          "theme.scss")
)
for (t in targets) {
  link <- file.path("inst/quarto/_extensions", t[[1]])
  src  <- file.path(shared, t[[2]])
  parent <- dirname(link)
  if (!dir.exists(parent)) dir.create(parent, recursive = TRUE)
  if (file.exists(link)) {
    is_link <- Sys.readlink(link) != ""
    if (is_link) next  # already a valid symlink
    file.remove(link)
  }
  ok <- file.symlink(normalizePath(src), link)
  if (!ok) {
    message("symlink failed (probably Windows); falling back to copy.")
    file.copy(src, link, overwrite = TRUE)
  } else {
    message("symlinked: ", src, " -> ", link)
  }
}
