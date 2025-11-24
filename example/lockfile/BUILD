load("@rules_conda//conda/environment:defs.bzl", "lock_environments")

lock_environments(
    name = "lockfile",
    cuda_version = "10",
    environments = [
        "python-env.yml",
        "zlib-env.yml",
    ],
    glibc_version = "2.32",
    macos_version = "11",
)
