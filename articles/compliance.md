# Compliance validation

## Overview

[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)
runs a registry of source-phase validation rules against your Quarto
thesis project. Each rule maps to one or more sections of the
*Presentation of Theses Policy* (v12, March 2026). A finding is either
an **error** (the thesis will likely be rejected unless fixed) or a
**warning** (should be investigated; may be intentional).

Source-phase rules inspect `.qmd` files, `_quarto.yml`, and the
extension partials. A planned PDF-phase rule set (v0.2) will
additionally inspect the rendered document.

Run the validator from within your thesis project directory:

``` r

library(uomthesis)
check_thesis()
```

## The rule registry

The table below lists all 19 rules in registry order.

| ID                         | Policy ref | Severity | Formats |
|:---------------------------|:-----------|:---------|:--------|
| metadata-complete          | §8.1.b     | error    | both    |
| degree-faculty-school      | §8.1.b     | error    | both    |
| year-not-month             | §8.1.b     | error    | both    |
| thesis-format              | §4.6       | error    | both    |
| font-allowed               | §7.1       | error    | both    |
| font-engine-compat         | §7.1       | error    | both    |
| linespacing-allowed        | §7.1       | error    | both    |
| ai-disclosure-shape        | §9.1.d     | warning  | both    |
| english-language           | §6.1       | warning  | both    |
| title-page-statement       | §8.1.b     | error    | both    |
| declaration-text           | §8.1.f     | error    | both    |
| copyright-text             | §8.1.g     | error    | both    |
| copyright-author-match     | §8.1.g     | error    | both    |
| prelim-order               | §8.1       | error    | both    |
| abstract-one-page          | §8.1.e     | warning  | both    |
| csl-bundled-or-path-exists | §7.2       | error    | both    |
| bibliography-exists        | §7.2       | error    | both    |
| journal-rationale-present  | §13.10     | error    | journal |

### metadata-complete

**Policy section:** 8 / general submission requirements **Severity:**
error **Formats:** both

Checks that all required `uomthesis:` YAML fields are present and
non-empty in `index.qmd`: `degree`, `author` (with `forename` and
`surname`), `title`, `year`, `division`, `faculty`, `school`, and
`thesis_format`.

**How to fix:** Open `index.qmd` and ensure every field in the
`uomthesis:` block has a non-empty value. Use
[`validate_metadata()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/validate_metadata.md)
for a focused check on just the metadata block.

------------------------------------------------------------------------

### degree-faculty-school

**Policy section:** general submission **Severity:** error **Formats:**
both

Checks that `degree`, `faculty`, and `school` each belong to the allowed
sets. Supported degrees: PhD, MPhil, MD, EdD, DBA, EngD. Supported
faculty: Humanities. Supported school: Alliance Manchester Business
School.

**How to fix:** Verify the values in your `uomthesis:` block against the
allowed sets. If your degree is not listed, open a GitHub issue – the
registry is updated when the Doctoral Academy recognises new degree
types.

------------------------------------------------------------------------

### year-not-month

**Policy section:** general submission **Severity:** error **Formats:**
both

Checks that `year` is a plausible four-digit integer (2000–2100) and not
a month name or other non-year string.

**How to fix:** Set `year` to a numeric year such as `2027`, not a
string like `"March 2027"`.

------------------------------------------------------------------------

### thesis-format

**Policy section:** 13 **Severity:** error **Formats:** both

Checks that `thesis_format` is either `"standard"` or `"journal"`.

**How to fix:** Set `thesis_format` to `standard` or `journal` in the
`uomthesis:` block.

------------------------------------------------------------------------

### font-allowed

**Policy section:** 7.1 **Severity:** error **Formats:** both

Checks that `mainfont` is one of the policy-permitted typefaces. Run
[`policy_info()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/policy_info.md)
to see the current permitted list.

**How to fix:** Choose a permitted font. `TeX Gyre Termes` (a Times New
Roman equivalent) is the recommended default and is available in all
standard LaTeX distributions.

------------------------------------------------------------------------

### font-engine-compat

**Policy section:** 7.1 **Severity:** error **Formats:** both

Checks that the chosen `mainfont` is compatible with the configured PDF
engine. Some OpenType fonts require LuaLaTeX or XeLaTeX and cannot be
used with pdflatex.

**How to fix:** Either switch to LuaLaTeX (recommended) by setting
`pdf-engine: lualatex` in `_quarto.yml`, or choose a font that is
pdflatex-safe.

------------------------------------------------------------------------

### linespacing-allowed

**Policy section:** 7.1 **Severity:** error **Formats:** both

Checks that `linestretch` is 1.5 or 2.0 (the only values the policy
permits for main text). The field may be absent (the extension default
of 1.5 will be used).

**How to fix:** Set `linestretch` to `1.5` or `2.0`.

------------------------------------------------------------------------

### ai-disclosure-shape

**Policy section:** 9.1.d **Severity:** warning **Formats:** both

If `ai_disclosure.include` is `true`, checks that `ai_disclosure.tools`
is a non-empty list of tool names. A declaration without a tools list is
malformed.

**How to fix:** Either set `ai_disclosure.include: false` (if you did
not use AI tools) or populate `ai_disclosure.tools` with the names of
each tool used (e.g., `[ChatGPT-4o, GitHub Copilot]`).

------------------------------------------------------------------------

### english-language

**Policy section:** 6.1 **Severity:** warning **Formats:** both

If the `lang` key is set in `_quarto.yml` or `index.qmd`, checks that it
starts with `en`. Policy section 6.1 requires the thesis to be written
in UK English unless advance written approval has been obtained for
another language.

**How to fix:** If the warning is incorrect (you have approval for
another language), suppress this rule by passing
`rules = setdiff(uomthesis:::rule_ids(), "english-language")` to
[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md).
Otherwise set `lang: en-GB`.

------------------------------------------------------------------------

### title-page-statement

**Policy section:** 8.1.b **Severity:** error **Formats:** both

Checks that the title page partial
(`_extensions/uomthesis-*/partials/title-page.tex`) contains the
policy-mandated submission statement. Run
[`policy_info()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/policy_info.md)
to see the required text.

**How to fix:** Do not edit the title-page partial directly unless you
know what you are doing. If you have accidentally altered it, re-copy it
from the package:
`uomthesis:::install_partial("title-page.tex", format = "standard")`.

------------------------------------------------------------------------

### declaration-text

**Policy section:** 8.1.f **Severity:** error **Formats:** both

Checks that the declaration partial
(`_extensions/uomthesis-*/partials/declaration.tex`) contains one of the
two policy-mandated declaration texts verbatim. Run
[`policy_info()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/policy_info.md)
to see both variants.

**How to fix:** Do not paraphrase the declaration. Restore it from the
package partial if it has been altered.

------------------------------------------------------------------------

### copyright-text

**Policy section:** 8.1.g **Severity:** error **Formats:** both

Checks that the copyright partial contains all four mandatory bullet
points that policy section 8.1.g requires. Run
[`policy_info()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/policy_info.md)
to see the required text.

**How to fix:** Restore the copyright partial from the package template.
Do not remove or alter the mandatory bullets.

------------------------------------------------------------------------

### copyright-author-match

**Policy section:** 8.1.g **Severity:** error **Formats:** both

Checks that the author name in the copyright partial matches the
`author` metadata in `index.qmd`. A mismatch typically means the
copyright partial was copied from another candidate’s project without
being updated.

**How to fix:** Search the copyright partial for the previous author’s
name and replace it with your own name, or re-run
[`create_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/create_thesis.md)
in a fresh directory.

------------------------------------------------------------------------

### prelim-order

**Policy section:** 8.1 **Severity:** error **Formats:** both

Checks that the preliminary pages appear in the order mandated by policy
section 8.1 (title, abstract, declaration, copyright,
dedication/acknowledgements if present, then body chapters, then
appendices).

**How to fix:** Reorder the `chapters:` list in `_quarto.yml` so that
preliminary files appear before body files. The validator reports the
first out-of-order file it finds.

------------------------------------------------------------------------

### abstract-one-page

**Policy section:** 8.1.e **Severity:** warning **Formats:** both

Checks (heuristically) whether the abstract in `index.qmd` exceeds
approximately one page of text. The source-phase check counts words; the
PDF-phase check (v0.2) will verify the rendered page count.

**How to fix:** Shorten your abstract to no more than ~300–350 words.
The policy mandates one page maximum.

------------------------------------------------------------------------

### csl-bundled-or-path-exists

**Policy section:** 7.2 **Severity:** error **Formats:** both

Checks that the `csl:` value in `_quarto.yml` is either a bundled style
name (resolvable via
[`list_csl()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/list_csl.md))
or a path to a file that exists on disk.

**How to fix:** Use one of the bundled style names (run
`list_csl()$name` to see them), or provide a valid path to a CSL file.
See
[`vignette("citation-styles")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/citation-styles.md).

------------------------------------------------------------------------

### bibliography-exists

**Policy section:** 7.2 **Severity:** error **Formats:** both

Checks that every file listed under `bibliography:` in `_quarto.yml`
exists on disk.

**How to fix:** Create the missing `.bib` file, or remove it from the
`bibliography:` list in `_quarto.yml`.

------------------------------------------------------------------------

### journal-rationale-present

**Policy section:** 13.10 **Severity:** error **Formats:** journal only

Checks that a chapter file whose name contains `rationale`
(case-insensitive) is listed in `_quarto.yml` under `book.chapters`.

**How to fix:** Add a rationale chapter (e.g.,
`chapters/00-rationale.qmd`) and list it in `_quarto.yml`. See
[`vignette("journal-format")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/journal-format.md).

------------------------------------------------------------------------

### journal-contribution-stmts

**Policy section:** 13.3 **Severity:** warning **Formats:** journal only

Checks that each chapter file whose name contains `paper`
(case-insensitive) carries a `contribution` attribute on its top-level
heading.

**How to fix:** Add `{contribution="..."}` to the `#` heading in each
paper chapter. See
[`vignette("journal-format")`](https://gabriel-cabrera-guz.github.io/uomthesis/articles/journal-format.md)
for the expected format.

------------------------------------------------------------------------

## Output formats

[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)
supports three output formats via the `format` argument:

### Console (default)

Findings are printed to the console using `cli` styling. Errors are
highlighted in red, warnings in yellow. A summary line reports the total
counts.

``` r

check_thesis()
```

### Markdown

Findings are written to `check-report.md` in the project root. The file
is overwritten on each run. Useful for committing a compliance snapshot
to version control.

``` r

check_thesis(".", format = "markdown")
# Writes check-report.md
```

### JSON

Returns a JSON string (invisibly) and also prints it. Each finding is a
JSON object with fields: `rule_id`, `severity`, `message`, `location`,
`policy_ref`, `hint`. Useful for CI integration.

``` r

result <- check_thesis(".", format = "json")
# result is a JSON string
```

## Fail-on behaviours

The `fail_on` argument controls when
[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)
signals an R error (allowing use in CI pipelines):

| Value | Behaviour |
|----|----|
| `"none"` (default) | Never signals an error; always returns invisibly |
| `"warning"` | Signals an error if any warning or error findings are found |
| `"error"` | Signals an error only if error-severity findings are found |

``` r

# Stop the build if any errors are found:
check_thesis(".", fail_on = "error")

# Stop the build if any warnings or errors are found:
check_thesis(".", fail_on = "warning")
```

## Restricting which rules run

Pass a character vector of rule IDs to `rules` to run only a subset:

``` r

check_thesis(".", rules = c("font-allowed", "linespacing-allowed"))
```

To get the full list of rule IDs programmatically:

``` r

vapply(uomthesis:::rule_registry(), `[[`, character(1), "id")
```
