load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("//conda/environment:providers.bzl", "EnvironmentInfo")

_ENV_ROOT_PLACEHOLDER = "__rules_conda_env__"

def _decode_link_entry(entry):
    if "|" not in entry:
        return struct(type = "flag", value = entry)
    parts = entry.split("|")
    if not parts:
        fail("Malformed link entry `{}`".format(entry))
    kind = parts[0]
    if kind == "F":
        if len(parts) != 2:
            fail("Flag entry `{}` must have exactly one value".format(entry))
        return struct(type = "flag", value = parts[1])
    if kind == "S":
        if len(parts) != 2:
            fail("Static entry `{}` must have exactly one value".format(entry))
        return struct(type = "static", path = parts[1])
    if kind == "D":
        if len(parts) < 2:
            fail("Dynamic entry `{}` missing library path".format(entry))
        library = parts[1]
        interface = ""
        if len(parts) >= 3:
            interface = parts[2]
        return struct(type = "dynamic", library = library, interface = interface)
    fail("Unknown link entry kind `{}`".format(kind))

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

def _pkg_config_import_impl(ctx):
    env_info = ctx.attr.environment[EnvironmentInfo]
    dir_info = env_info.files
    env_root = dir_info.path

    expanded_cflag_flags = [_expand_placeholder(flag, env_root) for flag in ctx.attr.cflags]
    cflags = _parse_cflags(expanded_cflag_flags)
    link_entries = ctx.attr.link_entries

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

    for entry_str in link_entries:
        entry = _decode_link_entry(entry_str)
        kind = entry.type
        if kind == "flag":
            _add_flag_input(_expand_placeholder(entry.value, env_root))
        elif kind == "static":
            path = entry.path
            file = dir_info.get_file(path)
            if file == None:
                fail("Could not find static library `{}` within environment".format(path))
            library_to_link = cc_common.create_library_to_link(
                actions = ctx.actions,
                cc_toolchain = cc_toolchain,
                feature_configuration = feature_configuration,
                static_library = file,
            )
            linker_inputs.append(
                cc_common.create_linker_input(
                    owner = ctx.label,
                    libraries = depset([library_to_link]),
                    user_link_flags = depset(),
                ),
            )
        elif kind == "dynamic":
            library_path = entry.library
            dynamic_file = dir_info.get_file(library_path)
            if dynamic_file == None:
                fail("Could not find dynamic library `{}` within environment".format(library_path))
            interface_path = entry.interface
            interface_file = None
            if interface_path not in ["", None]:
                interface_file = dir_info.get_file(interface_path)
                if interface_file == None:
                    fail("Could not find interface library `{}` within environment".format(interface_path))
            library_to_link = cc_common.create_library_to_link(
                actions = ctx.actions,
                cc_toolchain = cc_toolchain,
                feature_configuration = feature_configuration,
                dynamic_library = dynamic_file,
                interface_library = interface_file,
            )
            linker_inputs.append(
                cc_common.create_linker_input(
                    owner = ctx.label,
                    libraries = depset([library_to_link]),
                    user_link_flags = depset(),
                ),
            )
        else:
            fail("Unknown link entry type `{}` in {}".format(kind, ctx.label))

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
        "link_entries": attr.string_list(),
    },
    provides = [CcInfo],
    doc = "Creates a CcInfo provider based on pkg-config metadata.",
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
)
