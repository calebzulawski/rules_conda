load("@rules_conda//environment:environment.bzl", "environment_glob")

environment_glob(
    name = "headers",
    srcs = ["include/**"],
    environment = "@zlib",
)

environment_glob(
    name = "library",
    srcs = select({
        "@platforms//os:windows": ["Library/lib/zlib.lib"],
        "//conditions:default": ["lib/libz.so.1"],
    }),
    environment = "@zlib",
)

alias(
    name = "zlib.h",
    actual = select({
        "@platforms//os:windows": "@zlib//:Library/include/zlib.h",
        "//conditions:default": "@zlib//:include/zlib.h",
    }),
)

cc_library(
    name = "zlib",
    srcs = ["library"],
    hdrs = ["headers"],

    # this should be `additional_compiler_inputs`, but `includes` doesn't seem to check it
    data = ["zlib.h"],

    # is there a better way to do this? maybe!
    includes = ["../$(execpath zlib.h)/.."],
)

cc_test(
    name = "glob_test",
    srcs = ["test.cpp"],
    data = select({
        "@platforms//os:windows": ["@zlib//:zlib.dll"],
        "//conditions:default": [],
    }),
    deps = ["zlib"],
)
