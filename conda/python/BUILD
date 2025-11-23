load("@aspect_bazel_lib//:bzl_library.bzl", "bzl_library")

exports_files(
    ["toolchain.bzl"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "toolchain",
    srcs = ["toolchain.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//conda/environment:providers",
        "@rules_python//python:py_runtime_bzl",
        "@rules_python//python:py_runtime_pair_bzl",
    ],
)
