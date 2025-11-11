"""Helpers for generating pkg-config based targets inside a Conda environment repo."""

load("//conda/extensions/private:pkg_config_repo_linker.bzl", "relativize_flags", "resolve_link_entries")
load("//conda/extensions/private:pkg_config_repo_paths.bzl", "env_path", "pkg_config_paths")
load("//conda/extensions/private:pkg_config_repo_tools.bzl", "pkg_config_binary")
load("//conda/extensions/private:pkg_config_rule.bzl", "pkg_config_import")

def _quote_string(value):
    escaped = (
        value
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\b", "\\b")
            .replace("\f", "\\f")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    )
    return "\"{}\"".format(escaped)

def _format_string_list(values):
    return "[" + ", ".join([_quote_string(v) for v in values]) + "]"

def _run_pkg_config(rctx, argv, env):
    result = rctx.execute(argv, environment = env)
    if result.return_code != 0:
        fail("pkg-config failed with {}\nstdout:\n{}\nstderr:\n{}".format(result.return_code, result.stdout, result.stderr))
    output = result.stdout.replace("\n", " ").strip()
    if output == "":
        return []
    return [flag.strip() for flag in output.split(" ")]

def write_pkg_config_targets(rctx, entries, environment_target):
    if not entries:
        return

    env_root = rctx.path("")
    env_root_str = env_path(str(env_root))
    pkg_config_bin = pkg_config_binary(rctx)
    platform = rctx.attr.platform
    lines = ["load(\"@rules_conda//conda/extensions/private:pkg_config_rule.bzl\", \"pkg_config_import\")", ""]

    pathsep = ";" if rctx.os.name.startswith("windows") else ":"
    for entry in entries:
        entry_static = entry["static"] and not platform.startswith("win")
        modules = entry["modules"]
        if not modules:
            fail("pkg_config entry `{}` has no modules".format(entry["name"]))

        pkg_paths = pkg_config_paths(env_root, entry["extra_paths"])
        if not pkg_paths:
            fail("No pkg-config paths found inside {}".format(env_root))

        env = {
            "PKG_CONFIG_PATH": pathsep.join(pkg_paths),
            "PKG_CONFIG_LIBDIR": "disable-the-default",
        }

        base_cmd = [pkg_config_bin, "--print-errors"]
        if entry_static:
            base_cmd.append("--static")

        cflag_args = _run_pkg_config(rctx, base_cmd + ["--cflags"] + modules, env)
        lib_args = _run_pkg_config(rctx, base_cmd + ["--libs"] + modules, env)

        cflag_args = relativize_flags(cflag_args, env_root_str)
        link_entries = resolve_link_entries(
            rctx,
            env_root,
            env_root_str,
            lib_args,
            entry_static,
            platform,
        )

        lines.append("""pkg_config_import(
    name = "{name}",
    environment = "{env}",
    cflags = {cflags},
    link_entries = {link_entries},
    visibility = [\"//visibility:public\"],
)""".format(
            name = entry["name"],
            env = environment_target,
            cflags = _format_string_list(cflag_args),
            link_entries = _format_string_list(link_entries),
        ))
        lines.append("")

    rctx.file("pkg_config/BUILD.bazel", "\n".join(lines))
