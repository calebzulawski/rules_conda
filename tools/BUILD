load("@aspect_rules_lint//format:defs.bzl", "format_multirun")

format_multirun(
    name = "format",
    python = "@aspect_rules_lint//format:ruff",
    shell = "@aspect_rules_lint//format:shfmt",
    starlark = "@buildifier_prebuilt//:buildifier",
    visibility = ["//:__pkg__"],
    yaml = "@aspect_rules_lint//format:yamlfmt",
)
