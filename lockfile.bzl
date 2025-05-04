def _location(ctx, target):
    return ctx.expand_location('"$(rlocation $(rlocationpath {}))"'.format(target.label), targets = [target])

def _lockfile_impl(ctx):
    update_script = ctx.actions.declare_file(ctx.attr.name)
    overrides = []
    if ctx.attr.cuda_version:
        overrides.append("export CONDA_OVERRIDE_CUDA={}".format(ctx.attr.cuda_version))
    if ctx.attr.macos_version:
        overrides.append("export CONDA_OVERRIDE_OSX={}".format(ctx.attr.macos_version))
    if ctx.attr.glibc_version:
        overrides.append("export CONDA_OVERRIDE_GLIBC={}".format(ctx.attr.glibc_version))
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = update_script,
        substitutions = {
            "${OVERRIDES}": "\n".join(overrides),
            "${LOCK}": _location(ctx, ctx.attr._lock_script),
            "${MODE}": "test" if ctx.attr._test else "update",
            "${LOCKFILE}": _location(ctx, ctx.attr.lockfile),
            "${ENVIRONMENTS}": " ".join([_location(ctx, env) for env in ctx.attr.environments]),
        },
        is_executable = True,
    )
    return DefaultInfo(
        runfiles = ctx.runfiles(files = ctx.files.environments + ctx.files.lockfile + ctx.files._runfiles).merge(ctx.attr._lock_script[DefaultInfo].default_runfiles),
        executable = update_script,
    )

common_attrs = {
    "lockfile": attr.label(allow_single_file = True),
    "environments": attr.label_list(mandatory = True, allow_files = True),
    "cuda_version": attr.string(),
    "macos_version": attr.string(),
    "glibc_version": attr.string(),
    "_template": attr.label(default = "//private/lock:lock.sh", allow_single_file = True),
    "_lock_script": attr.label(default = "//private/lock", executable = True, cfg = "exec"),
    "_runfiles": attr.label(default = "@bazel_tools//tools/bash/runfiles"),
}

_lockfile_update = rule(
    implementation = _lockfile_impl,
    attrs = common_attrs | {
        "_test": attr.bool(default = False),
    },
    executable = True,
)

_lockfile_test = rule(
    implementation = _lockfile_impl,
    attrs = common_attrs | {
        "_test": attr.bool(default = True),
    },
    test = True,
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
    _lockfile_update(
        name = name + ".update",
        lockfile = lockfile,
        environments = environments,
        cuda_version = cuda_version,
        macos_version = macos_version,
        glibc_version = glibc_version,
    )
    _lockfile_test(
        name = name + ".test",
        lockfile = lockfile,
        environments = environments,
        cuda_version = cuda_version,
        macos_version = macos_version,
        glibc_version = glibc_version,
    )
