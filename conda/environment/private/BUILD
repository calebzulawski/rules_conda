load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    glob(["*.bzl"]),
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "private",
    srcs = [
        "environment_glob.bzl",
        "run_binary.bzl",
    ],
    visibility = ["//visibility:public"],
    deps = ["//conda/environment:providers"],
)
