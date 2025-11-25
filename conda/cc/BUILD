load("@bazel_lib//:bzl_library.bzl", "bzl_library")

exports_files(
    ["import.bzl"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "import",
    srcs = ["import.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//conda/environment:providers",
        "@bazel_skylib//lib:paths",
        "@rules_cc//cc:find_cc_toolchain_bzl",
    ],
)
