# Your thesis (journal format)

Scaffolded with `uomthesis::create_thesis()` using the journal format.

This skeleton follows the University of Manchester journal-format thesis guidelines
(Presentation of Theses Policy, section 13 — Journal Format Theses). Each paper
chapter (`02-paper-*.qmd`) should correspond to a published or submitted journal
article. The `contribution` attribute records your individual contribution statement,
as required by policy section 13.10.

## Next steps

1. Open `index.qmd` and edit your title-page metadata if needed.
2. Write chapter content under `chapters/`. The numbering convention is:
   - `00-*.qmd` — preliminary pages (abstract, acknowledgements) — not counted toward the word limit
   - `01-introduction.qmd` — contextualising introduction — counted toward the word limit
   - `02-` through `04-` — paper chapters — counted toward the word limit
   - `05-discussion.qmd` — general discussion — counted toward the word limit
   - `appendix-*.qmd` — appendices — not counted toward the word limit
3. Add references to `references.bib`.
4. Place figures under `figures/`.

## Rendering

From R:

```r
quarto::quarto_render()
```

From the terminal:

```bash
quarto render
```

The PDF will appear under `_book/`.

## Compliance checks

At any point, run:

```r
uomthesis::word_count()       # main-text word count vs cap
uomthesis::check_thesis()     # full compliance check
uomthesis::validate_metadata() # metadata-only check
```

## Documentation

See the `uomthesis` package documentation:

```r
?uomthesis::create_thesis
?uomthesis::check_thesis
vignette("getting-started", package = "uomthesis")
```

For the source policy this template encodes, run:

```r
uomthesis::policy_info()
```
