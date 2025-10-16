load("//conda/environment:providers.bzl", "EnvironmentInfo", "get_files_provided_by", "what_provides")

def _run_binary(ctx):
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

run_binary = rule(
    doc = "Creates a binary target from an executable in an environment",
    implementation = _run_binary,
    attrs = {
        "environment": attr.label(mandatory = True, providers = [EnvironmentInfo]),
        "path": attr.string(mandatory = True, doc = "The path of the binary"),
    },
    executable = True,
)
