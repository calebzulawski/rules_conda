load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    ["lockfile.bzl"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "lockfile",
    srcs = ["lockfile.bzl"],
    visibility = ["//visibility:public"],
    deps = ["@rules_shell//shell:rules_bzl"],
)
