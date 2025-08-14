load("@bazel_skylib//rules/directory:providers.bzl", "DirectoryInfo")
load("//environment:providers.bzl", "EnvironmentInfo")

def _environment(ctx):
    environment_info = EnvironmentInfo(
        metadata = json.decode(ctx.attr.metadata),
    )
    return [
        environment_info,
        ctx.attrs.dir[DirectoryInfo],
        ctx.attrs.dir[DefaultInfo],
    ]

environment = rule(
    implementation = _environment,
    attrs = {
        "dir": attr.label(mandatory = True, providers = [DirectoryInfo]),
        "metadata": attr.string(mandatory = True),
    },
)
