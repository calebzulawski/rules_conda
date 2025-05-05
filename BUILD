load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_python//python:pip.bzl", "compile_pip_requirements")

alias(
    name = "format",
    actual = "//tools:format",
)

alias(
    name = "format.check",
    actual = "//tools:format.check",
)

compile_pip_requirements(
    name = "requirements",
    requirements_in = "requirements.txt",
    requirements_txt = "requirements_lock.txt",
)

exports_files(
    glob(["*.bzl"]),
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "extensions",
    srcs = ["extensions.bzl"],
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "lockfile",
    srcs = ["lockfile.bzl"],
    visibility = ["//visibility:public"],
    deps = ["@rules_shell//shell:rules_bzl"],
)
