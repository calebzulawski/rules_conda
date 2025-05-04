load("@aspect_rules_lint//format:defs.bzl", "format_multirun")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")

compile_pip_requirements(
    name = "requirements",
    requirements_in = "requirements.txt",
    requirements_txt = "requirements_lock.txt",
)

format_multirun(
    name = "format",
    python = "@aspect_rules_lint//format:ruff",
    shell = "@aspect_rules_lint//format:shfmt",
    starlark = "@buildifier_prebuilt//:buildifier",
    yaml = "@aspect_rules_lint//format:yamlfmt",
)
