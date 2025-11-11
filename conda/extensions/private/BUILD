load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(
    [
        "environment.bzl",
        "get_dll_from_import_lib.py",
        "install.py",
        "parse_lockfile.py",
        "pkg_config_repo_linker.bzl",
        "pkg_config_repo_paths.bzl",
        "pkg_config_repo.bzl",
        "pkg_config_rule.bzl",
        "pkg_config_repo_tools.bzl",
        "template.BUILD",
    ],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "pkg_config_repo",
    srcs = ["pkg_config_repo.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        ":pkg_config_repo_linker",
        ":pkg_config_repo_paths",
        ":pkg_config_repo_tools",
        ":pkg_config_rule",
    ],
)

bzl_library(
    name = "pkg_config_repo_paths",
    srcs = ["pkg_config_repo_paths.bzl"],
    visibility = ["//visibility:public"],
    deps = ["@bazel_skylib//lib:paths"],
)

bzl_library(
    name = "pkg_config_repo_tools",
    srcs = ["pkg_config_repo_tools.bzl"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "pkg_config_repo_linker",
    srcs = ["pkg_config_repo_linker.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        ":pkg_config_repo_paths",
        ":pkg_config_repo_tools",
        "@bazel_skylib//lib:paths",
    ],
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
