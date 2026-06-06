# Lazily read a QMD file into the context cache

Lazily read a QMD file into the context cache

## Usage

``` r
ctx_read(ctx, file)
```

## Arguments

- ctx:

  A context object produced by
  [`build_ctx()`](https://gabriel-cabrera-guz.github.io/uomthesis/reference/build_ctx.md).

- file:

  Path to the file, relative to the project root.

## Value

Character vector of lines.
