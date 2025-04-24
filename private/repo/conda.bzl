def _run_python(rctx, args):
    return rctx.execute(
        [Label("@python_3_11_host//:bin/python3")] + args,
        environment = {"PYTHONPATH": str(rctx.path(Label("@pypi_311_py_rattler//:site-packages")))},
    )

def _check_result(result, error):
    if result.return_code != 0:
        fail("{}\n{}".format(error, result.stderr))

def _package_list_impl(rctx):
    result = _run_python(rctx, [Label("//private/repo:packages.py"), rctx.attr.lockfile, "packages.json"])
    _check_result(result, "couldn't read list of packages")
    rctx.file("BUILD")

_package_list = repository_rule(
    implementation = _package_list_impl,
    attrs = {
        "lockfile": attr.label(),
    },
)

def _install_impl(rctx):
    rctx.file("BUILD")

_install = repository_rule(
    implementation = _install_impl,
    attrs = {},
)

def conda_environment(name = None, lockfile = None):
    _package_list(name = name + "_packages", lockfile = lockfile)
    _install(name = name)
