load("//private/repo:conda.bzl", "conda_environment")

def _run_python(rctx, args):
    return rctx.execute(
        [Label("@python_3_11_host//:bin/python3")] + args,
        environment = {"PYTHONPATH": str(rctx.path(Label("@pypi_311_py_rattler//:site-packages")))},
    )

def _check_result(result, error):
    if result.return_code != 0:
        fail("{}\n{}".format(result.stderr, error))

def _parse_lockfile(mctx, lockfile):
    mctx.watch(lockfile)
    parse_lockfile = Label("//private/repo:parse_lockfile.py")
    mctx.watch(parse_lockfile)
    result = _run_python(mctx, [parse_lockfile, lockfile, "environments.json"])
    _check_result(result, "couldn't parse lockfile {}".format(lockfile))
    return json.decode(mctx.read("environments.json"))

def _list_packages(environments):
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

def _download_impl(rctx):
    rctx.download(rctx.attr.url, sha256 = rctx.attr.sha256, output = rctx.attr.subdir + "/" + rctx.attr.filename)
    rctx.file("BUILD")

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
    rctx.watch(install)
    result = _run_python(rctx, [install, rctx.attr.lockfile, rctx.attr.environment_name, rctx.attr.platform, str(rctx.attr.execute_link_scripts)] + args)
    _check_result(result, "couldn't create environment {}".format(rctx.attr.name))
    rctx.file("BUILD")

def _package_repo_name(filename, subdir):
    return subdir + "-" + filename

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

_parse = tag_class(attrs = {"lockfile": attr.label()})

def _conda(ctx):
    lockfiles = {}
    environments = {}
    for mod in ctx.modules:
        for parse in mod.tags.parse:
            for name, environment in _parse_lockfile(ctx, parse.lockfile).items():
                if name in environments:
                    fail("an environment `{}` already exists (`{}`)".format(name, parse.lockfile))
                environments[name] = environment
                lockfiles[name] = parse.lockfile

    for package in _list_packages(environments):
        _download(
            name = _package_repo_name(package.filename, package.subdir),
            url = package.url,
            sha256 = package.sha256,
            filename = package.filename,
            subdir = package.subdir,
        )

    for name, environment in environments.items():
        for platform, packages in environment.items():
            if platform == "linux-64":  # FIXME detect host
                _install(
                    name = name,
                    environment_name = name,
                    platform = "linux-64",
                    lockfile = lockfiles[name],
                    packages = {
                        p["filename"]: "@{}//:{}/{}".format(_package_repo_name(p["filename"], p["subdir"]), p["subdir"], p["filename"])
                        for p in packages
                    },
                    execute_link_scripts = False,
                )

conda = module_extension(
    implementation = _conda,
    tag_classes = {"parse": _parse},
)
