"""Link-entry helpers for pkg-config repository logic."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//conda/extensions/private:pkg_config_repo_paths.bzl", "find_file_by_name", "find_file_with_extensions", "relativize_to_env")
load("//conda/extensions/private:pkg_config_repo_tools.bzl", "identify_windows_dll", "shared_library_name")

_ENV_ROOT_PLACEHOLDER = "__rules_conda_env__"

def _library_config(platform):
    if not platform:
        platform = ""
    if platform.startswith("win"):
        return struct(
            prefixes = ["", "lib"],
            shared_exts = [".dll"],
            static_exts = [".a", ".lib"],
            interface_exts = [".dll.a", ".lib"],
            dll_dirs = ["Library/bin", "bin"],
        )
    if platform.startswith("osx"):
        return struct(
            prefixes = ["lib"],
            shared_exts = [".*.dylib", ".dylib"],
            static_exts = [".a"],
            interface_exts = None,
            dll_dirs = [],
        )
    return struct(
        prefixes = ["lib"],
        shared_exts = [".so.*", ".so"],
        static_exts = [".a"],
        interface_exts = None,
        dll_dirs = [],
    )

def with_placeholder(flag, root):
    normalized = root.rstrip("/\\")
    variants = [normalized]
    forward = normalized.replace("\\", "/")
    backward = normalized.replace("/", "\\")
    if forward not in variants:
        variants.append(forward)
    if backward not in variants:
        variants.append(backward)

    rewritten = flag
    for variant in variants:
        rewritten = rewritten.replace(variant, _ENV_ROOT_PLACEHOLDER)
    return rewritten

def relativize_flags(flags, root):
    return [with_placeholder(flag, root) for flag in flags]

def flag_entry(flag, env_root_str):
    return with_placeholder(flag, env_root_str)

def static_entry(path):
    return "|".join(["S", path])

def dynamic_entry(library, interface):
    interface_field = interface if interface else ""
    return "|".join(["D", library, interface_field])

def _resolve_windows_dynamic_library(rctx, env_root, env_root_str, lib_dirs, interface, config):
    dll_name = identify_windows_dll(rctx, interface.absolute)
    if not dll_name:
        return None

    interface_dir = paths.dirname(interface.relative)
    if interface_dir in ["", "."]:
        interface_dir = ""

    candidate_dirs = []
    if interface_dir != "":
        candidate_dirs.append(interface_dir)
    candidate_dirs.extend(lib_dirs)
    for lib_dir in lib_dirs:
        stripped = lib_dir.removesuffix("/lib")
        if stripped != lib_dir:
            candidate_dirs.append(paths.join(stripped, "bin"))
    candidate_dirs.extend(config.dll_dirs)
    candidate_dirs = [d for d in candidate_dirs if d not in ["", None]]

    dll_entry = find_file_by_name(env_root, env_root_str, candidate_dirs, dll_name)
    if not dll_entry:
        return None

    return dynamic_entry(dll_entry.relative, interface.relative)

def _resolve_posix_shared_library(rctx, env_root, env_root_str, lib_dirs, match, platform):
    soname = shared_library_name(rctx, match.absolute, platform)
    if not soname:
        return match.relative
    if "/" in soname or "\\" in soname or soname.startswith("@"):
        return match.relative

    match_dir = paths.dirname(match.relative)
    candidate_dirs = []
    if match_dir not in ["", "."]:
        candidate_dirs.append(match_dir)
    candidate_dirs.extend(lib_dirs)
    replacement = find_file_by_name(env_root, env_root_str, candidate_dirs, soname)
    if replacement:
        return replacement.relative
    return match.relative

def _resolve_library_entry(rctx, env_root, env_root_str, lib_dirs, lib_name, static, platform_config, platform):
    literal = lib_name.startswith(":")
    normalized_name = lib_name.removeprefix(":") if literal else lib_name
    candidate_bases = [normalized_name] if literal else [prefix + normalized_name for prefix in platform_config.prefixes]

    if static:
        match = find_file_with_extensions(env_root, env_root_str, lib_dirs, candidate_bases, platform_config.static_exts)
        if match:
            return static_entry(match.relative)
        return None

    if platform_config.interface_exts:
        interface = find_file_with_extensions(env_root, env_root_str, lib_dirs, candidate_bases, platform_config.interface_exts)
        if interface:
            if platform_config.dll_dirs:
                resolved = _resolve_windows_dynamic_library(
                    rctx,
                    env_root,
                    env_root_str,
                    lib_dirs,
                    interface,
                    platform_config,
                )
                if resolved:
                    return resolved
            else:
                return dynamic_entry(interface.relative, "")

    match = find_file_with_extensions(env_root, env_root_str, lib_dirs, candidate_bases, platform_config.shared_exts)
    if match:
        shared_path = match.relative
        if not platform.startswith("win"):
            shared_path = _resolve_posix_shared_library(
                rctx,
                env_root,
                env_root_str,
                lib_dirs,
                match,
                platform,
            )
        return dynamic_entry(shared_path, "")
    return None

def resolve_link_entries(rctx, env_root, env_root_str, lib_args, static, platform):
    config = _library_config(platform)
    if platform.startswith("win"):
        static = False
    lib_dirs = []
    for flag in lib_args:
        if flag.startswith("-L"):
            directory = flag.removeprefix("-L")
            if directory == "":
                fail("`-L` flag must be immediately followed by a path")
            rel = relativize_to_env(directory, env_root_str)
            if rel != None:
                lib_dirs.append(rel)

    entries = []
    for flag in lib_args:
        if flag.startswith("-L"):
            continue
        if flag.startswith("-l"):
            lib_name = flag.removeprefix("-l")
            if lib_name == "":
                fail("`-l` flag must be immediately followed by a library")
            resolved = _resolve_library_entry(
                rctx,
                env_root,
                env_root_str,
                lib_dirs,
                lib_name,
                static,
                config,
                platform,
            )
            if resolved:
                entries.append(resolved)
            else:
                entries.append(flag_entry(flag, env_root_str))
        else:
            entries.append(flag_entry(flag, env_root_str))
    return entries
