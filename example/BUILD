load("@rules_conda//:lockfile.bzl", "lock_environments")

lock_environments(
    name = "lockfile",
    cuda_version = "10",
    environments = [
        "env1.yml",
        "env2.yml",
    ],
    glibc_version = "2.32",
    macos_version = "11",
)

sh_test(
    name = "env_test",
    srcs = ["test.sh"],
    data = select({
        "@platforms//os:windows": [
            "@env1//:python.exe",
            "@env2//:Library/bin/vim.exe",
        ],
        "//conditions:default": [
            "@env1//:bin/python3",
            "@env2//:bin/vim",
        ],
    }),
    env = select({
        "@platforms//os:windows": {
            "PYTHON": "$(rlocationpath @env1//:python.exe)",
            "VIM": "$(rlocationpath @env2//:Library/bin/vim.exe)",
        },
        "//conditions:default": {
            "PYTHON": "$(rlocationpath @env1//:bin/python3)",
            "VIM": "$(rlocationpath @env2//:bin/vim)",
        },
    }),
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
