# Changelog

## uomthesis 0.1.0

First tagged release.

### Features

- [`create_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/create_thesis.md)
  – scaffold a new Quarto project for a PhD thesis at Alliance
  Manchester Business School. Supports `standard` and `journal` formats.
- [`word_count()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/word_count.md)
  – count main-text words against the applicable policy cap, per policy
  section 4.6 fn. 1.
- [`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)
  – run the source-phase compliance validator. Source-phase rules cover
  required metadata, title-page statement, declaration text, copyright
  statement, font/engine/spacing, prelim order, bibliography existence,
  and journal-format-specific rules. Console, markdown, and JSON output
  formats supported.
- [`validate_metadata()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/validate_metadata.md)
  – lint the `uomthesis:` YAML block without running the full check.
- [`policy_info()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/policy_info.md)
  – report the targeted *Presentation of Theses Policy* version.
- [`list_csl()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/list_csl.md)
  /
  [`copy_csl()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/copy_csl.md)
  – list and copy the bundled citation styles (Harvard, APA, Chicago
  author-date, MHRA, Vancouver).
- Quarto extensions `uomthesis-standard` and `uomthesis-journal`
  packaged with the R package – both produce a compliant PDF (LuaLaTeX)
  plus a companion HTML.

### Policy targeted

This build encodes *Presentation of Theses Policy* v12 (March 2026).
Next policy review: November 2028. Run
[`policy_info()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/policy_info.md)
to confirm.

### Not yet implemented

- PDF-phase validator rules (planned for 0.2).
- Word (`.docx`) output (out of scope).
- Practice-based theses (out of scope; School-specific).

### Acknowledgements

Built against the *Presentation of Theses Policy* and the *Journal
Format Theses Guiding Principles* of The University of Manchester.
Source: <https://documents.manchester.ac.uk/display.aspx?DocID=7420>.
