cc_test(
    name = "libpng_pkg_config_test",
    srcs = ["test.cpp"],
    target_compatible_with = select({
        "@platforms//os:windows": ["@platforms//:incompatible"],
        "//conditions:default": [],
    }),
    deps = ["@libpng//pkg_config:libpng"],
)

cc_test(
    name = "libpng_static_pkg_config_test",
    srcs = ["test.cpp"],
    target_compatible_with = select({
        "@platforms//os:windows": ["@platforms//:incompatible"],
        "//conditions:default": [],
    }),
    deps = ["@libpng//pkg_config:libpng-static"],
)
