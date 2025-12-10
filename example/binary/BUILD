load("@rules_conda//conda/environment:defs.bzl", "run_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

run_binary(
    name = "python",
    environment = "@python",
    path = select({
        "@platforms//os:windows": "python.exe",
        "//conditions:default": "bin/python3",
    }),
)

run_binary(
    name = "python_by_name",
    environment = "@python",
    executable = select({
        "@platforms//os:windows": "python.exe",
        "//conditions:default": "python3",
    }),
)

sh_test(
    name = "binary_test",
    srcs = ["test.sh"],
    data = ["python"],
    env = {"PYTHON": "$(rlocationpath python)"},
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

sh_test(
    name = "binary_by_name_test",
    srcs = ["test.sh"],
    data = ["python_by_name"],
    env = {"PYTHON": "$(rlocationpath python_by_name)"},
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
