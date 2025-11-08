"""Helpers for generating pkg-config based targets inside a Conda environment repo."""

load("//conda/extensions/private:pkg_config_rule.bzl", "pkg_config_import")

_ENV_ROOT_PLACEHOLDER = "__rules_conda_env__"

def _pkg_config_paths(env_root, extra_paths):
    candidates = [
        "lib/pkgconfig",
        "lib64/pkgconfig",
        "share/pkgconfig",
        "Library/lib/pkgconfig",
        "Library/lib64/pkgconfig",
        "Library/share/pkgconfig",
    ] + extra_paths
    dirs = []
    for rel in candidates:
        candidate = env_root.get_child(rel.replace("//", "/"))
        if candidate.exists:
            dirs.append(str(candidate))
    return dirs

def _pkg_config_binary(rctx):
    suffix = ".exe" if rctx.os.name.startswith("windows") else ""
    candidates = [
        "bin/pkg-config" + suffix,
        "Library/bin/pkg-config" + suffix,
        "Library/mingw-w64/bin/pkg-config" + suffix,
        "Scripts/pkg-config" + suffix,
    ]
    for rel in candidates:
        label = Label("@rules_conda_pkg_config_tool//:" + rel)
        path = rctx.path(label)
        if path.exists:
            return str(path)
    fail("could not find pkg-config binary in rules_conda_pkg_config_tool")

def _run_pkg_config(rctx, argv, env):
    result = rctx.execute(argv, environment = env)
    if result.return_code != 0:
        fail("pkg-config failed with {}\nstdout:\n{}\nstderr:\n{}".format(result.return_code, result.stdout, result.stderr))
    output = result.stdout.replace("\n", " ").strip()
    if output == "":
        return []
    return [flag.strip() for flag in output.split(" ")]

def _with_placeholder(flag, root):
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

def _relativize_flags(flags, root):
    return [_with_placeholder(flag, root) for flag in flags]

def write_pkg_config_targets(rctx, entries, environment_target):
    if not entries:
        return

    env_root = rctx.path("")
    pkg_config_bin = _pkg_config_binary(rctx)
    lines = ["load(\"@rules_conda//conda/extensions/private:pkg_config_rule.bzl\", \"pkg_config_import\")", ""]

    pathsep = ";" if rctx.os.name.startswith("windows") else ":"
    for entry in entries:
        modules = entry["modules"]
        if not modules:
            fail("pkg_config entry `{}` has no modules".format(entry["name"]))

        pkg_paths = _pkg_config_paths(env_root, entry["extra_paths"])
        if not pkg_paths:
            fail("No pkg-config paths found inside {}".format(env_root))

        env = {
            "PKG_CONFIG_PATH": pathsep.join(pkg_paths),
            "PKG_CONFIG_LIBDIR": "disable-the-default",
        }

        base_cmd = [pkg_config_bin, "--print-errors"]
        if entry["static"]:
            base_cmd.append("--static")

        cflag_args = _run_pkg_config(rctx, base_cmd + ["--cflags"] + modules, env)
        lib_args = _run_pkg_config(rctx, base_cmd + ["--libs"] + modules, env)

        cflag_args = _relativize_flags(cflag_args, str(env_root))
        lib_args = _relativize_flags(lib_args, str(env_root))

        lines.append("""pkg_config_import(
    name = "{name}",
    environment = "{env}",
    cflags = {cflags},
    libs = {libs},
    static = {static},
    visibility = [\"//visibility:public\"],
)""".format(
            name = entry["name"],
            env = environment_target,
            cflags = json.encode(cflag_args),
            libs = json.encode(lib_args),
            static = "True" if entry["static"] else "False",
        ))
        lines.append("")

    rctx.file("pkg_config/BUILD.bazel", "\n".join(lines))
