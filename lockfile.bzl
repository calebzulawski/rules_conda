load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

def _location(ctx, target):
    return ctx.expand_location('"$(rlocation $(rlocationpath {}))"'.format(target.label), targets = [target])

def _lockfile_impl(ctx):
    script = ctx.actions.declare_file(ctx.attr.name)
    overrides = []
    if ctx.attr.cuda_version:
        overrides.append("export CONDA_OVERRIDE_CUDA={}".format(ctx.attr.cuda_version))
    if ctx.attr.macos_version:
        overrides.append("export CONDA_OVERRIDE_OSX={}".format(ctx.attr.macos_version))
    if ctx.attr.glibc_version:
        overrides.append("export CONDA_OVERRIDE_GLIBC={}".format(ctx.attr.glibc_version))
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = script,
        substitutions = {
            "${OVERRIDES}": "\n".join(overrides),
            "${LOCK}": _location(ctx, ctx.attr._lock_script),
            "${MODE}": ctx.attr.mode,
            "${LOCKFILE}": _location(ctx, ctx.attr.lockfile),
            "${ENVIRONMENTS}": " ".join([_location(ctx, env) for env in ctx.attr.environments]),
        },
        is_executable = True,
    )
    return DefaultInfo(files = depset([script]))

_lockfile = rule(
    implementation = _lockfile_impl,
    attrs = {
        "lockfile": attr.label(allow_single_file = True),
        "environments": attr.label_list(mandatory = True, allow_files = True),
        "cuda_version": attr.string(),
        "macos_version": attr.string(),
        "glibc_version": attr.string(),
        "mode": attr.string(),
        "_template": attr.label(default = "//private/lock:lock.sh", allow_single_file = True),
        "_lock_script": attr.label(default = "//private/lock", executable = True, cfg = "exec"),
        "_runfiles": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
    },
)

def lock_environments(
        name = None,
        environments = [],
        lockfile = "conda.lock",
        cuda_version = None,
        macos_version = None,
        glibc_version = None):
    """
    Lock Conda environments.

    Creates two targets:
    * `bazel run [name].update` to update the lockfile
    * `bazel test [name].test` to ensure the lockfile is up-to-date

    Args:
      name: The name of this rule
      environments: A list of environment files, in YAML format
      lockfile: The lockfile to create
      cuda_version: The CUDA version to use to solve
      macos_version: The macOS version to use to solve
      glibc_version: The glibc version to use to solve
    """
    _lockfile(
        name = name + ".impl.update",
        lockfile = lockfile,
        mode = "update",
        environments = environments,
        cuda_version = cuda_version,
        macos_version = macos_version,
        glibc_version = glibc_version,
    )
    _lockfile(
        name = name + ".impl.test",
        lockfile = lockfile,
        mode = "test",
        environments = environments,
        cuda_version = cuda_version,
        macos_version = macos_version,
        glibc_version = glibc_version,
    )
    sh_binary(
        name = name + ".update",
        srcs = [name + ".impl.update"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [lockfile, Label("//private/lock")] + environments,
    )
    sh_test(
        name = name + ".test",
        srcs = [name + ".impl.test"],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        data = [lockfile, Label("//private/lock")] + environments,
    )
