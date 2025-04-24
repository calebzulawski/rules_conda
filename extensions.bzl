load("//private/repo:conda.bzl", "conda_environment")

_environment = tag_class(attrs = {"name": attr.string(), "lockfile": attr.label()})

def _conda(ctx):
    for mod in ctx.modules:
        for environment in mod.tags.environment:
            conda_environment(name = environment.name, lockfile = environment.lockfile)

conda = module_extension(
    implementation = _conda,
    tag_classes = {"environment": _environment},
)
