load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    [
        "environment.bzl",
        "install.py",
        "parse_lockfile.py",
        "pkg_config_repo.bzl",
        "pkg_config_rule.bzl",
        "template.BUILD",
    ],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "pkg_config_repo",
    srcs = ["pkg_config_repo.bzl"],
    visibility = ["//visibility:public"],
    deps = [":pkg_config_rule"],
)

bzl_library(
    name = "pkg_config_rule",
    srcs = ["pkg_config_rule.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//conda/environment:providers",
        "@bazel_skylib//lib:paths",
        "@rules_cc//cc:find_cc_toolchain_bzl",
    ],
)
