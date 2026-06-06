# uomthesis

**Author:** [Gabriel Cabrera](https://github.com/gabbocg)  
**License:** [MIT](https://opensource.org/licenses/MIT) + file
[LICENSE](https://gabriel-cabrera-guz.github.io/uomthesis/LICENSE)

## Overview

**uomthesis** is an R package that ships a Quarto template and a
compliance validator for PhD theses submitted to Alliance Manchester
Business School (AMBS) in the Faculty of Humanities at The University of
Manchester.
[`create_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/create_thesis.md)
scaffolds a policy-compliant Quarto book project in either a monograph
(`standard`) or journal-format (`journal`, 1–10 constituent papers)
layout, with margins, font, line spacing, declaration, copyright
statement, and preliminary page order baked in per the *Presentation of
Theses Policy*.
[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)
runs 18 source-phase rules against the project and reports findings as
console, markdown, or JSON.
[`word_count()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/word_count.md)
counts the main text per the policy definition (section 4.6 fn. 1) and
checks it against the applicable cap. Five citation styles ship bundled
(Harvard-Manchester, APA, Chicago author-date, MHRA, Vancouver), pinned
by sha256.

## Installation

``` r

# Install from GitHub (not yet on CRAN)
# install.packages("devtools")
devtools::install_github("gabbocg/uomthesis")
```

You will also need:

- **Quarto** (\>= 1.5)
- **A LaTeX engine** – LuaLaTeX recommended. If you don’t have one,
  install [TinyTeX](https://yihui.org/tinytex/) via
  `quarto install tinytex`.

## Functions

### Scaffolding and rendering

| Function | Purpose |
|----|----|
| [`create_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/create_thesis.md) | Scaffold a new Quarto project (standard or journal format) |
| [`policy_info()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/policy_info.md) | Report the *Presentation of Theses Policy* version this build targets |

### Compliance

| Function | Purpose | Policy reference |
|----|----|----|
| [`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md) | Run all 18 source-phase rules and return a report | sections 7, 8, 13 |
| [`validate_metadata()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/validate_metadata.md) | Lint the `uomthesis:` YAML block in `index.qmd` | section 8 |
| [`word_count()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/word_count.md) | Count main-text words vs the applicable cap | section 4.6 fn. 1 |

### Citation styles

| Function | Purpose |
|----|----|
| [`list_csl()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/list_csl.md) | List the five bundled CSL styles with sha256 hashes |
| [`copy_csl()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/copy_csl.md) | Copy one of the bundled styles into a project |

## Usage

### Quick start

``` r

library(uomthesis)

# Scaffold a journal-format PhD thesis with 3 constituent papers
create_thesis(
  path     = "my-thesis",
  format   = "journal",
  degree   = "PhD",
  division = "A&F",
  author   = list(forename = "Gabriel", surname = "Cabrera"),
  title    = "Three essays on something interesting",
  year     = 2026
)

# In the new project, render with Quarto
setwd("my-thesis")
quarto::quarto_render()

# Then check compliance whenever you like
check_thesis(".")
#> ── uomthesis::check_thesis() - journal ─────────────────────────────────────────
#> ✔ 18 rules passed
#> ✖ 0 errors
#> ! 0 warnings
```

### Scaffolding options

``` r

# Monograph (standard) thesis
create_thesis("monograph-thesis", format = "standard", ...)

# Two-paper DBA, no list of publications yet
create_thesis(
  path                 = "dba-thesis",
  format               = "journal",
  degree               = "DBA",
  num_papers           = 2L,
  list_of_publications = FALSE,
  ...
)

# Five-paper PhD using APA citation style and xelatex
create_thesis(
  path            = "five-paper-thesis",
  format          = "journal",
  num_papers      = 5L,
  reference_style = "apa",
  engine          = "xelatex",
  ...
)
```

`num_papers` (1–10) controls how many constituent paper chapters the
journal-format skeleton scaffolds. Paper 1 is a rich demo chapter that
exercises citations, equations, tables, figures, and per-paper
appendices; Papers 2..N are bare structural templates.

### Word count

``` r

word_count(".")
#> Main-text word count
#> ----------------------------------------
#>  Count             68,432
#>  Cap (PhD)         80,000
#>  Status            within cap
```

The count excludes preliminaries, references, and appendices per policy
section 4.6 fn. 1. The cap is degree × format-specific (PhD standard:
80,000; PhD journal: 80,000; MPhil: 60,000; DBA: 60,000; etc.).

### Compliance check

``` r

check_thesis(".", format = "console")
#> ── uomthesis::check_thesis() - journal ─────────────────────────────────────────
#> ✔ 18 rules passed
#> ✖ 0 errors
#> ! 0 warnings

# JSON output for CI pipelines
check_thesis(".", format = "json")
```

[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)
runs a registry of 18 source-phase rules covering: required preliminary
pages and order (section 8.1), declaration text and variant (8.1.f),
copyright statement – all four mandatory bullets (8.1.g), font / line
spacing / LaTeX engine compatibility (7.1), word caps per degree ×
format (4.6, 13.11), citation style and bibliography presence (7.2), and
journal-format-specific rules including rationale chapter (13.10) and
contribution declarations (13.3).

### Policy version

``` r

policy_info()
#> uomthesis is built against the University of Manchester
#> Presentation of Theses Policy v12 (March 2026).
#> Next policy review: November 2028.
```

### Citation styles

``` r

list_csl()
#>                  name                          file        sha256
#> 1  harvard-manchester   harvard-manchester.csl  a3f2...891b
#> 2                 apa                  apa.csl  7c4d...3e02
#> 3 chicago-author-date  chicago-author-date.csl  1f8e...c5d9
#> 4                mhra                 mhra.csl  92a1...7f6b
#> 5          vancouver            vancouver.csl  4b3e...0d27

copy_csl("harvard-manchester", to = "_extensions/uomthesis-journal/csl/")
```

## Documentation

For a full walkthrough, see the vignettes:

- [`vignette("getting-started")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/getting-started.md)
  – scaffold, render, check
- [`vignette("journal-format")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/journal-format.md)
  – conventions for paper-based theses
- [`vignette("compliance")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/compliance.md)
  – the full 18-rule list and the policy passages each one encodes
- [`vignette("citation-styles")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/citation-styles.md)
  – choosing and applying a CSL

The full reference is also available at the [pkgdown
site](https://gabbocg.github.io/uomthesis/).

## Not in scope

- Word (`.docx`) output – PDF + HTML only
- Other UoM faculties or schools – AMBS within Humanities only
- Practice-based PhDs – policy section 14 differs too much by School for
  the validator to be reliable
- Plagiarism / Turnitin-style detection

## Getting help

If you encounter a bug, please file an issue with a minimal reproducible
example on [GitHub](https://github.com/gabbocg/uomthesis/issues). For
questions, email <gabriel.cabreraguzman@postgrad.manchester.ac.uk>.

## References

- The University of Manchester. *Presentation of Theses Policy*. Version
  12, March 2026.
- The University of Manchester. *Journal Format Theses: Guiding
  Principles*. Faculty of Humanities.
