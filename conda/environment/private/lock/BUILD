load("@pypi//:requirements.bzl", "requirement")

py_library(
    name = "lock_lib",
    srcs = ["lock.py"],
    visibility = ["//visibility:public"],
    deps = [
        "@rules_python//python/runfiles",
        requirement("py-rattler"),
        requirement("pyyaml"),
    ],
)

exports_files([
    "lock.bzl",
    "lock.py",
])
