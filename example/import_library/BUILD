load("@rules_conda//environment:defs.bzl", "import_library")

import_library(
    name = "zlib",
    environment = "@zlib",
    interface_library = select({
        "@platforms//os:windows": "Library/lib/zlib.lib",
        "//conditions:default": None,
    }),
    packages = ["zlib"],
    shared_library = select({
        "@platforms//os:windows": "zlib.dll",
        "@platforms//os:macos": "lib/libz.1.dylib",
        "//conditions:default": "lib/libz.so.1",
    }),
)

cc_test(
    name = "import_library_test",
    srcs = ["test.cpp"],
    deps = ["zlib"],
)
