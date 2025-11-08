load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("//conda/environment:providers.bzl", "EnvironmentInfo")

_ENV_ROOT_PLACEHOLDER = "__rules_conda_env__"

def _normalize_relative_path(path):
    normalized = path.replace("\\", "/")
    if normalized in ["", ".", "./"]:
        return ""
    result = paths.normalize(normalized)
    return "" if result in ["", "."] else result

def _expand_placeholder(value, env_root):
    if _ENV_ROOT_PLACEHOLDER not in value:
        return value
    return value.replace(_ENV_ROOT_PLACEHOLDER, env_root)

def _relativize_to_env(path, env_root):
    normalized_root = paths.normalize(env_root.replace("\\", "/"))
    normalized_path = paths.normalize(path.replace("\\", "/"))
    if normalized_path == normalized_root:
        return ""
    if paths.starts_with(normalized_path, normalized_root):
        remainder = paths.relativize(normalized_path, normalized_root)
        return "" if remainder in ["", "."] else remainder
    if paths.is_absolute(normalized_path):
        return None
    relative = _normalize_relative_path(path)
    return relative if relative != "" else None

def _parse_cflags(flag_values):
    includes = []
    defines = []
    others = []
    for flag in flag_values:
        if flag.startswith("-I"):
            path = flag.removeprefix("-I")
            if path == "":
                fail("`-I` flag must be immediately followed by a path")
            includes.append(path)
        elif flag.startswith("-D"):
            define = flag.removeprefix("-D")
            if define == "":
                fail("`-D` flag must be immediately followed by a define")
            defines.append(define)
        else:
            others.append(flag)
    return struct(
        includes = includes,
        defines = defines,
        others = others,
    )

def _parse_libs(flag_values):
    lib_dirs = []
    libs = []
    other = []
    for flag in flag_values:
        if flag.startswith("-L"):
            directory = flag.removeprefix("-L")
            if directory == "":
                fail("`-L` flag must be immediately followed by a path")
            lib_dirs.append(directory)
        elif flag.startswith("-l"):
            library = flag.removeprefix("-l")
            if library == "":
                fail("`-l` flag must be immediately followed by a library")
            libs.append(library)
        else:
            other.append(flag)
    return struct(
        lib_dirs = lib_dirs,
        libs = libs,
        other = other,
    )

def _first_match(dir_info, pattern):
    matches = dir_info.glob(include = [pattern], allow_empty = True).to_list()
    if not matches:
        return None
    matches = sorted(matches, key = lambda f: f.path)
    return matches[0]

def _resolve_library_files(dir_info, lib_dirs, libs, static, shared_exts, static_exts, lib_prefix):
    entries = []
    if not libs:
        return entries

    extensions = static_exts + shared_exts if static else shared_exts
    search_dirs = lib_dirs if lib_dirs else [""]

    for lib in libs:
        found = None
        for directory in search_dirs:
            prefix = lib_prefix + lib
            for ext in extensions:
                relative = prefix + ext
                candidate = paths.normalize(paths.join(directory, relative)) if directory else relative
                match = _first_match(dir_info, candidate)
                if match:
                    found = match
                    break
            if found:
                break
        if found:
            entries.append(struct(file = found, unresolved = None))
        else:
            entries.append(struct(file = None, unresolved = lib))

    return entries

def _library_extensions(ctx):
    if ctx.target_platform_has_constraint(ctx.attr._macos[platform_common.ConstraintValueInfo]):
        return struct(shared_exts = [".*.dylib", ".dylib"], static_exts = [".a"], lib_prefix = "lib")
    if ctx.target_platform_has_constraint(ctx.attr._windows[platform_common.ConstraintValueInfo]):
        return struct(shared_exts = [".dll", ".dll.a"], static_exts = [".lib"], lib_prefix = "")
    return struct(shared_exts = [".so.*", ".so"], static_exts = [".a"], lib_prefix = "lib")

def _pkg_config_import_impl(ctx):
    env_info = ctx.attr.environment[EnvironmentInfo]
    dir_info = env_info.files
    env_root = dir_info.path

    expanded_cflag_flags = [_expand_placeholder(flag, env_root) for flag in ctx.attr.cflags]
    expanded_lib_flags = [_expand_placeholder(flag, env_root) for flag in ctx.attr.libs]

    cflags = _parse_cflags(expanded_cflag_flags)
    libs = _parse_libs(expanded_lib_flags)

    header_sets = []
    include_paths = []
    for include in cflags.includes:
        include_paths.append(include)
        rel = _relativize_to_env(include, env_root)
        if rel != None:
            subdir = dir_info if rel == "" else dir_info.get_subdirectory(rel)
            header_sets.append(subdir.transitive_files)

    system_includes = depset(include_paths)
    defines = depset(cflags.defines)

    lib_dirs_rel = []
    for lib_dir in libs.lib_dirs:
        rel = _relativize_to_env(lib_dir, env_root)
        if rel != None:
            lib_dirs_rel.append(rel)

    extensions = _library_extensions(ctx)
    library_entries = _resolve_library_files(
        dir_info,
        lib_dirs_rel,
        libs.libs,
        ctx.attr.static,
        extensions.shared_exts,
        extensions.static_exts,
        extensions.lib_prefix,
    )

    cc_toolchain = find_cc_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    linker_inputs = []

    def _add_flag_input(flag):
        linker_inputs.append(
            cc_common.create_linker_input(
                owner = ctx.label,
                libraries = depset(),
                user_link_flags = depset([flag]),
            ),
        )

    for flag in cflags.others:
        _add_flag_input(flag)

    entry_index = 0
    entry_count = len(library_entries)
    for flag in expanded_lib_flags:
        if flag.startswith("-L"):
            continue
        if flag.startswith("-l"):
            if entry_index >= entry_count:
                fail("No resolution entry found for flag `{}`".format(flag))
            entry = library_entries[entry_index]
            entry_index += 1
            if entry.file:
                if ctx.attr.static:
                    library_to_link = cc_common.create_library_to_link(
                        actions = ctx.actions,
                        cc_toolchain = cc_toolchain,
                        feature_configuration = feature_configuration,
                        static_library = entry.file,
                    )
                else:
                    library_to_link = cc_common.create_library_to_link(
                        actions = ctx.actions,
                        cc_toolchain = cc_toolchain,
                        feature_configuration = feature_configuration,
                        dynamic_library = entry.file,
                    )
                linker_inputs.append(
                    cc_common.create_linker_input(
                        owner = ctx.label,
                        libraries = depset([library_to_link]),
                        user_link_flags = depset(),
                    ),
                )
            else:
                _add_flag_input(flag)
        else:
            _add_flag_input(flag)

    if entry_index != entry_count:
        fail("Unconsumed library resolution entries remain; pkg-config flag parsing is inconsistent")

    compilation_context = cc_common.create_compilation_context(
        headers = depset(transitive = header_sets),
        system_includes = system_includes,
        defines = defines,
    )

    linking_context = cc_common.create_linking_context(
        linker_inputs = depset(order = "topological", direct = linker_inputs),
    )

    if ctx.attr.deps:
        dep_compilation_contexts = [d[CcInfo].compilation_context for d in ctx.attr.deps]
        dep_linking_contexts = [d[CcInfo].linking_context for d in ctx.attr.deps]
        compilation_context = cc_common.merge_compilation_contexts(
            compilation_contexts = dep_compilation_contexts + [compilation_context],
        )
        linking_context = cc_common.merge_linking_contexts(
            linking_contexts = dep_linking_contexts + [linking_context],
        )

    return [
        CcInfo(
            compilation_context = compilation_context,
            linking_context = linking_context,
        ),
        DefaultInfo(files = depset()),
    ]

pkg_config_import = rule(
    implementation = _pkg_config_import_impl,
    attrs = {
        "environment": attr.label(mandatory = True, providers = [EnvironmentInfo]),
        "deps": attr.label_list(providers = [CcInfo], default = []),
        "cflags": attr.string_list(),
        "libs": attr.string_list(),
        "static": attr.bool(default = False),
        "_macos": attr.label(default = "@platforms//os:macos"),
        "_windows": attr.label(default = "@platforms//os:windows"),
    },
    provides = [CcInfo],
    doc = "Creates a CcInfo provider based on pkg-config metadata.",
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
)
