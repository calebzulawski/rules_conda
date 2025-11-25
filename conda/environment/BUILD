load("@bazel_lib//:bzl_library.bzl", "bzl_library")

exports_files(
    glob(["*.bzl"]),
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "defs",
    srcs = ["defs.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "providers",
        "//conda/environment/private",
    ],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
    visibility = ["//visibility:public"],
)
