load("//conda/environment:providers.bzl", "EnvironmentInfo", "get_files_provided_by", "what_provides")

def _is_windows(ctx):
    return ctx.configuration.host_path_separator == ";"

def _run_binary(ctx):
    info = ctx.attr.environment[EnvironmentInfo]
    package = what_provides(info, ctx.attr.path)
    files = get_files_provided_by(info, package)
    file = info.files.get_file(ctx.attr.path)
    if _is_windows(ctx):
        exe = ctx.actions.declare_file(ctx.label.name + ".bat")
        target_path = file.path.removeprefix("external/").replace("/", "\\")
        script = '@echo off\r\n"../{target}" %*\r\n'.format(target = target_path)
        ctx.actions.write(
            output = exe,
            content = script,
            is_executable = True,
        )
    else:
        exe = ctx.actions.declare_file(ctx.attr.name)
        ctx.actions.symlink(output = exe, target_file = file, is_executable = True)
    return [DefaultInfo(
        files = depset([exe]),
        runfiles = ctx.runfiles(transitive_files = files),
        executable = exe,
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
