# Getting started with uomthesis

## What uomthesis does

`uomthesis` gives PhD students at Alliance Manchester Business School
(AMBS), Faculty of Humanities, The University of Manchester, a
Quarto-based writing environment that is policy-compliant from day one.
It scaffolds a complete project – two rendering formats (standard and
journal), all required preliminary pages, correct margins and fonts –
and provides a word counter and a compliance validator so you can catch
problems early rather than at submission.

## Install

``` r

remotes::install_github("gabriel-cabrera-guz/uomthesis")
```

You also need:

- **Quarto** \>= 1.5 (download from <https://quarto.org/>)
- **LuaLaTeX** – the recommended PDF engine. The easiest way to get it
  is via TinyTeX:

``` r

quarto::quarto_add_extension("quarto install tinytex")
# or from R:
# tinytex::install_tinytex()
```

## Scaffold a project

[`create_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/create_thesis.md)
writes a ready-to-render project into a new directory.

``` r

library(uomthesis)

create_thesis(
  "my-thesis",
  degree         = "PhD",
  author         = list(forename       = "Jane",
                        middle_initial = "Q",
                        surname        = "Doe"),
  title          = "An analysis of something important",
  year           = 2027,
  division       = "MSM",
  format         = "standard",    # or "journal"
  reference_style = "harvard-manchester"
)
```

The function creates a `my-thesis/` directory and prints a summary of
what was written.

## Tour of the scaffolded project

After running
[`create_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/create_thesis.md),
your project contains:

| File / directory | Purpose |
|----|----|
| `_quarto.yml` | Book-level configuration: title, author, PDF engine, CSL, bibliography |
| `index.qmd` | Front matter: `uomthesis:` metadata YAML block + abstract |
| `chapters/01-introduction.qmd` | First body chapter (rename and copy as needed) |
| `references.bib` | BibTeX bibliography |
| `_extensions/uomthesis-standard/` | The Quarto extension that drives rendering |
| `_extensions/uomthesis-standard/partials/` | LaTeX partials for title page, declaration, copyright |

For a journal-format project the extension directory is
`_extensions/uomthesis-journal/` and there is an additional
`chapters/00-rationale.qmd`.

## Write your content

Edit `index.qmd` to fill in your abstract. The `uomthesis:` YAML block
at the top of `index.qmd` holds your thesis metadata:

``` yaml
uomthesis:
  degree: PhD
  author:
    forename: Jane
    middle_initial: Q
    surname: Doe
  title: "An analysis of something important"
  year: 2027
  division: MSM
  faculty: Humanities
  school: "Alliance Manchester Business School"
  thesis_format: standard
  mainfont: "TeX Gyre Termes"
  linestretch: 1.5
```

Add chapters by creating new `.qmd` files under `chapters/` and listing
them in `_quarto.yml` under `book.chapters`. Place your BibTeX entries
in `references.bib` and cite them with `[@key]` syntax.

## Render

From R, or from the terminal inside your project directory:

``` r

quarto::quarto_render()
```

This produces a PDF (via LuaLaTeX) and an HTML version. Both are written
to the `_book/` directory. Open `_book/index.html` in a browser to
preview the HTML, or `_book/my-thesis.pdf` to view the PDF.

## Check compliance

### Word count

[`word_count()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/word_count.md)
counts main-text words according to the policy definition (section 4.6
fn. 1: preliminary pages, bibliography, appendices, and footnotes are
excluded) and reports the count against the applicable cap.

``` r

word_count()          # run from within the project directory
```

### Full compliance check

[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)
runs the full source-phase rule registry and reports findings:

``` r

check_thesis()                              # console output (default)
check_thesis(".", format = "markdown")     # writes check-report.md
check_thesis(".", format = "json")         # returns a JSON string
```

A finding is either an **error** (must fix before submission) or a
**warning** (should investigate). Run
[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)
regularly as you write, not just at the end.

## Where to next

- [`vignette("journal-format")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/journal-format.md)
  – if you are writing a journal-format thesis, read this before you
  start.
- [`vignette("compliance")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/compliance.md)
  – full list of the 19 rules, what each checks, and how to fix
  findings.
- [`vignette("citation-styles")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/citation-styles.md)
  – how to choose, switch, or bring your own citation style.
