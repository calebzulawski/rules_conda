load("@rules_conda//environment:environment.bzl", "environment_glob")

environment_glob(
    name = "headers",
    srcs = select({
        "@platforms//os:windows": ["Library/include/**"],
        "//conditions:default": ["include/**"],
    }),
    environment = "@zlib",
)

cc_library(
    name = "import_headers",
    hdrs = ["headers"],

    # this should be `additional_compiler_inputs`, but `includes` doesn't seem to check it
    data = select({
        "@platforms//os:windows": ["@zlib//:Library/include/zlib.h"],
        "//conditions:default": ["@zlib//:include/zlib.h"],
    }),

    # is there a better way to do this? maybe!
    includes = select({
        "@platforms//os:windows": ["../$(execpath @zlib//:Library/include/zlib.h)/.."],
        "//conditions:default": ["../$(execpath @zlib//:include/zlib.h)/.."],
    }),
)

cc_import(
    name = "zlib",
    interface_library = select({
        "@platforms//os:windows": "@zlib//:Library/lib/zlib.lib",
        "//conditions:default": None,
    }),
    shared_library = select({
        "@platforms//os:windows": "@zlib//:zlib.dll",
        "//conditions:default": "@zlib//:lib/libz.so.1",
    }),
    deps = ["import_headers"],
)

cc_test(
    name = "glob_test",
    srcs = ["test.cpp"],
    deps = ["zlib"],
)
