# uomthesis — Design

**Status:** Approved 2026-05-31
**Targets:** University of Manchester *Presentation of Theses Policy* **v12, March 2026** (next review November 2028)
**Scope:** Alliance Manchester Business School (AMBS), Faculty of Humanities

## Purpose

`uomthesis` is a public, polished R package that ships a Quarto template, an R-side scaffolder, and a compliance checker, all aimed at PhD candidates writing their thesis within Alliance Manchester Business School (AMBS) at the University of Manchester. It encodes the current Presentation of Theses Policy so an author can write in `.qmd`, render a policy-compliant PDF + HTML, and continuously verify that the document still meets the submission requirements.

The package is opinionated by design. Margins, page numbering, the declaration text, and the copyright statement are mandated by the policy; the package makes them defaults and the validator pushes back when they drift. Knobs only exist where the policy permits variation (font choice within the allowed list, line spacing 1.5 vs 2.0, choice of referencing style, standard vs journal format, optional preliminary pages).

## Goals

1. A UoM PGR can install `uomthesis`, run one command, and have a scaffolded thesis project that renders to a compliant PDF on first try.
2. The rendered PDF passes the Presentation of Theses Policy's mechanical requirements (font, margins, pagination, prelim order, declaration/copyright text) without the author having to read the policy.
3. The author can run `word_count()` at any point and see, against the policy's exact definition of "main text," how much budget is left.
4. The author can run `check_thesis()` at any point and get a list of any policy violations with file:line references and fix recipes.
5. Both standard and journal thesis formats are first-class.
6. The package is internally consistent: if it says you are compliant, you are.

## Non-goals

- Word (.docx) output. PDF + HTML only.
- Non-AMBS or non-Humanities thesis conventions (other schools/faculties can override `school:` and `division:`, but their division names and conventions are not in the curated allowed-sets).
- DBA / MRes / MPhil first-class skeletons or DBA-specific validator rules. The template renders for these degrees; we don't tailor.
- Practice-based PhDs (policy §14). Word counts and structure vary too much by School for the validator to be reliable.
- Pre-submission services (Turnitin, plagiarism detection, real proofreading).
- PDF/A or PDF/UA compliance beyond what Quarto/LuaLaTeX produce by default.
- Continuous compatibility with older Quarto. We pin `quarto-required: ">=1.5.0"` and test against the latest release; older Quarto produces a clear error.

## Architecture overview

The package is one R package containing four logical modules:

1. **R API** (`R/`) — `create_thesis()`, `word_count()`, `check_thesis()`, plus exported helpers (`list_csl()`, `copy_csl()`, `policy_info()`, `validate_metadata()`).
2. **Quarto extensions** (`inst/quarto/_extensions/`) — two sibling extensions, `uomthesis-standard` and `uomthesis-journal`, plus a `_shared/` directory holding policy-mandated partials referenced by both via symlinks.
3. **Bundled CSL menu** (`inst/csl/`) — five curated, version-pinned CSL files plus a `SOURCES.yml` manifest (URL, sha256, retrieval date per file).
4. **Project skeletons** (`inst/skeleton/`, `inst/skeleton-journal/`) — the chapter scaffold, `_quarto.yml`, and starter `index.qmd` copied into a new user project.

The R package and the Quarto extensions are versioned together. `create_thesis()` is the only place where the R side and the Quarto side meet: it copies the appropriate extension and skeleton into the user's project. After that, rendering is pure Quarto and validation is pure R; they share state only through the project's YAML.

```
┌─────────────────────────────────────────────────────────────┐
│  uomthesis (R package)                                       │
│                                                              │
│  ┌───────────────┐   ┌──────────────────────────────────┐  │
│  │  R API        │   │  Bundled Quarto assets           │  │
│  │  (R/)         │   │  (inst/quarto/_extensions/)      │  │
│  │               │   │                                   │  │
│  │  create_      │   │  uomthesis-standard/             │  │
│  │   thesis()    │   │    _extension.yml                │  │
│  │  word_count() │   │    template.tex (LuaLaTeX)       │  │
│  │  check_       │   │    partials/                     │  │
│  │   thesis()    │   │    theme/                        │  │
│  │  list_csl()   │   │                                   │  │
│  │  copy_csl()   │   │  uomthesis-journal/              │  │
│  │  policy_info()│   │    _extension.yml                │  │
│  │  validate_    │   │    template.tex                  │  │
│  │   metadata()  │   │    partials/                     │  │
│  └───────────────┘   │                                   │  │
│                      │  _shared/                        │  │
│  ┌───────────────┐   │    title-page.tex                │  │
│  │  Bundled      │   │    declaration.tex               │  │
│  │  CSL menu     │   │    copyright.tex                 │  │
│  │  (inst/csl/)  │   │    ai-disclosure.tex             │  │
│  │               │   │    theme.scss                    │  │
│  │  + skeletons  │   └──────────────────────────────────┘  │
│  └───────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
            │
            │  create_thesis() copies the right
            │  extension + skeleton into a new
            │  user project
            ▼
┌─────────────────────────────────────────────────────────────┐
│  User project                                                │
│   _quarto.yml          (format: uomthesis-standard-pdf)     │
│   index.qmd            (title-page metadata)                │
│   chapters/01-…qmd                                          │
│   references.bib                                             │
│   _extensions/uomthesis-standard/  (copied at scaffold)     │
└─────────────────────────────────────────────────────────────┘
```

## Package layout

```
uomthesis/
├── DESCRIPTION                # Imports: cli, fs, glue, rlang, withr, yaml
│                              # Suggests: pdftools, quarto, rstudioapi, testthat,
│                              #           knitr, rmarkdown
├── NAMESPACE
├── LICENSE                    # MIT + file LICENSE
├── README.md                  # built from README.Rmd
├── NEWS.md                    # one entry per release; records the targeted
│                              # Presentation of Theses Policy version
│
├── .github/workflows/
│   ├── R-CMD-check.yml        # Linux + macOS + Windows; R-release + R-devel
│   ├── test-coverage.yml      # covr → codecov
│   ├── pkgdown.yml            # docs site to gh-pages
│   └── render-example-thesis.yml  # end-to-end PDF render on Linux
│
├── R/
│   ├── create_thesis.R
│   ├── word_count.R
│   ├── check_thesis.R         # orchestrator
│   ├── check_rules.R          # rule registry (one entry per check)
│   ├── check_report.R         # console / markdown / JSON formatters
│   ├── parse_qmd.R            # internal: walk .qmd source for AST-like checks
│   ├── parse_pdf.R            # internal: pdftools wrapper for PDF-phase checks
│   ├── policy.R               # single source of truth for policy constants
│   ├── csl.R                  # list_csl(), copy_csl()
│   ├── utils.R                # internal helpers
│   └── zzz.R                  # .onLoad sanity check on inst/quarto/_extensions/
│
├── inst/
│   ├── quarto/_extensions/
│   │   ├── uomthesis-standard/
│   │   │   ├── _extension.yml      # declares uomthesis-standard-pdf,
│   │   │   │                       # uomthesis-standard-html formats
│   │   │   ├── template.tex        # LuaLaTeX skeleton
│   │   │   ├── partials/
│   │   │   │   ├── title-page.tex     # → symlink to _shared/
│   │   │   │   ├── declaration.tex    # → symlink to _shared/
│   │   │   │   ├── copyright.tex      # → symlink to _shared/
│   │   │   │   ├── ai-disclosure.tex  # → symlink to _shared/
│   │   │   │   ├── before-body.tex
│   │   │   │   └── header.tex         # page numbering, geometry
│   │   │   └── theme/
│   │   │       ├── uomthesis.scss     # → symlink to _shared/theme.scss
│   │   │       └── uomthesis-html.html # title-page HTML partial
│   │   │
│   │   ├── uomthesis-journal/
│   │   │   ├── _extension.yml
│   │   │   ├── template.tex
│   │   │   ├── partials/
│   │   │   │   ├── rationale.tex             # journal-specific prelim
│   │   │   │   ├── contribution-statement.tex # per-chapter block
│   │   │   │   ├── title-page.tex            # → symlink to _shared/
│   │   │   │   ├── declaration.tex           # → symlink to _shared/
│   │   │   │   ├── copyright.tex             # → symlink to _shared/
│   │   │   │   ├── ai-disclosure.tex         # → symlink to _shared/
│   │   │   │   └── header.tex
│   │   │   └── theme/uomthesis.scss          # → symlink to _shared/theme.scss
│   │   │
│   │   └── _shared/                          # source of truth for symlinks
│   │       ├── title-page.tex
│   │       ├── declaration.tex
│   │       ├── copyright.tex
│   │       ├── ai-disclosure.tex
│   │       └── theme.scss
│   │
│   ├── csl/                                  # bundled citation styles
│   │   ├── harvard-manchester.csl
│   │   ├── apa.csl
│   │   ├── chicago-author-date.csl
│   │   ├── mhra.csl
│   │   ├── vancouver.csl
│   │   └── SOURCES.yml                       # URL + sha256 + retrieval date
│   │
│   ├── skeleton/                             # standard-format starter
│   │   ├── _quarto.yml
│   │   ├── index.qmd
│   │   ├── chapters/
│   │   │   ├── 00-abstract.qmd
│   │   │   ├── 01-introduction.qmd
│   │   │   ├── 02-literature.qmd
│   │   │   ├── 03-methodology.qmd
│   │   │   ├── 04-results.qmd
│   │   │   ├── 05-discussion.qmd
│   │   │   └── 06-conclusion.qmd
│   │   ├── references.bib                    # empty starter
│   │   ├── figures/
│   │   └── README.md
│   │
│   └── skeleton-journal/                     # journal-format starter
│       └── ...
│
├── man/                                       # roxygen-generated
├── tests/
│   ├── testthat/
│   │   ├── test-create_thesis.R
│   │   ├── test-word_count.R
│   │   ├── test-check_thesis.R
│   │   ├── test-check_rules.R               # one test per rule
│   │   ├── test-policy.R                    # constants haven't drifted
│   │   ├── fixtures/
│   │   │   ├── compliant-standard/
│   │   │   ├── compliant-journal/
│   │   │   ├── noncompliant-missing-cr/
│   │   │   ├── noncompliant-altered-decl/
│   │   │   └── noncompliant-roman/
│   │   └── _snaps/                          # snapshot tests for report output
│   └── testthat.R
│
├── vignettes/
│   ├── getting-started.Rmd
│   ├── journal-format.Rmd
│   ├── compliance.Rmd
│   └── citation-styles.Rmd
│
├── pkgdown/
│   └── _pkgdown.yml
│
└── dev/                                      # not part of build
    ├── sync_shared.R                         # verify symlinks vs _shared/ source
    ├── refresh_csl.R                         # re-download & sha-pin CSL files
    └── render_example_thesis.R               # build PDF for docs site
```

### Layout decisions

- **No UoM logo / branding asset shipped.** UoM's logo is copyright-protected. The README documents how a user can place a logo locally; the package itself bundles none.
- **`policy.R` as the single source of truth** for everything tied to the Presentation of Theses Policy: required prelim order, exact declaration text (both variants), exact copyright bullets, allowed fonts list, margin minima, word-cap table per degree × format. Every constant carries an inline comment with its policy section number. The validator reads from `policy.R`; the partials that need the same constants receive them through Quarto metadata generated by `create_thesis()`.
- **`_shared/` via symlinks** rather than build-time copying. Symlinks survive `R CMD build`'s tarball; partials look like normal files to Quarto. Windows developers without symlink support use `dev/sync_shared.R` to refresh copies before commit.
- **`SOURCES.yml`** records exactly which version of each bundled CSL we ship: source URL, retrieval date, sha256. A maintainer script (`dev/refresh_csl.R`, not user-facing) reports drift against upstream so the package can stay current.

## The Quarto extensions

Both extensions follow the same shape. They diverge only where the policy says they should.

### `uomthesis-standard`

`_extension.yml` declares two formats:

```yaml
title: UoM AMBS Standard Thesis
author: Gabriel Cabrera
version: 0.1.0
quarto-required: ">=1.5.0"
contributes:
  formats:
    pdf:
      pdf-engine: lualatex
      documentclass: report
      papersize: a4
      geometry:
        - left=40mm                      # binding edge — policy §7.3
        - right=15mm
        - top=20mm
        - bottom=20mm
      fontsize: 12pt
      linestretch: 1.5
      mainfont: "Times New Roman"
      number-sections: true
      toc: true
      toc-depth: 3
      lof: true
      lot: true
      bibliography: references.bib
      csl: "{{< meta uomthesis.csl >}}"
      template: template.tex
      include-in-header:
        - partials/header.tex
      include-before-body:
        - partials/title-page.tex
        - partials/declaration.tex
        - partials/copyright.tex
      cite-method: biblatex
    html:
      theme: theme/uomthesis.scss
      toc: true
      number-sections: true
      anchor-sections: true
      bibliography: references.bib
      csl: "{{< meta uomthesis.csl >}}"
```

`template.tex` is a Pandoc-Quarto LaTeX skeleton that:

- Uses `ifluatex` to choose between `fontspec` (LuaLaTeX/XeLaTeX) and `mathptmx` (pdfLaTeX fallback) so the policy-allowed font list is reachable.
- Sets `geometry` from `_extension.yml` — values are not user-overridable except via explicit YAML override.
- Sets `\pagenumbering{arabic}` (no `\frontmatter` / Roman numerals anywhere).
- Sets `\fancyhf{}` for headers — no candidate name in headers per policy §7.9.
- Provides a `\blankpage` macro that emits a centered "Blank page" text per policy §7.7.

How the template enforces specific clauses:

| Policy clause | How the template enforces it |
|---|---|
| §7.3 margins (40 mm bind / 15 mm other) | `geometry` package, values from `_extension.yml` |
| §7.1 fonts | `fontspec` under LuaLaTeX/XeLaTeX; `mainfont` validated by `create_thesis()` against the allowed list |
| §7.4 / §7.6 pagination | `\pagenumbering{arabic}`; no `\frontmatter` or Roman numerals |
| §7.5 title page = page 1 | Title-page partial is `include-before-body`, inside `\begin{document}` |
| §7.7 blank pages | `\blankpage` macro emits "Blank page" text |
| §7.9 no name in headers | `\fancyhf{}` clears headers; partials do not write to header |
| §8.1 prelim order | `include-before-body` list in `_extension.yml` is the source of truth |

#### Standard partials

- **`title-page.tex`** — driven by Quarto metadata. Uses the policy's required statement verbatim: `A thesis submitted to The University of Manchester for the degree of <degree> in the Faculty of <faculty>.` `year` is an integer (no month — §8.1.b). `author` accepts an optional `native_name` for the bilingual rendering the policy allows.
- **`declaration.tex`** — emits the EITHER text by default; the OR variant is selected by setting `declaration.variant: "or"` and providing `joint_authorship_details`. The exact policy text is hardcoded; no user knob alters it.
- **`copyright.tex`** — emits the four mandatory bullets verbatim. Not parameterized; the author's name in bullet i is taken from the same `author` metadata as the title page.
- **`ai-disclosure.tex`** — optional, gated on `ai_disclosure.include: true`. If `ai_disclosure.tools` is provided as a non-empty list, it is interpolated into the policy's sample wording; otherwise the boilerplate sample appears.

### `uomthesis-journal`

Same backbone as standard, with:

- **Rationale section** (mandatory per policy §13.10, first bullet) included as a partial after the abstract, before chapter one.
- **Per-chapter contribution declaration**: a `contribution` chunk option (e.g. `#| contribution: "I designed the study, collected data, wrote the manuscript. Co-author X advised on statistical methods."`) emits a styled box at the chapter opening. Implemented as a Lua filter shipped under `uomthesis-journal/_extensions/uomthesis-journal/filters/contribution.lua`, registered in the format's `filters:` list. The filter renders the box for PDF (a tcolorbox-styled callout) and HTML (a CSS-styled div).
- **Word limit documented as 90 k** in `_extension.yml`. The partial templates do not enforce it; the validator does.
- **`thesis_format: journal`** metadata key set automatically — used by `word_count()` to apply the 90 k cap and by `check_thesis()` to load journal-specific rules.

### `_shared/`

Files that are byte-identical between standard and journal:

- `title-page.tex`, `declaration.tex`, `copyright.tex`, `ai-disclosure.tex` (policy text is the same regardless of format)
- `theme.scss` (HTML look is the same)

Each extension's `partials/` contains symlinks pointing into `_shared/`. `dev/sync_shared.R` verifies symlink targets and can recreate them on platforms where symlinks need re-creating.

## R API surface

Three primary functions plus four helpers. All public functions use `cli` for output and `rlang::abort()` with classed conditions for errors.

### `create_thesis()`

```r
create_thesis(
  path,
  format = c("standard", "journal"),
  degree = c("PhD", "MPhil", "DBA", "MD", "EngD", "PhD by Enterprise"),
  faculty = "Humanities",
  school = "Alliance Manchester Business School",
  division = NULL,                    # one of: "A&F", "IMP", "MSM", "PMO"; NULL allowed
  author = NULL,                      # list(forename=, middle_initial=, surname=, native_name=)
  title = NULL,
  year = NULL,                        # integer; defaults to current year
  reference_style = c("harvard-manchester", "apa", "chicago-author-date",
                      "mhra", "vancouver"),
  engine = c("lualatex", "xelatex", "pdflatex"),
  mainfont = "Times New Roman",       # validated against policy §7.1 allowed list
  force = FALSE,                      # if TRUE, allow path to exist when empty
  open = rlang::is_interactive()
)
```

Behavior:

1. Validate inputs. `path` must not exist (unless `force = TRUE` and path is empty). `mainfont` must be in the allowed list; if `engine = "pdflatex"`, must additionally be in the pdfLaTeX-safe subset (`Times New Roman` only).
2. Create directory tree from `inst/skeleton/` or `inst/skeleton-journal/`.
3. Copy the appropriate extension plus `_shared/` symlink targets into `path/_extensions/`.
4. Copy the requested CSL from `inst/csl/` into `path/_extensions/uomthesis-<format>/csl/` and reference it from `_quarto.yml`.
5. Render the YAML front-matter of `index.qmd` from the supplied arguments. Missing fields become commented placeholders.
6. If `open = TRUE` and RStudio is available, `rstudioapi::openProject(path)`.
7. Print next-steps tip via `cli`.

Returns the path invisibly.

### `word_count()`

```r
word_count(
  project = ".",
  rendered_pdf = NULL,
  warn_at = 0.9,
  error_at = NULL
)
```

Behavior:

1. Resolve thesis format by reading `_quarto.yml` (error clearly if neither standard nor journal extension is in use).
2. Look up the applicable cap from `policy.R` based on format × degree:
   - Standard PhD / EngD / MD / PhD-by-Enterprise: **80,000**
   - Standard MPhil / Professional Doctorate: **50,000**
   - Journal PhD / EngD / MD / PhD-by-Enterprise: **90,000**
   - Journal MPhil / Professional Doctorate: **60,000**
   - Practice-based: 20,000–50,000 (cap depends on local arrangement; print a note, skip cap-checking)
3. Count "main text" per policy §4.6 fn. 1:
   - **Included**: core chapters (argument and findings), footnotes, endnotes.
   - **Excluded**: preliminary pages (abstract, lay abstract, TOC, lists, declaration, copyright, AI disclosure, acknowledgements, "Preface"/"The Author"), bibliography/list of works cited, appendices.
4. Source counting (default) walks `index.qmd` → resolved chapter list, strips YAML/code chunks/equations/footnote markers, partitions each `.qmd` by prelim/body/appendix.
5. PDF counting (when `rendered_pdf` supplied) uses `pdftools::pdf_text()`, identifies page ranges from the parsed TOC, applies the same prelim/body/appendix partition.
6. Returns a `uomthesis_word_count` object: `total`, `cap`, `by_chapter` (named integer), `excluded` (named integer per excluded section), `format`, `degree`, `over` (logical). Custom `print` shows a progress bar against the cap, a breakdown table, and `cli` warnings/errors per `warn_at` / `error_at`.

### `check_thesis()`

```r
check_thesis(
  project = ".",
  rendered_pdf = NULL,
  rules = NULL,
  format = c("console", "markdown", "json"),
  fail_on = c("none", "warning", "error")
)
```

Behavior:

1. Discover thesis format and degree as in `word_count()`.
2. Load applicable rules from the rule registry (rule shape detailed below).
3. Run source-phase rules; if `rendered_pdf` is supplied, also run PDF-phase rules.
4. Aggregate findings into a `uomthesis_check_report` with columns `rule_id`, `severity`, `location`, `message`, `policy_ref`.
5. Render the report in `console` (via `cli`, grouped by category), `markdown` (committable file), or `json` (CI-friendly).
6. Per `fail_on`: invisible return, or `rlang::abort()` after summary when findings meet the threshold.

Default `fail_on = "none"` — informational unless the user opts in.

### Helpers (exported)

```r
list_csl()                  # data.frame of bundled CSLs: name, source URL, retrieval date
copy_csl(name, to = ".")    # copy a bundled CSL into a project
policy_info()               # named list with components $version (character, e.g. "12"),
                            # $dated (Date, e.g. 2026-03-01), $next_review (Date),
                            # $source_url (character). Custom print method that
                            # formats as a one-screen summary; programmatic access
                            # via list components.
validate_metadata(project = ".")   # lint index.qmd without running a full check
```

## YAML schema

This is the contract between user and package. Anything not listed is standard Quarto.

### `_quarto.yml`

Written by `create_thesis()`; rarely touched after:

```yaml
project:
  type: book
  output-dir: _book

book:
  title: "{{< meta title >}}"
  chapters:
    - index.qmd
    - chapters/00-abstract.qmd
    - chapters/01-introduction.qmd
    - chapters/02-literature.qmd
    - chapters/03-methodology.qmd
    - chapters/04-results.qmd
    - chapters/05-discussion.qmd
    - chapters/06-conclusion.qmd
  appendices:
    - chapters/appendix-a.qmd

format:
  uomthesis-standard-pdf: default
  uomthesis-standard-html: default

bibliography: references.bib
csl: _extensions/uomthesis-standard/csl/harvard-manchester.csl
```

### `index.qmd` front-matter

Two zones: `uomthesis:` (our schema) and standard Quarto keys.

```yaml
---
# ─── Standard Quarto keys ────────────────────────────────────────────
title: "An Analysis of Something Important"
author:
  - name: "Jane Q. Doe"

# ─── uomthesis: policy-driven metadata ───────────────────────────────
uomthesis:
  candidate:
    forename: "Jane"
    middle_initial: "Q"
    surname: "Doe"
    native_name: null
  degree: "PhD"
  faculty: "Humanities"
  school: "Alliance Manchester Business School"
  division: "MSM"
  year: 2027
  thesis_format: "standard"          # set automatically by create_thesis()
  declaration:
    variant: "either"                # "either" | "or"
    joint_authorship_details: null   # required when variant: "or"
  ai_disclosure:
    include: false
    tools: []
    description: null
  content_notification:
    include: false
    summary: null
  optional_prelims:
    lay_abstract: false
    dedication: null
    acknowledgements: true
    preface: false
  resubmission:
    is_resubmission: false
    revisions_file: null
  covid_impact_statement: null

mainfont: "Times New Roman"          # validated against policy §7.1 list
linestretch: 1.5                     # 1.5 or 2.0 (= double); enforced
pdf-engine: lualatex                 # lualatex | xelatex | pdflatex
---
```

### Schema validation

`create_thesis()` writes a syntactically valid file the first time. After that:

- **Missing required fields** (`candidate.surname`, `degree`, `faculty`, `year`) → error with `cli` message pointing at file and line.
- **Value not in allowed set** (e.g., `degree: "DPhil"`) → error listing valid choices.
- **Cross-field consistency** (e.g., `declaration.variant: "or"` requires `joint_authorship_details`) → error.
- **Date-shaped fields** (`year`) → plausible integer 2000–2100.

Validation runs at the start of `word_count()` and `check_thesis()`. `validate_metadata()` is exported for standalone use.

### Locked vs editable

Locked (not exposed as knobs):

- Margins
- Page-number style / position
- Declaration / copyright statement text
- Required-prelims order
- Word-count text on TOC (auto-rendered)

This "knobs only where the policy permits variation" principle is what makes the validator meaningful.

`optional_prelims.preface`, `optional_prelims.acknowledgements`, `optional_prelims.lay_abstract`, and `optional_prelims.dedication` exist solely to gate template inclusion of those sections — there are no validator rules tied to them. The validator is silent on whether a thesis has acknowledgements; the policy treats them as optional.

## The validator

### Rule registry shape

Every check is a list in `R/check_rules.R`:

```r
list(
  id          = "declaration-text",
  policy_ref  = "§8.1.f",
  phase       = "source",                # "source" | "pdf"
  formats     = c("standard", "journal"),
  severity    = "error",                 # "error" | "warning"
  check       = function(ctx) { … },     # returns NULL (pass) or a finding list
  rationale   = "The declaration text is mandated verbatim by the policy.
                 Any deviation may cause the Doctoral Academy to reject the
                 thesis for examination."
)
```

`ctx` is built once per run:

- `ctx$project_path`
- `ctx$metadata` — parsed `uomthesis:` YAML
- `ctx$qmd_files` — files classified as `prelim` / `body` / `appendix` / `bibliography`
- `ctx$qmd_text` — lazy-loaded text per file
- `ctx$pdf_pages` — character vector of pages, or `NULL`
- `ctx$pdf_toc` — parsed TOC, or `NULL`
- `ctx$policy` — `policy.R` constants

### v0.1 rule set

Source-phase (always run):

| ID | Policy ref | Severity | What it checks |
|---|---|---|---|
| `metadata-complete` | §8.1.b | error | All required YAML keys present and well-typed |
| `degree-faculty-school` | §8.1.b | error | `degree`, `faculty`, `school` are from allowed sets |
| `year-not-month` | §8.1.b | error | `year` is integer, not a date with month |
| `title-page-statement` | §8.1.b | error | Title-page partial uses the exact statement template |
| `prelim-order` | §8.1 | error | `include-before-body` order matches the mandated order |
| `declaration-text` | §8.1.f | error | Declaration partial matches policy text exactly (variant-aware) |
| `copyright-text` | §8.1.g | error | All four mandatory bullets present, verbatim |
| `copyright-author-match` | §8.1.g | error | Author name in copyright bullet matches `candidate` fields |
| `abstract-one-page` | §8.1.e | warning | Abstract source is under a heuristic threshold (final check is PDF-phase) |
| `font-allowed` | §7.1 | error | `mainfont` is in the allowed list |
| `font-engine-compat` | §7.1 | error | If `pdf-engine: pdflatex`, `mainfont` is pdfLaTeX-safe |
| `linespacing-allowed` | §7.1 | error | `linestretch` is `1.5` or `2.0` |
| `ai-disclosure-shape` | §9.1.d | warning | If `ai_disclosure.include: true`, `tools` is non-empty list |
| `journal-rationale-present` | §13.10 | error | (journal) rationale partial included before chapter 1 |
| `journal-contribution-stmts` | §13.3 | warning | (journal) each results chapter has a `contribution` chunk option |
| `csl-bundled-or-path-exists` | §7.2 | error | `csl:` path resolves to a real file |
| `bibliography-exists` | §7.2 | error | `bibliography:` files exist |
| `english-language` | §6.1 | warning | YAML `lang:` is `en` / `en-GB` (or `en-US` with override) |

PDF-phase (when `rendered_pdf` supplied; deferred from v0.1 to v0.2 unless an early adopter needs it):

| ID | Policy ref | Severity | What it checks |
|---|---|---|---|
| `pdf-margins` | §7.3 | error | Bind-edge ≥ 40 mm, others ≥ 15 mm (sampled) |
| `pdf-pagination-arabic` | §7.4, §7.6 | error | Page numbers are Arabic, single sequence, starting at title page |
| `pdf-no-name-in-header` | §7.9 | warning | Candidate `surname` not in any page's header band |
| `pdf-blank-page-text` | §7.7 | warning | Near-empty pages contain "Blank page" text |
| `pdf-abstract-one-page` | §8.1.e | error | Abstract section spans exactly one page |
| `pdf-word-count-on-toc` | §8.1.c | error | Word count appears at the bottom of the contents page |
| `pdf-word-count-correct` | §4.6 | warning | TOC word count within ±1% of `word_count()` total |

### Finding shape

```r
list(
  rule_id     = "declaration-text",
  severity    = "error",
  message     = "Declaration text on line 14 of chapters/00-prelims/declaration.qmd
                 has been edited from the policy-mandated wording.
                 Diff: …",
  location    = list(file = "chapters/00-prelims/declaration.qmd", line = 14L),
  policy_ref  = "§8.1.f",
  hint        = "Restore the EITHER text exactly, or set
                 uomthesis.declaration.variant: 'or' if joint authorship applies."
)
```

`message` is the headline. `hint` is the fix. For text-match rules, the diff is truncated to ~5 lines with `…`.

### Output formats

**Console** via `cli`, grouped by error/warning, each finding shows `rule_id`, `policy_ref`, message, hint.

**Markdown** writes `check-report.md` with one section per rule, suitable for committing or emailing.

**JSON** machine-readable, for CI. The package ships a sample GitHub Actions workflow that runs `Rscript -e 'uomthesis::check_thesis(format = "json", fail_on = "error")'` on push.

### Validator non-goals

- No CSL conformance check beyond "file exists."
- `check_thesis()` does not run `word_count()` against the cap — separate tools, compose if you want.
- No journal-format references-per-chapter consistency check (too much false-positive risk).
- No plagiarism / Turnitin-style detection.
- No "referenced figures exist on disk" check (Quarto's renderer handles).

## Testing strategy

Three layers:

1. **Unit tests** for pure functions: every check function, every parser helper, every `policy.R` constant. Run on every change, every platform, < 30 seconds total. No fixtures bigger than a few KB.
2. **Fixture-driven integration tests** for `check_thesis()` against five minimal projects:
   - `compliant-standard/` — zero findings expected
   - `compliant-journal/` — zero findings expected
   - `noncompliant-missing-cr/` — `copyright-text` fires
   - `noncompliant-altered-decl/` — `declaration-text` fires
   - `noncompliant-roman/` — pagination/linespacing rule fires

   Tests assert exact firing rule IDs and finding counts. Report output is snapshot-tested via `testthat::expect_snapshot()`.
3. **End-to-end render test (CI, Linux only)**. One GitHub Actions job renders `fixtures/compliant-standard/` to PDF using Quarto + TinyTeX, then runs `check_thesis(rendered_pdf = …)` and asserts zero findings. Catches LaTeX-preamble bugs, missing fonts, geometry drift. We do not snapshot-test the rendered PDF itself.

## CI

| Workflow | When | What |
|---|---|---|
| `R-CMD-check.yml` | Push, PR | Linux + macOS + Windows, R-release + R-devel |
| `test-coverage.yml` | Push to main | `covr::codecov()` |
| `pkgdown.yml` | Push to main | Docs site to gh-pages |
| `render-example-thesis.yml` | Push, PR | End-to-end PDF render on Linux; uploads PDF artifact on PRs touching templates |

If anyone weakens the policy text constants, `R-CMD-check` fails on the `noncompliant-*` fixtures.

## Documentation

| Asset | Audience | Source |
|---|---|---|
| `README.md` | first-time visitor | Built from `README.Rmd` — 30-second overview, install, one-command quick-start |
| `vignettes/getting-started.Rmd` | new user | 10-minute walkthrough from install to rendered PDF |
| `vignettes/journal-format.Rmd` | journal-format user | When it applies, rationale chapter, contribution declarations |
| `vignettes/compliance.Rmd` | anyone hitting validator findings | Each rule explained with a fix recipe |
| `vignettes/citation-styles.Rmd` | citation chooser | The five bundled CSLs and when each is conventional at UoM |
| pkgdown site | reference users | Auto-built from roxygen; vignettes promoted to articles |
| `NEWS.md` | upgraders | Each release records the targeted Presentation of Theses Policy version |

## Versioning and policy-tracking

Semver: `MAJOR.MINOR.PATCH`.

- Policy revision that changes mandated text → minor bump (outputs change, R API does not).
- R API break → major bump.
- Bug fixes → patch.

`policy_info()` exposes the targeted policy version, retrieval date, and next review date so an author who installed `uomthesis 0.3.0` two years ago can immediately tell whether to upgrade.

## v0.1 vs later

**v0.1** (initial public release): scaffolder, both formats, source-phase validator, word counter, five bundled CSLs, four vignettes, end-to-end CI on Linux, GitHub-only distribution. `check_thesis()` ships with console / markdown / JSON output formats from day one.

**v0.2** candidates: PDF-phase validator, `policy_diff()` to compare current text constants against a fetched policy PDF, optional `.docx` output, formal CRAN submission.

## Sources

- *Presentation of Theses Policy* v12, March 2026 — https://documents.manchester.ac.uk/display.aspx?DocID=7420
- *Journal Format PhD Theses — Guiding Principles for Students and Staff* — https://documents.manchester.ac.uk/display.aspx?DocID=15216
- *AMBS Doctoral Programmes Postgraduate Researcher (PGR) Handbook 2023/24* — https://documents.manchester.ac.uk/display.aspx?DocID=51116
- *School of Arts, Languages and Cultures Thesis Submission Information* — https://documents.manchester.ac.uk/display.aspx?DocID=51157
- Regulations page (Presentation of Theses Policy) — https://www.regulations.manchester.ac.uk/pgr-presentation-theses/
