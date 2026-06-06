# uomthesis

`uomthesis` is an R package that ships a Quarto template and compliance
tooling for PhD theses submitted to **Alliance Manchester Business
School (AMBS)** in the Faculty of Humanities at **The University of
Manchester**. It encodes the *Presentation of Theses Policy* – currently
version 12, March 2026 – so that an author can write in `.qmd`, render a
policy-compliant PDF + HTML, and continuously verify that the document
still meets the submission requirements.

## What this package gives you

- **A scaffolded Quarto project** with policy-compliant defaults baked
  in: margins, font, line spacing, declaration text, copyright
  statement, preliminary page order.
- **Two thesis formats** – `standard` and `journal` – both compliant
  with policy sections 8 and 13.
- **A word counter**
  ([`word_count()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/word_count.md))
  that counts “main text” per the policy’s definition (section 4.6
  fn. 1) and checks against the applicable cap.
- **A compliance validator**
  ([`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md))
  that runs ~17 source-phase rules against your project and produces
  console / markdown / JSON reports.
- **Five bundled citation styles** (Harvard, APA, Chicago author-date,
  MHRA, Vancouver) pinned by sha256.

## Installation

``` r

remotes::install_github("gabriel-cabrera-guz/uomthesis")
```

You will also need:

- **Quarto** (\>= 1.5)
- **A LaTeX engine** – LuaLaTeX recommended. If you don’t have one,
  install [TinyTeX](https://yihui.org/tinytex/) via
  `quarto install tinytex`.

## Quick start

``` r

library(uomthesis)

# Scaffold a new thesis project
create_thesis(
  "my-thesis",
  degree   = "PhD",
  author   = list(forename = "Jane",
                  middle_initial = "Q",
                  surname = "Doe"),
  title    = "An analysis of something important",
  year     = 2027,
  division = "MSM"
)

# In the new project, render with Quarto:
quarto::quarto_render()

# Then check compliance whenever you like:
word_count()       # main-text word count vs cap
check_thesis()     # full 17-rule validator
```

## What gets checked

[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)
runs a registry of rules covering:

- Required preliminary pages and their order (section 8.1)
- Declaration text and variant (section 8.1.f)
- Copyright statement – all four mandatory bullets (section 8.1.g)
- Font, line spacing, LaTeX engine compatibility (section 7.1)
- Word caps per degree x format (sections 4.6 and 13.11)
- Citation style and bibliography presence (section 7.2)
- For journal format: rationale chapter and per-chapter contribution
  declarations (section 13.10, 13.3)

See
[`vignette("compliance")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/compliance.md)
for the full rule list.

## Not in scope

- Word (.docx) output – PDF + HTML only.
- Other UoM faculties / schools – AMBS within Humanities only.
- Practice-based PhDs – policy section 14 differs too much by School for
  the validator to be reliable.
- Plagiarism / Turnitin-style detection.

## Documentation

Run
[`policy_info()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/policy_info.md)
for the policy version this build encodes:

``` r

library(uomthesis)
policy_info()
```

For a full walkthrough, see the vignettes:

- [`vignette("getting-started")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/getting-started.md)
- [`vignette("journal-format")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/journal-format.md)
- [`vignette("compliance")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/compliance.md)
- [`vignette("citation-styles")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/citation-styles.md)

## Contributing

Issues and pull requests are welcome on
[GitHub](https://github.com/gabriel-cabrera-guz/uomthesis).

## License

MIT (c) Gabriel Cabrera.
