""" Rules for creating lockfiles. """

def _location(ctx, target):
    return ctx.expand_location("$(rlocationpath {})".format(target.label), targets = [target])

def _lockfile_impl(ctx):
    overrides = {}
    for override in ["cuda_version", "macos_version", "glibc_version"]:
        value = getattr(ctx.attr, override)
        if value:
            overrides[override] = value

    config = ctx.actions.declare_file(ctx.attr.name + ".config.json")
    ctx.actions.write(
        output = config,
        content = json.encode({
            "lockfile": _location(ctx, ctx.attr.lockfile),
            "environments": [_location(ctx, env) for env in ctx.attr.environments],
            "overrides": overrides,
        }),
    )
    outputs = [config]
    for mode in ["update", "test"]:
        runner = ctx.actions.declare_file("{}.{}.py".format(ctx.attr.name, mode))
        ctx.actions.write(
            output = runner,
            content = """from conda.environment.private.lock import lock

if __name__ == "__main__":
    lock.run_config("{config}", "{mode}")
""".format(
                config = config.short_path,
                mode = mode,
            ),
            is_executable = True,
        )
        outputs.append(runner)
    return DefaultInfo(
        files = depset(outputs),
        runfiles = ctx.runfiles(files = [config]),
    )

_lockfile = rule(
    implementation = _lockfile_impl,
    attrs = {
        "lockfile": attr.label(allow_single_file = True),
        "environments": attr.label_list(mandatory = True, allow_files = True),
        "cuda_version": attr.string(),
        "macos_version": attr.string(),
        "glibc_version": attr.string(),
    },
)

def lock_environments(
        name = None,
        environments = [],
        lockfile = "conda.lock",
        cuda_version = None,
        macos_version = None,
        glibc_version = None,
        visibility = ["//visibility:private"],
        tags = [],
        **kwargs):
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
      visibility: passed to both .update and .test
      tags: passed to both .update and .test
      **kwargs: additional arguments passed to .test
    """
    _lockfile(
        name = name + ".impl",
        lockfile = lockfile,
        environments = environments,
        cuda_version = cuda_version,
        macos_version = macos_version,
        glibc_version = glibc_version,
    )
    native.py_binary(
        name = name + ".update",
        srcs = [name + ".impl"],
        main = name + ".impl.update.py",
        deps = [Label("//conda/environment/private/lock:lock_lib")],
        data = [lockfile] + environments,
        visibility = visibility,
        tags = tags,
    )
    native.py_test(
        name = name + ".test",
        srcs = [name + ".impl"],
        main = name + ".impl.test.py",
        deps = [Label("//conda/environment/private/lock:lock_lib")],
        data = [lockfile] + environments,
        visibility = visibility,
        tags = tags,
        **kwargs
    )
