# dev/refresh_csl.R
# Re-download bundled CSL files and refresh inst/csl/SOURCES.yml.
# Run interactively; commits are made by hand.
#
# sha256 is computed via digest::digest(file = path, algo = "sha256") if
# openssl is not available, which produces the same hex digest.

sources <- list(
  list(
    name = "harvard-manchester",
    url  = "https://raw.githubusercontent.com/citation-style-language/styles/master/harvard-cite-them-right.csl"
  ),
  list(
    name = "apa",
    url  = "https://raw.githubusercontent.com/citation-style-language/styles/master/apa.csl"
  ),
  list(
    name = "chicago-author-date",
    url  = "https://raw.githubusercontent.com/citation-style-language/styles/master/chicago-author-date.csl"
  ),
  list(
    name = "mhra",
    url  = "https://raw.githubusercontent.com/citation-style-language/styles/master/mhra-notes.csl"
  ),
  list(
    name = "vancouver",
    url  = "https://raw.githubusercontent.com/citation-style-language/styles/master/elsevier-vancouver.csl"
  )
)

today <- format(Sys.Date(), "%Y-%m-%d")
manifest <- lapply(sources, function(s) {
  dest <- file.path("inst", "csl", paste0(s$name, ".csl"))
  download.file(s$url, dest, mode = "wb", quiet = TRUE)
  # Use digest if openssl is not installed
  sha256 <- if (requireNamespace("openssl", quietly = TRUE)) {
    raw <- readBin(dest, "raw", n = file.info(dest)$size)
    paste(format(openssl::sha256(raw)), collapse = "")
  } else {
    digest::digest(file = dest, algo = "sha256")
  }
  list(name = s$name, url = s$url,
       retrieved = today,
       sha256 = sha256)
})
yaml::write_yaml(manifest, "inst/csl/SOURCES.yml")
