# List bundled citation styles

Returns a data frame describing the CSL files bundled with the package.
Each row corresponds to one style file in `inst/csl/`.

## Usage

``` r
list_csl()
```

## Value

A data.frame with one row per bundled CSL, columns: `name`, `url`,
`retrieved`, `sha256`.

## Examples

``` r
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
