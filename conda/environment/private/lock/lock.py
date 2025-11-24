import argparse
import asyncio
import difflib
import json
import os
import sys
import tempfile

import rattler
import yaml
from bazel_tools.tools.python.runfiles import runfiles


def virtual_packages(platform, overrides):
    platform = rattler.Platform(platform)
    packages = []
    default = lambda name: rattler.GenericVirtualPackage(
        rattler.PackageName(name), rattler.Version("0"), "0"
    )
    override = lambda name, var: rattler.GenericVirtualPackage(
        rattler.PackageName(name), rattler.Version(overrides[var]), "0"
    )
    if platform.is_linux:
        packages.append(default("__linux"))
    if platform.is_unix:
        packages.append(default("__unix"))
    if platform.is_windows:
        packages.append(default("__win"))
    if "cuda_version" in overrides and not platform.is_osx:
        packages.append(override("__cuda", "cuda_version"))
    if "macos_version" in overrides and platform.is_osx:
        packages.append(override("__osx", "macos_version"))
    if "glibc_version" in overrides and platform.is_linux:
        packages.append(override("__glibc", "glibc_version"))
    return packages


async def solve(lockfile_path, environment_paths, overrides):
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as cache_dir:
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
                    str(p) for p in locked_envs[env["name"]].platforms()
                ]:
                    locked_packages = locked_envs[
                        env["name"]
                    ].conda_repodata_records_for_platform(rattler.Platform(platform))
                environments.setdefault(env["name"], {})[
                    rattler.Platform(platform)
                ] = await rattler.solve(
                    channels=env["channels"],
                    specs=env["dependencies"],
                    platforms=[platform, "noarch"],
                    gateway=gateway,
                    locked_packages=locked_packages,
                    virtual_packages=virtual_packages(platform, overrides),
                )
        return environments


def make_lockfile(lockfile_path, environment_paths, overrides):
    environments = asyncio.run(solve(lockfile_path, environment_paths, overrides))

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


def _resolve_runfile(path, runfiles_ctx):
    if os.path.isabs(path):
        return path
    return runfiles_ctx.Rlocation(path)


def run_config(config_path, mode):
    runfiles_ctx = runfiles.Create()
    with open(config_path) as f:
        config = json.load(f)
    lockfile_path = os.path.realpath(_resolve_runfile(config["lockfile"], runfiles_ctx))
    environment_paths = [
        os.path.realpath(_resolve_runfile(p, runfiles_ctx))
        for p in config.get("environments", [])
    ]
    overrides = config.get("overrides", {})
    if mode == "update":
        make_lockfile(lockfile_path, environment_paths, overrides).to_path(
            lockfile_path
        )
    elif mode == "test":
        # use delete=False to allow it to be opened and closed multiple times on windows
        with tempfile.NamedTemporaryFile(delete=os.name != "nt") as tmp:
            make_lockfile(lockfile_path, environment_paths, overrides).to_path(tmp.name)
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
        raise ValueError("Unsupported mode {}".format(mode))
