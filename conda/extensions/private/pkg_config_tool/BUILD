load("@rules_conda//conda/environment:defs.bzl", "lock_environments")

lock_environments(
    name = "pkg_config_lock",
    environments = ["pkg-config-env.yml"],
    glibc_version = "2.32",
    lockfile = "pkg-config.lock",
    macos_version = "11",
)
