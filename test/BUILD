load("@rules_conda//:lockfile.bzl", "lock_environments")

lock_environments(
    name = "lockfile",
    environments = [
        "env1.yml",
        "env2.yml",
    ],
)

sh_test(
    name = "env_test",
    srcs = ["test.sh"],
    data = [
        "@env1//:bin/bash",
        "@env2//:bin/zsh",
    ],
    env = {
        "BASH": "$(rootpath @env1//:bin/bash)",
        "ZSH": "$(rootpath @env2//:bin/zsh)",
    },
)
