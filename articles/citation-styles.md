# Citation styles

## Which styles are bundled

`uomthesis` ships five CSL (Citation Style Language) files that cover
the most common citation styles used in AMBS research. View them with
[`list_csl()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/list_csl.md):

``` r

library(uomthesis)
list_csl()
#>                  name
#> 1  harvard-manchester
#> 2                 apa
#> 3 chicago-author-date
#> 4                mhra
#> 5           vancouver
#>                                                                                                   url
#> 1 https://raw.githubusercontent.com/citation-style-language/styles/master/harvard-cite-them-right.csl
#> 2                     https://raw.githubusercontent.com/citation-style-language/styles/master/apa.csl
#> 3     https://raw.githubusercontent.com/citation-style-language/styles/master/chicago-author-date.csl
#> 4              https://raw.githubusercontent.com/citation-style-language/styles/master/mhra-notes.csl
#> 5      https://raw.githubusercontent.com/citation-style-language/styles/master/elsevier-vancouver.csl
#>    retrieved                                                           sha256
#> 1 2026-06-02 0ca3d2c7c881cd98cdd81098b5349f5921edf430498aa9a5a41918621cf7cc45
#> 2 2026-06-02 1ece4fb3c295e66d04b4394e295aa58a87741ceeef1658192437eb9953c2f13e
#> 3 2026-06-02 002fade78d7e4fe9d42936a16b43a8066b097013f6255df40b1bfba6631eff9b
#> 4 2026-06-02 9fa37e7faabf28795309b74b42c459b9586fd8f58529ed2db9f40722db3a7637
#> 5 2026-06-02 005e915c3419eb2b84eb2b31bffc411dce3890619d3fd0ed23ac6591ac128335
```

Each style is identified by a short `name` used in
[`create_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/create_thesis.md)
and
[`copy_csl()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/copy_csl.md).
The `sha256` column records the hash of the CSL file at retrieval time
so that reproducibility can be verified: if the upstream file changes,
the hash will differ.

The bundled styles are:

| Name | Full style name | Common in |
|----|----|----|
| `harvard-manchester` | Harvard (Cite Them Right) | Business, social sciences |
| `apa` | APA 7th edition | Psychology, education |
| `chicago-author-date` | Chicago author-date | History, humanities |
| `mhra` | MHRA footnotes | Humanities, languages |
| `vancouver` | Vancouver (Elsevier variant) | Medicine, life sciences |

Policy section 7.2 requires citations to be in a consistent, recognised
style throughout the thesis. Any of the five bundled styles satisfies
this requirement.

## Picking one at scaffold time

Pass `reference_style` to
[`create_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/create_thesis.md):

``` r

create_thesis(
  "my-thesis",
  degree          = "PhD",
  author          = list(forename = "Jane", surname = "Doe"),
  title           = "An analysis of something",
  year            = 2027,
  division        = "MSM",
  reference_style = "apa"
)
```

The scaffolder copies `apa.csl` into the extension’s `csl/` subdirectory
and sets `csl: _extensions/uomthesis-standard/csl/apa.csl` in
`_quarto.yml`.

If `reference_style` is omitted the default is `harvard-manchester`.

## Switching styles after scaffolding

To change the citation style in an existing project:

**Step 1.** Copy the new CSL into your extension directory:

``` r

copy_csl("apa", to = "_extensions/uomthesis-standard/csl/")
```

**Step 2.** Update the `csl:` line in `_quarto.yml`:

``` yaml
bibliography: references.bib
csl: _extensions/uomthesis-standard/csl/apa.csl
```

**Step 3.** Re-render:

``` r

quarto::quarto_render()
```

For a journal-format project, replace `uomthesis-standard` with
`uomthesis-journal` in the path.

## Bringing your own CSL

You are not restricted to the five bundled styles. If your supervisor
requires a specific style, or if your target journal has a custom CSL:

1.  Download the CSL file (e.g., from <https://citationstyles.org/> or
    the CSL repository at
    <https://github.com/citation-style-language/styles>).
2.  Save it anywhere inside your project (e.g.,
    `_extensions/uomthesis-standard/csl/my-style.csl`).
3.  Point `csl:` in `_quarto.yml` at the file path:

``` yaml
csl: _extensions/uomthesis-standard/csl/my-style.csl
```

The `csl-bundled-or-path-exists` validator rule accepts any path that
resolves to an existing file, so your custom CSL will pass validation as
long as it is present on disk.

## How bundled styles are pinned

The file `inst/csl/SOURCES.yml` records the provenance of each bundled
CSL:

``` yaml
- name: harvard-manchester
  url: https://raw.githubusercontent.com/.../harvard-cite-them-right.csl
  retrieved: '2026-06-02'
  sha256: 0ca3d2c7...
```

When a new version of the package is built, `dev/sync_shared.R`
re-downloads each file, verifies the sha256, and updates `SOURCES.yml`
if the upstream file has changed. This means you can always tell exactly
which version of a CSL style your thesis used and reproduce it from the
hash. The
[`list_csl()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/list_csl.md)
function surfaces this information directly:

``` r

# View provenance of all bundled styles
list_csl()[, c("name", "retrieved", "sha256")]
```
