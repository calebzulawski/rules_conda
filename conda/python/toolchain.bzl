load("@rules_python//python:py_runtime.bzl", "py_runtime")
load("@rules_python//python:py_runtime_pair.bzl", "py_runtime_pair")
load("//conda/environment:providers.bzl", "EnvironmentInfo")

def _get_interpreter(ctx):
    env_info = ctx.attr.environment[EnvironmentInfo]
    dir_info = env_info.files

    interpreter = dir_info.glob(["bin/python3", "python.exe"], [], True)
    if len(interpreter.to_list()) != 1:
        fail("Could not find a Python interpreter")
    return interpreter

def _conda_python_interpreter_impl(ctx):
    interpreter = _get_interpreter(ctx)
    return [DefaultInfo(files = _get_interpreter(ctx))]

_conda_python_interpreter = rule(
    implementation = _conda_python_interpreter_impl,
    attrs = {
        "environment": attr.label(mandatory = True, providers = [EnvironmentInfo]),
    },
)

def conda_python_toolchain(*, name, environment):
    _conda_python_interpreter(
        name = name + "_interpreter",
        environment = environment,
    )
    py_runtime(
        name = name + "_runtime",
        interpreter = name + "_interpreter",
        files = [environment],
    )
    py_runtime_pair(
        name = name,
        py3_runtime = name + "_runtime",
    )
