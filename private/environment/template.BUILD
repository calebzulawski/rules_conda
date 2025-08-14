load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@rules_conda//private/environment:environment.bzl", "environment")

filtered_files = [f for f in glob(
    ["**/*"],
) if ":" not in f]

exports_files(filtered_files)

metadata = """
{{metadata}}
"""

directory(name = "directory", srcs = filtered_files)

environment(
    name = "{{name}}",
    dir = "directory",
    metadata = metadata,
    visibility = ["//visibility:public"],
)
