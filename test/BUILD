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
    data = [
        "@env1//:bin/python3",
        "@env2//:bin/vim",
    ],
    env = {
        "PYTHON": "$(rootpath @env1//:bin/python3)",
        "VIM": "$(rootpath @env2//:bin/vim)",
    },
)
