# Validate the uomthesis: YAML block in a project

Runs the metadata-level checks (a subset of
[`check_thesis()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/check_thesis.md)'s
source-phase rules) without touching any chapter content.

## Usage

``` r
validate_metadata(project = ".")
```

## Arguments

- project:

  Path to project root.

## Value

An object of class `uomthesis_metadata_check` (a named list with fields
`ok` (logical) and `findings` (list of finding records)).

## Examples

``` r
if (FALSE) { # \dontrun{
validate_metadata(".")
} # }
```
