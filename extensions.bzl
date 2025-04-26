load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")
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
                if package.filename in all_packages and package.sha256 != all_packages[package.filename].sha256:
                    fail("found conda packages with mismatched sha256 hashes:\n{}\n{}".format(package.url, all_packages[package.filename].url))
                all_packages[package.filename] = package
    return all_packages.values()

def _install_impl(rctx):
    args = []
    for name, label in rctx.attr.packages.items():
        args += [name, rctx.path(label)]

    install = Label("//private/repo:install.py")
    result = _run_python(rctx, [install, rctx.attr.lockfile, str(rctx.attr.run_install_scripts)] + args)
    _check_result(result, "couldn't create environment {}".format(rctx.attr.name))
    rctx.file("BUILD")

def _package_repo_name(name):
    return "package-" + name

_install = repository_rule(
    implementation = _install_impl,
    attrs = {
        "lockfile": attr.label(),
        "packages": attr.string_keyed_label_dict(),
        "run_install_scripts": attr.bool(),
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
        http_file(
            name = _package_repo_name(package.filename),
            url = package.url,
            sha256 = package.sha256,
        )

    for name, environment in environments.items():
        for platform, packages in environment.items():
            if platform == "linux-64":  # FIXME detect host
                _install(
                    name = name,
                    lockfile = lockfiles[name],
                    packages = {
                        p["filename"]: "@{}//file:downloaded".format(_package_repo_name(p["filename"]))
                        for p in packages
                    },
                    run_install_scripts = False,
                )

conda = module_extension(
    implementation = _conda,
    tag_classes = {"parse": _parse},
)
