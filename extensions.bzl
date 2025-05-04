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
    parse_lockfile = Label("//private/repo:parse_lockfile.py")
    mctx.watch(parse_lockfile)
    result = _run_python(mctx, [parse_lockfile, lockfile, "environments.json"])
    _check_result(result, "couldn't parse lockfile {}".format(lockfile))
    return json.decode(mctx.read("environments.json"))

def _list_packages(environments):
    "Return the list of unique packages across all environments"
    all_packages = {}
    for environment in environments.values():
        for packages in environment.values():
            for package in packages:
                package = struct(**package)
                key = (package.subdir, package.filename)
                if key in all_packages and package.sha256 != all_packages[key].sha256:
                    fail("found conda packages with mismatched sha256 hashes:\n{}\n{}".format(package.url, all_packages[package.filename].url))
                all_packages[key] = package
    return all_packages.values()

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

    install = Label("//private/repo:install.py")
    template = Label("//private/repo:template.BUILD")
    rctx.watch(install)
    rctx.watch(template)
    result = _run_python(rctx, [install, rctx.attr.lockfile, rctx.attr.environment_name, rctx.attr.platform, str(rctx.attr.execute_link_scripts)] + args)
    _check_result(result, "couldn't create environment {}".format(rctx.attr.name))
    rctx.file("BUILD", rctx.read(template))

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
        "name": attr.string(mandatory = True, doc = "The name of the Conda environment."),
        "lockfile": attr.label(mandatory = True, doc = "The lockfile containing the environment."),
        "execute_link_scripts": attr.bool(default = False, doc = "Whether link scripts should be executed when installing the environment. Only applies to the host platform."),
        "repo_name": attr.string(doc = "The name of the repo to create. Uses the environment name if not specified."),
    },
    doc = "Create a Conda environment",
)

def _conda(ctx):
    # Parse all lockfiles, obtaining all environments
    environments = {}
    cfgs = {}
    for mod in ctx.modules:
        for cfg in mod.tags.environment:
            repo_name = cfg.repo_name
            if repo_name == "":
                repo_name = cfg.name

            if repo_name in cfgs:
                fail("error creating environment `{}` from `{}`\nthe named environment already exists (`{}`)".format(cfg.repo_name, cfg.lockfile, cfgs[repo_name].lockfile))

            cfgs[repo_name] = cfg

            locked = _parse_lockfile(ctx, cfg.lockfile)
            if cfg.name not in locked:
                fail("environment `{}` doesn't exist in `{}`".format(cfg.name, cfg.lockfile))
            environments[repo_name] = locked[cfg.name]

    # Download all packages used across environments
    for package in _list_packages(environments):
        _download(
            name = _package_repo_name(package.filename, package.subdir),
            url = package.url,
            sha256 = package.sha256,
            filename = package.filename,
            subdir = package.subdir,
        )

    # Install environments
    host_platform = _host_platform(ctx)
    for name, environment in environments.items():
        for platform, packages in environment.items():
            packages = {
                p["filename"]: "@{}//:{}/{}".format(_package_repo_name(p["filename"], p["subdir"]), p["subdir"], p["filename"])
                for p in packages
            }
            _install(
                name = name + "-" + platform,
                environment_name = name,
                platform = platform,
                lockfile = cfgs[name].lockfile,
                packages = packages,
                execute_link_scripts = cfgs[name].execute_link_scripts,
            )
            if platform == host_platform:
                _install(
                    name = name,
                    environment_name = name,
                    platform = platform,
                    lockfile = cfgs[name].lockfile,
                    packages = packages,
                    execute_link_scripts = False,
                )

    return ctx.extension_metadata(
        reproducible = True,
    )

conda = module_extension(
    implementation = _conda,
    tag_classes = {"environment": _environment},
    doc = "Create Conda environments",
)
