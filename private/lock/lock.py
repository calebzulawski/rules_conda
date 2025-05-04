import argparse
import asyncio
import difflib
import filecmp
import os
import rattler
import sys
import tempfile
import yaml

mode = sys.argv[1]
lockfile_path = os.path.realpath(sys.argv[2])
environment_paths = sys.argv[3:]


def virtual_packages(platform):
    platform = rattler.Platform(platform)
    packages = []
    default = lambda name: rattler.GenericVirtualPackage(
        rattler.PackageName(name), rattler.Version("0"), "0"
    )
    override = lambda name, var: rattler.GenericVirtualPackage(
        rattler.PackageName(name), rattler.Version(os.environ[var]), "0"
    )
    if platform.is_linux:
        packages.append(default("__linux"))
    if platform.is_unix:
        packages.append(default("__unix"))
    if platform.is_windows:
        packages.append(default("__win"))
    if "CONDA_OVERRIDE_CUDA" in os.environ and not platform.is_osx:
        packages.append(override("__cuda", "CONDA_OVERRIDE_CUDA"))
    if "CONDA_OVERRIDE_OSX" in os.environ and platform.is_osx:
        packages.append(override("__osx", "CONDA_OVERRIDE_OSX"))
    if "CONDA_OVERRIDE_GLIBC" in os.environ and platform.is_linux:
        packages.append(override("__glibc", "CONDA_OVERRIDE_GLIBC"))
    return packages


async def solve():
    with tempfile.TemporaryDirectory() as cache_dir:
        client = rattler.Client.authenticated_client()
        gateway = rattler.Gateway(cache_dir=cache_dir, client=client)

        locked_envs = {}
        if os.path.getsize(lockfile_path) != 0:
            lockfile = rattler.LockFile.from_path(lockfile_path)
            locked_envs = dict(lockfile.environments())

        environments = {}
        for p in environment_paths:
            with open(p) as f:
                env = yaml.safe_load(f)
            for platform in env["platforms"]:
                locked_packages = []
                if env["name"] in locked_envs and platform in [
                    str(p) in locked_envs[env["name"]].platforms()
                ]:
                    locked_packages = locked_envs[env["name"]].packages(
                        rattler.Platform(platform)
                    )
                environments.setdefault(env["name"], {})[
                    rattler.Platform(platform)
                ] = await rattler.solve(
                    channels=env["channels"],
                    specs=env["dependencies"],
                    platforms=[platform, "noarch"],
                    gateway=gateway,
                    locked_packages=locked_packages,
                    virtual_packages=virtual_packages(platform),
                )
        return environments


def make_lockfile():
    environments = asyncio.run(solve())

    return rattler.LockFile(
        {
            name: rattler.Environment(
                name,
                environment,
                # channels don't seem to compare properly, so make the set over strings to deduplicate
                [
                    rattler.Channel(c)
                    for c in {
                        record.channel
                        for records in environment.values()
                        for record in records
                    }
                ],
            )
            for name, environment in environments.items()
        }
    )


if mode == "update":
    make_lockfile().to_path(lockfile_path)
elif mode == "test":
    # use delete=False to allow it to be opened and closed multiple times on windows
    with tempfile.NamedTemporaryFile(delete=os.name != "nt") as tmp:
        make_lockfile().to_path(tmp.name)
        with open(lockfile_path) as f:
            actual = list(f)
        with open(tmp.name) as f:
            want = list(f)
        if actual != want:
            sys.stderr.writelines(
                difflib.unified_diff(
                    actual,
                    want,
                    fromfile="actual",
                    tofile="want",
                )
            )
            sys.exit(1)
else:
    assert False
