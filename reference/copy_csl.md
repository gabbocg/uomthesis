# Copy a bundled CSL into a directory

Copies one of the bundled citation style files into a destination
directory, creating the directory if it does not already exist.

## Usage

``` r
copy_csl(name, to = ".")
```

## Arguments

- name:

  One of the names from `list_csl()$name`.

- to:

  Destination directory (created if missing).

## Value

Invisible path to the copied file.

## Examples

``` r
if (FALSE) { # \dontrun{
copy_csl("apa", to = ".")
} # }
```
