load("//environment:providers.bzl", "EnvironmentInfo", "get_files_provided_by", "what_provides")

def _conda_binary(ctx):
    info = ctx.attr.environment[EnvironmentInfo]
    package = what_provides(info, ctx.attr.path)
    files = get_files_provided_by(info, package)
    file = info.files.get_file(ctx.attr.path)
    symlink = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.symlink(output = symlink, target_file = file, is_executable = True)
    return [DefaultInfo(
        files = depset([symlink]),
        runfiles = ctx.runfiles(transitive_files = files),
        executable = symlink,
    )]

conda_binary = rule(
    doc = "Creates a binary target from an executable in an environment",
    implementation = _conda_binary,
    attrs = {
        "environment": attr.label(mandatory = True, providers = [EnvironmentInfo]),
        "path": attr.string(mandatory = True, doc = "The path of the binary"),
    },
    executable = True,
)

def _environment_glob(ctx):
    info = ctx.attr.environment[EnvironmentInfo]
    srcs = info.files.glob(
        ctx.attr.srcs,
        exclude = ctx.attr.exclude,
        allow_empty = ctx.attr.allow_empty,
    )
    data = info.files.glob(
        ctx.attr.data,
        exclude = ctx.attr.exclude,
        allow_empty = ctx.attr.allow_empty,
    )

    if len(ctx.attr.packages) > 0:
        files = get_files_provided_by(info, ctx.attr.packages, ctx.attr.include_package_dependencies)
        files = set(files.to_list())
        srcs = depset([f for f in srcs.to_list() if f in files])
        data = depset([f for f in data.to_list() if f in files])

    return DefaultInfo(
        files = srcs,
        runfiles = ctx.runfiles(transitive_files = depset(transitive = [srcs, data])),
    )

environment_glob = rule(
    doc = "Globs files from an environment",
    implementation = _environment_glob,
    attrs = {
        "environment": attr.label(mandatory = True, providers = [EnvironmentInfo]),
        "allow_empty": attr.bool(
            default = False,
            doc = "If true, allows globs to not match anything.",
        ),
        "data": attr.string_list(
            default = [],
            doc = """A list of globs to files within the environment to put in the runfiles.

For example, `data = ["foo/**"]` would collect all files contained within `<environment>/foo` into the
runfiles.""",
        ),
        "exclude": attr.string_list(
            default = [],
            doc = "A list of globs to files within the environment to exclude from the files and runfiles.",
        ),
        "include_package_dependencies": attr.bool(default = True, doc = "If true, includes dependencies of `packages` as well."),
        "packages": attr.string_list(
            default = [],
            doc = """A list of packages globs are allowed to match.

If empty, matches all packages.""",
        ),
        "srcs": attr.string_list(
            default = [],
            doc = """A list of globs to files within the environment to put in the files.

For example, `srcs = ["foo/**"]` would collect the file at `<environment>/foo` into the
files.""",
        ),
    },
)
