load("@rules_python//python:pip.bzl", "compile_pip_requirements")

alias(
    name = "format",
    actual = "//tools:format",
    tags = ["manual"],
)

alias(
    name = "format.check",
    actual = "//tools:format.check",
    tags = ["manual"],
)

compile_pip_requirements(
    name = "requirements",
    requirements_in = "requirements.txt",
    requirements_txt = "requirements_lock.txt",
)
