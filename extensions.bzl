""" Module extensions for loading Conda environments. """

def _run_python(rctx, args):
    "Run Python in a repository_rule context with rattler"
    path = "bin/python3"
    if rctx.os.name.startswith("windows"):
        path = "python.exe"
    return rctx.execute(
        [Label("@python_3_11_host//:" + path)] + args,
        environment = {"PYTHONPATH": str(rctx.path(Label("@pypi_311_py_rattler//:site-packages")))},
    )

def _check_result(result, error):
    "Fail on exec error"
    if result.return_code != 0:
        fail("{}\n{}".format(result.stderr, error))

def _parse_lockfile(mctx, lockfile):
    "Parse a conda lockfile and return the contained environments"
    mctx.watch(lockfile)
    parse_lockfile = Label("//private/environment:parse_lockfile.py")
    mctx.watch(parse_lockfile)
    result = _run_python(mctx, [parse_lockfile, lockfile, "environments.json"])
    _check_result(result, "couldn't parse lockfile {}".format(lockfile))
    return json.decode(mctx.read("environments.json"))

def _unique_packages(packages):
    "Return the list of unique packages across all environments"
    unique_packages = {}
    for package in packages:
        package = struct(**package)
        key = (package.subdir, package.filename)
        if key in unique_packages and package.sha256 != unique_packages[key].sha256:
            fail("found conda packages with mismatched sha256 hashes:\n{}\n{}".format(package.url, unique_packages[package.filename].url))
        unique_packages[key] = package
    return unique_packages.values()

def _package_repo_name(filename, subdir):
    "Create a valid repository name for a conda package"
    return subdir + "-" + filename

def _download_impl(rctx):
    rctx.download(rctx.attr.url, sha256 = rctx.attr.sha256, output = rctx.attr.subdir + "/" + rctx.attr.filename)
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

def _install_impl(rctx):
    args = []
    for name, label in rctx.attr.packages.items():
        args += [name, rctx.path(label)]

    install = Label("//private/environment:install.py")
    template = Label("//private/environment:template.BUILD")
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

            locked = _parse_lockfile(ctx, cfg.lockfile)

            if env not in locked:
                fail("couldn't find environment `{}`", env)

            if platform not in locked[env]:
                # TODO make this error delayed
                fail("environment `{}` isn't locked for platform `{}`", env, platform)
            else:
                packages = locked[env][platform]
                used_packages.extend(packages)
                _install(
                    name = cfg.name,
                    environment_name = env,
                    platform = platform,
                    lockfile = cfg.lockfile,
                    packages = {
                        p["filename"]: "@{}//:{}/{}".format(_package_repo_name(p["filename"], p["subdir"]), p["subdir"], p["filename"])
                        for p in packages
                    },
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
