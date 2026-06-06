# Count main-text words in a uomthesis project

Counts words per the Presentation of Theses Policy section 4.6 fn.1
definition of "main text" (core chapters + footnotes/endnotes; excludes
preliminary pages, bibliography, and appendices).

## Usage

``` r
word_count(project = ".", rendered_pdf = NULL, warn_at = 0.9, error_at = NULL)
```

## Arguments

- project:

  Path to project root (containing \_quarto.yml).

- rendered_pdf:

  Optional path to a rendered PDF. **Not yet implemented** in v0.1 –
  supplying a value emits a warning and falls back to source-based
  counting. Will be honored in v0.2.

- warn_at:

  Fraction of cap at which a warning is printed (default 0.9).

- error_at:

  Optional fraction of cap at which an error is raised. Must be greater
  than `warn_at` if supplied.

## Value

An object of class `uomthesis_word_count`.
