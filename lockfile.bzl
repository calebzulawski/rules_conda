def _location(ctx, target):
    return ctx.expand_location('"$(rootpath {})"'.format(target.label), targets = [target])

def _lockfile_impl(ctx):
    update_script = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = update_script,
        substitutions = {
            "${LOCK}": _location(ctx, ctx.attr._lock_script),
            "${MODE}": "test" if ctx.attr._test else "update",
            "${LOCKFILE}": _location(ctx, ctx.attr.lockfile),
            "${ENVIRONMENTS}": " ".join([_location(ctx, env) for env in ctx.attr.environments]),
        },
        is_executable = True,
    )
    return DefaultInfo(
        runfiles = ctx.runfiles(files = ctx.files.environments + ctx.files.lockfile).merge(ctx.attr._lock_script[DefaultInfo].default_runfiles),
        executable = update_script,
    )

common_attrs = {
    "lockfile": attr.label(allow_single_file = True),
    "environments": attr.label_list(mandatory = True, allow_files = True),
    "_template": attr.label(default = "//private/lock:lock.sh", allow_single_file = True),
    "_lock_script": attr.label(default = "//private/lock", executable = True, cfg = "exec"),
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
        lockfile = "conda.lock"):
    """
    Lock Conda environments.

    Creates two targets:
    * `bazel run [name].update` to update the lockfile
    * `bazel test [name].test` to ensure the lockfile is up-to-date

    Args:
      name: The name of this rule
      environments: A list of environment files, in YAML format
      lockfile: The lockfile to create
    """
    _lockfile_update(
        name = name + ".update",
        lockfile = lockfile,
        environments = environments,
    )
    _lockfile_test(
        name = name + ".test",
        lockfile = lockfile,
        environments = environments,
    )
