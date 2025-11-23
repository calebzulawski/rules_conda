load("@aspect_bazel_lib//:bzl_library.bzl", "bzl_library")

exports_files(
    glob(["*.bzl"]),
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "private",
    srcs = [
        "environment_glob.bzl",
        "run_binary.bzl",
        "//conda/environment/private/lock:lock.bzl",
    ],
    visibility = ["//visibility:public"],
    deps = [
        "//conda/environment:providers",
        "@rules_shell//shell:rules_bzl",
    ],
)
