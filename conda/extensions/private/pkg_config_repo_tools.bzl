"""External tool discovery helpers for pkg-config repository logic."""

def _python_interpreter(rctx):
    if rctx.os.name.startswith("windows"):
        return str(rctx.path(Label("@python_3_11_host//:python.exe")))
    return str(rctx.path(Label("@python_3_11_host//:bin/python3")))

def identify_windows_dll(rctx, interface_path):
    script = Label("//conda/extensions/private:get_dll_from_import_lib.py")
    rctx.watch(script)
    python_bin = _python_interpreter(rctx)
    script_path = str(rctx.path(script))
    result = rctx.execute([python_bin, script_path, interface_path])
    if result.return_code != 0:
        fail("get_dll_from_import_lib.py failed with {}\nstdout:\n{}\nstderr:\n{}".format(result.return_code, result.stdout, result.stderr))
    dll_name = result.stdout.strip()
    return dll_name if dll_name != "" else None

def _readelf_binary(rctx):
    suffix = ".exe" if rctx.os.name.startswith("windows") else ""
    candidates = [
        "bin/readelf" + suffix,
        "Library/mingw-w64/bin/readelf" + suffix,
        "Library/bin/readelf" + suffix,
        "Scripts/readelf" + suffix,
    ]
    for rel in candidates:
        label = Label("@rules_conda_pkg_config_tool//:" + rel)
        path = rctx.path(label)
        if path.exists:
            return str(path)
    fail("could not find readelf binary in rules_conda_pkg_config_tool")

def shared_library_name(rctx, shared_path, platform):
    if platform.startswith("osx"):
        tool = rctx.which("otool")
        if tool == None:
            tool = "/usr/bin/otool"
        if tool == None:
            fail("otool not found on host; required to read install names")
        result = rctx.execute([tool, "-D", shared_path])
        if result.return_code != 0:
            fail("otool failed with {}\nstdout:\n{}\nstderr:\n{}".format(result.return_code, result.stdout, result.stderr))
        lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
        if len(lines) >= 2:
            return lines[-1]
        return None

    readelf = _readelf_binary(rctx)
    result = rctx.execute([readelf, "-d", shared_path])
    if result.return_code != 0:
        fail("readelf failed with {}\nstdout:\n{}\nstderr:\n{}".format(result.return_code, result.stdout, result.stderr))
    for line in result.stdout.splitlines():
        if "SONAME" not in line:
            continue
        start = line.find("[")
        end = line.find("]", start + 1)
        if start != -1 and end != -1:
            return line[start + 1:end].strip()
    return None

def pkg_config_binary(rctx):
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
