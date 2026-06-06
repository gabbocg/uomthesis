# uomthesis examples

Two worked example projects you can read, render, and copy from.

## Rendered PDFs

- **`standard-example.pdf`** — a standard-format AMBS PhD thesis with six body chapters (intro, literature, methodology, results, discussion, conclusion) plus an appendix. Demonstrates citations, footnotes, figures, tables, equations, code chunks, callouts.
- **`journal-example.pdf`** — a journal-format AMBS PhD thesis with three constituent papers, each carrying a contribution declaration in a styled callout. Demonstrates the journal-format rationale chapter and the `::: {.contribution}` Div syntax that the Lua filter renders as a "Contribution statement" tcolorbox.

Open either PDF to see what `uomthesis` produces before you commit to using it.

## Source projects

- **`standard/`** — full Quarto project source for the standard example. Already includes the bundled `_extensions/uomthesis-standard/` and `references.bib`. Render it locally with:

    ```bash
    cd inst/examples/standard
    quarto render
    ```

- **`journal/`** — same, for the journal example.

## How to start from an example

Copy the example into your own directory and treat it as your thesis:

```bash
cp -r inst/examples/journal ~/Documents/my-thesis
cd ~/Documents/my-thesis
# Edit chapters/*.qmd, index.qmd metadata, references.bib
quarto render
```

You'll get a project that already shows how to use every Quarto feature commonly needed in a thesis. Then strip the example content and replace it with your own.

Equivalent in R:

```r
file.copy(
  from = system.file("examples/journal", package = "uomthesis"),
  to   = "~/Documents/",
  recursive = TRUE
)
```

## Accessing from installed package

After `remotes::install_github("gabriel-cabrera-guz/uomthesis")`, the examples are reachable as:

```r
system.file("examples/journal-example.pdf", package = "uomthesis")
system.file("examples/standard-example.pdf", package = "uomthesis")
system.file("examples/journal", package = "uomthesis")    # the source dir
system.file("examples/standard", package = "uomthesis")
```
