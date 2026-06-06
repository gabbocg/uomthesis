# Build a validation context object for a given project

Build a validation context object for a given project

## Usage

``` r
build_ctx(project_path, rendered_pdf = NULL)
```

## Arguments

- project_path:

  Path to the project root (must contain \_quarto.yml and index.qmd).

- rendered_pdf:

  Optional path to a rendered PDF file.

## Value

A named list used as the context argument to each rule's check function.
