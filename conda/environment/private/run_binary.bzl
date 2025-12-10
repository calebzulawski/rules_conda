load("@bazel_skylib//lib:paths.bzl", "paths")
load("//conda/environment:providers.bzl", "EnvironmentInfo", "get_files_provided_by", "what_provides")

def _is_windows(ctx):
    return ctx.configuration.host_path_separator == ";"

def _default_search_paths(ctx):
    if _is_windows(ctx):
        return [
            ".",
            "Library/mingw-w64/bin",
            "Library/usr/bin",
            "Library/bin",
            "Scripts",
            "bin",
        ]
    return ["bin"]

def _get_file_if_exists(info, path):
    if "*" in path:
        fail("run_binary: path '{path}' contains '*' but globs are not permitted.".format(path = path))
    matches = info.files.glob(include = [path], exclude = [], allow_empty = True).to_list()
    if len(matches) == 0:
        return None
    return matches[0]

def _find_executable(ctx, info, executable):
    search_paths = ctx.attr.search_paths if len(ctx.attr.search_paths) > 0 else _default_search_paths(ctx)
    for directory in search_paths:
        candidate = paths.join(directory, executable)
        candidate = candidate.lstrip("./").lstrip("/")
        candidate_file = _get_file_if_exists(info, candidate)
        if candidate_file != None:
            return candidate, candidate_file
    fail("run_binary target '{label}': executable '{exe}' was not found in any search path: {paths}".format(
        label = ctx.label,
        exe = executable,
        paths = ", ".join(search_paths),
    ))

def _run_binary(ctx):
    info = ctx.attr.environment[EnvironmentInfo]
    file = None
    relative_path = None

    if ctx.attr.path != "":
        relative_path = ctx.attr.path
        file = _get_file_if_exists(info, relative_path)
        if file == None:
            fail("run_binary target '{label}': file '{path}' was not found in the provided environment".format(
                label = ctx.label,
                path = relative_path,
            ))
    else:
        if ctx.attr.executable == "":
            fail("run_binary target '{label}': either 'path' or 'executable' must be set".format(label = ctx.label))
        relative_path, file = _find_executable(ctx, info, ctx.attr.executable)

    package = what_provides(info, relative_path)
    files = get_files_provided_by(info, package)
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
        "path": attr.string(
            default = "",
            doc = "Explicit relative path of the binary within the environment. Set either this or `executable`.",
        ),
        "executable": attr.string(
            default = "",
            doc = "Executable filename (no directories). Used together with `search_paths` to locate the binary by name. Set either this or `path`.",
        ),
        "search_paths": attr.string_list(
            default = [],
            doc = "Directories to search for `executable`. Defaults to ['bin'] on Linux/macOS and ['.', 'Library/mingw-w64/bin', 'Library/usr/bin', 'Library/bin', 'Scripts', 'bin'] on Windows.",
        ),
    },
    executable = True,
)
