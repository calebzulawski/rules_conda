load("@rules_conda//environment:environment.bzl", "conda_binary")

conda_binary(
    name = "python",
    environment = "@python",
    path = select({
        "@platforms//os:windows": "python.exe",
        "//conditions:default": "bin/python3",
    }),
)

sh_test(
    name = "binary_test",
    srcs = ["test.sh"],
    data = ["python"],
    env = {"PYTHON": "$(rootpath python)"},
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
