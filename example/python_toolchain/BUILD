load("@rules_conda//:python.bzl", "conda_python_toolchain")

conda_python_toolchain(
    name = "conda_python_toolchain",
    environment = "@python",
)

toolchain(
    name = "python_toolchain",
    toolchain = "conda_python_toolchain",
    toolchain_type = "@bazel_tools//tools/python:toolchain_type",
    visibility = ["//visibility:public"],
)

py_test(
    name = "toolchain_test",
    srcs = ["toolchain_test.py"],
)
