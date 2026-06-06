# Return all registered validation rules

Each element is a named list with fields: `id`, `policy_ref`, `phase`,
`formats`, `severity`, `check`, and `rationale`. The `check` field is a
function that accepts a context object (see
[`build_ctx()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/build_ctx.md))
and returns either `NULL` (pass) or a finding list.

## Usage

``` r
rule_registry()
```

## Value

A list of rule spec lists.
