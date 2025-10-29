# End-to-end tests

This directory contains tests running the entire interpreter on program inputs.
Test suites are generated with the contents of the `negative` and `positive` sub-directories, which define use cases.
A use case is either a single Dyva source file or a directory representing a package.

A single-file test is compiled and executed, just as if it was passed as an argument to `dyva`.
A package test is processed according to the configuration specified by its manifest.

Test cases are generated automatically as part of SPM's build sequence.
You can also use `dyva-tests` to generate test cases manually.

## Passing arguments

You can add `#> --foo --bar` on the first line of a single-file test to pass custom arguments to the interpreter.
