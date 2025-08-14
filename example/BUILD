load("@rules_conda//:lockfile.bzl", "lock_environments")
load("@rules_conda//environment:environment.bzl", "conda_binary")

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

conda_binary(
    name = "python",
    environment = "@env1",
    path = select({
        "@platforms//os:windows": "python.exe",
        "//conditions:default": "bin/python3",
    }),
)

conda_binary(
    name = "vim",
    environment = "@env2",
    path = select({
        "@platforms//os:windows": "Library/bin/vim.exe",
        "//conditions:default": "bin/vim",
    }),
)

sh_test(
    name = "env_test",
    srcs = ["test.sh"],
    data = [
        "python",
        "vim",
    ],
    env = {
        "PYTHON": "$(rlocationpath python)",
        "VIM": "$(rlocationpath vim)",
    },
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
