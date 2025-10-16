load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    ["toolchain.bzl"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "toolchain",
    srcs = ["toolchain.bzl"],
    visibility = ["//visibility:public"],
    deps = ["//conda/environment:providers"],
)
