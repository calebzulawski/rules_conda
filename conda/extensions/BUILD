load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    ["module.bzl"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "module",
    srcs = ["module.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//conda/extensions/private:pkg_config_repo",
    ],
)
