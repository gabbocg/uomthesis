# Scaffold a new uomthesis project

Creates a directory tree containing a Quarto project (`_quarto.yml`,
`index.qmd`, chapter stubs), copies the appropriate Quarto extension
(standard or journal) and a chosen CSL file into the project's
`_extensions/` directory, and substitutes user-supplied metadata into
the scaffolded `index.qmd`.

## Usage

``` r
create_thesis(
  path,
  format = c("standard", "journal"),
  degree = "PhD",
  faculty = "Humanities",
  school = "Alliance Manchester Business School",
  division = NULL,
  author = NULL,
  title = NULL,
  year = NULL,
  reference_style = c("harvard-manchester", "apa", "chicago-author-date", "mhra",
    "vancouver"),
  engine = c("lualatex", "xelatex", "pdflatex"),
  mainfont = "Times New Roman",
  list_of_publications = NULL,
  num_papers = 3L,
  force = FALSE,
  open = rlang::is_interactive()
)
```

## Arguments

- path:

  Path to the new project directory.

- format:

  `"standard"` or `"journal"`.

- degree:

  One of the degrees in the policy allowed set.

- faculty:

  Faculty name. Default: `"Humanities"`.

- school:

  School name. Default: `"Alliance Manchester Business School"`.

- division:

  AMBS division code: `"A&F"` \| `"IMP"` \| `"MSM"` \| `"PMO"`, or
  `NULL`.

- author:

  Named list with components `forename`, `middle_initial`, `surname`,
  `native_name` (optional). If `NULL`, placeholders are used.

- title:

  Thesis title. If `NULL`, a placeholder is used.

- year:

  Year of submission (integer). Defaults to current year.

- reference_style:

  One of `list_csl()$name`.

- engine:

  `"lualatex"` \| `"xelatex"` \| `"pdflatex"`.

- mainfont:

  One of the policy-allowed fonts.

- list_of_publications:

  For journal format: if `TRUE` (default for journal), a
  `chapters/00-publications.qmd` page is scaffolded and listed in
  `_quarto.yml`. Set to `FALSE` if you have no papers to list yet – the
  page is omitted from both the directory and the book chapters. Has no
  effect for `format = "standard"`.

- num_papers:

  For journal format: integer 1-10, the number of constituent paper
  chapters to scaffold (Introduction + N papers + Conclusion). Default
  `3` (the typical AMBS journal-format thesis size per policy section
  13.5). Paper 1 is always the rich example chapter that demonstrates
  citations, equations, tables, figures, and per-paper appendices;
  Papers 2..N are bare structural templates with letter- prefixed
  appendix headings (N.A, N.B). Has no effect for `format = "standard"`.

- force:

  If `TRUE`, allow `path` to exist as long as it is empty.

- open:

  If `TRUE` and RStudio is available, open the new project.

## Value

Invisible path to the created project.
