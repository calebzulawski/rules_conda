load("@aspect_bazel_lib//lib:docs.bzl", "stardoc_with_diff_test", "update_docs")

stardoc_with_diff_test(
    name = "extensions",
    bzl_library_target = "//conda/extensions:module",
)

stardoc_with_diff_test(
    name = "environment",
    bzl_library_target = "//conda/environment:defs",
)

stardoc_with_diff_test(
    name = "environment_providers",
    bzl_library_target = "//conda/environment:providers",
)

update_docs(name = "update")
