""" Module extensions for loading Conda environments. """

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "read_netrc", "read_user_netrc", "use_netrc")

def _run_python(rctx, args):
    "Run Python in a repository_rule context with rattler"
    path = "bin/python3"
    if rctx.os.name.startswith("windows"):
        path = "python.exe"
    return rctx.execute(
        [Label("@python_3_11_host//:" + path)] + args,
        environment = {"PYTHONPATH": str(rctx.path(Label("@rules_conda_pypi_311_py_rattler//:site-packages")))},
    )

def _check_result(result, error):
    "Fail on exec error"
    if result.return_code != 0:
        fail("{}\n{}".format(result.stderr, error))

def _parse_lockfile(mctx, lockfile, env, platform):
    "Parse a conda lockfile and return the contained environments"
    mctx.watch(lockfile)
    parse_lockfile = Label("//conda/extensions/private:parse_lockfile.py")
    mctx.watch(parse_lockfile)
    result = _run_python(mctx, [parse_lockfile, lockfile, env, platform, "environments.json"])
    _check_result(result, "couldn't parse lockfile {}".format(lockfile))
    return json.decode(mctx.read("environments.json"))

def _unique_packages(packages):
    "Return the list of unique packages across all environments"
    unique_packages = {}
    for package in packages:
        package = struct(**package)
        key = (package.subdir, package.filename)
        if key in unique_packages and package.sha256 != unique_packages[key].sha256:
            fail("found conda packages with mismatched sha256 hashes:\n{}\n{}".format(package.url, unique_packages[key].url))
        unique_packages[key] = package
    return unique_packages.values()

def _package_repo_name(filename, subdir):
    "Create a valid repository name for a conda package"
    return subdir + "-" + filename

def _auth(rctx, url):
    if "NETRC" in rctx.os.environ:
        if hasattr(rctx, "getenv"):
            netrc = read_netrc(rctx, rctx.getenv("NETRC"))
        else:
            netrc = read_netrc(rctx, rctx.os.environ["NETRC"])
    else:
        netrc = read_user_netrc(rctx)

    # TODO support auth patterns, but basic auth is usually enough for conda
    return use_netrc(netrc, [url], {})

def _download_impl(rctx):
    auth = _auth(rctx, rctx.attr.url)
    rctx.download(rctx.attr.url, sha256 = rctx.attr.sha256, output = rctx.attr.subdir + "/" + rctx.attr.filename, auth = auth)
    rctx.file("BUILD")

def _host_platform(mctx):
    if mctx.os.name.startswith("linux"):
        return "linux-" + {
            "x86": "32",
            "amd64": "64",
            "x86_64": "64",
            "arm": "armv7l",
        }.get(mctx.os.arch, default = mctx.os.arch)
    if mctx.os.name.startswith("mac os"):
        return "osx-" + {
            "amd64": "64",
            "x86_64": "64",
            "aarch64": "arm64",
        }[mctx.os.arch]
    if mctx.os.name.startswith("windows"):
        return "win-" + {
            "x86": "32",
            "amd64": "64",
            "x86_64": "64",
        }.get(mctx.os.arch, default = mctx.os.arch)
    return None

_download = repository_rule(
    implementation = _download_impl,
    attrs = {
        "url": attr.string(),
        "sha256": attr.string(),
        "filename": attr.string(),
        "subdir": attr.string(),
    },
)

def _delayed_error_impl(rctx):
    fail(rctx.attr.message)

def _install_impl(rctx):
    args = []
    if len(rctx.attr.packages) != 0:
        for name, label in rctx.attr.packages.items():
            args += [name, rctx.path(label)]
    else:
        locked_packages = _parse_lockfile(rctx, rctx.attr.lockfile, rctx.attr.environment_name, rctx.attr.platform)
        download = []
        for p in locked_packages:
            path = "rules_conda_download/{}/{}".format(p["subdir"], p["filename"])
            auth = _auth(rctx, p["url"])
            download.append(rctx.download(p["url"], sha256 = p["sha256"], output = path, auth = auth, block = False))
            args += [p["filename"], rctx.path(path)]
        for d in download:
            d.wait()

    install = Label("//conda/extensions/private:install.py")
    template = Label("//conda/extensions/private:template.BUILD")
    rctx.watch(install)
    rctx.watch(template)
    result = _run_python(rctx, [install, rctx.attr.lockfile, rctx.attr.environment_name, rctx.attr.platform, str(rctx.attr.execute_link_scripts)] + args)
    _check_result(result, "couldn't create environment {}".format(rctx.attr.name))

    # parse metadata
    metadata = {}
    for f in rctx.path("conda-meta").readdir():
        this_metadata = json.decode(rctx.read(f))
        metadata[this_metadata["name"]] = this_metadata

    rctx.file(
        "BUILD",
        rctx.read(template)
            .replace("{{metadata}}", json.encode_indent(metadata).replace("\\", "\\\\"))
            .replace("{{name}}", rctx.attr.environment_name),
    )

_install = repository_rule(
    implementation = _install_impl,
    attrs = {
        "lockfile": attr.label(),
        "environment_name": attr.string(),
        "platform": attr.string(),
        "packages": attr.string_keyed_label_dict(),
        "execute_link_scripts": attr.bool(),
    },
)

_environment = tag_class(
    attrs = {
        "name": attr.string(mandatory = True, doc = "The name of the repository to create."),
        "lockfile": attr.label(mandatory = True, doc = "The lockfile containing the environment."),
        "execute_link_scripts": attr.bool(default = False, doc = "Execute link scripts when installing the environment. Only applies to the host platform."),
        "platform": attr.string(doc = "The platform to create an environment for. Defaults to the host platform."),
        "environment": attr.string(doc = "The environment to create. Defaults to `name`."),
        "deduplicate_downloads": attr.bool(doc = "Allow this environment to participate in package download deduplication. " +
                                                 "For very large environments or an excessive number of environments, this option can increase the initialization time of this module extension.", default = True),
    },
    doc = "Create a Conda environment",
)

def _conda(ctx):
    # Detect the host platform
    host_platform = _host_platform(ctx)

    # Create each environment
    used_packages = []
    root_module_direct_deps = []
    root_module_direct_dev_deps = []
    for mod in ctx.modules:
        for cfg in mod.tags.environment:
            if mod.is_root:
                if ctx.is_dev_dependency(cfg):
                    root_module_direct_dev_deps.append(cfg.name)
                else:
                    root_module_direct_deps.append(cfg.name)

            env = cfg.environment
            if env == "":
                env = cfg.name

            platform = cfg.platform
            if platform == "":
                platform = host_platform

            if cfg.execute_link_scripts and cfg.platform != "":
                fail("`execute_link_scripts` must be False when `platform` is specified")

            packages = {}
            if cfg.deduplicate_downloads:
                locked_packages = _parse_lockfile(ctx, cfg.lockfile, env, platform)
                used_packages.extend(locked_packages)
                packages = {
                    p["filename"]: "@{}//:{}/{}".format(_package_repo_name(p["filename"], p["subdir"]), p["subdir"], p["filename"])
                    for p in locked_packages
                }
            _install(
                name = cfg.name,
                environment_name = env,
                platform = platform,
                lockfile = cfg.lockfile,
                packages = packages,
                execute_link_scripts = cfg.execute_link_scripts,
            )

    # Download all packages used across environments
    for package in _unique_packages(used_packages):
        _download(
            name = _package_repo_name(package.filename, package.subdir),
            url = package.url,
            sha256 = package.sha256,
            filename = package.filename,
            subdir = package.subdir,
        )

    return ctx.extension_metadata(
        root_module_direct_deps = root_module_direct_deps,
        root_module_direct_dev_deps = root_module_direct_dev_deps,
        reproducible = True,
    )

conda = module_extension(
    implementation = _conda,
    tag_classes = {"environment": _environment},
    doc = "Create Conda environments",
    arch_dependent = True,
    os_dependent = True,
)
