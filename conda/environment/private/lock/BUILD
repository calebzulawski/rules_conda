load("@pypi//:requirements.bzl", "requirement")

py_binary(
    name = "lock",
    srcs = ["lock.py"],
    visibility = ["//visibility:public"],
    deps = [
        requirement("py-rattler"),
        requirement("pyyaml"),
    ],
)

exports_files([
    "lock.sh",
    "lock.bzl",
])
