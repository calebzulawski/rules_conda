import argparse
import asyncio
import difflib
import json
import os
import sys
import tempfile

import rattler
import yaml
from python.runfiles import runfiles


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


def get_locked_packages_for_platform(
    locked_envs, env_name, platform, channels, exclude_packages=None
):
    if env_name not in locked_envs:
        return []

    locked_env = locked_envs[env_name]
    if platform not in [str(p) for p in locked_env.platforms()]:
        return []

    all_packages = locked_env.conda_repodata_records_for_platform(
        rattler.Platform(platform)
    )

    # only keep packages from channels that are present in the environment spec
    # env.yaml might use a name (e.g. "conda-forge") but lockfiles always use the full url
    allowed_channels = {str(rattler.Channel(c).base_url) for c in channels}
    packages = [
        pkg
        for pkg in all_packages
        if str(rattler.Channel(pkg.channel).base_url) in allowed_channels
    ]

    # Filter out packages that should be upgraded
    if exclude_packages:
        exclude_names = {rattler.PackageName(name) for name in exclude_packages}
        packages = [pkg for pkg in packages if pkg.name not in exclude_names]

    return packages


async def solve(
    lockfile_path,
    environment_paths,
    overrides,
    load_locked_packages=True,
    upgrade_packages=None,
):
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as cache_dir:
        client = rattler.Client.authenticated_client()
        gateway = rattler.Gateway(cache_dir=cache_dir, client=client)

        locked_envs = {}
        if load_locked_packages and os.path.getsize(lockfile_path) != 0:
            lockfile = rattler.LockFile.from_path(lockfile_path)
            locked_envs = dict(lockfile.environments())

        environments = {}
        for p in environment_paths:
            with open(p) as f:
                env = yaml.safe_load(f)

            for platform in env["platforms"]:
                locked_packages = []
                if load_locked_packages:
                    locked_packages = get_locked_packages_for_platform(
                        locked_envs,
                        env["name"],
                        platform,
                        env["channels"],
                        upgrade_packages,
                    )

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


def make_lockfile(
    lockfile_path,
    environment_paths,
    overrides,
    load_locked_packages=True,
    upgrade_packages=None,
):
    environments = asyncio.run(
        solve(
            lockfile_path,
            environment_paths,
            overrides,
            load_locked_packages,
            upgrade_packages,
        )
    )

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
    parser = argparse.ArgumentParser(
        description=f"{mode.capitalize()} conda environment lockfiles"
    )
    if mode == "upgrade":
        parser.add_argument(
            "packages",
            nargs="*",
            help="Package names to upgrade. If none specified, all packages are upgraded.",
        )
    args = parser.parse_args()

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
        make_lockfile(
            lockfile_path, environment_paths, overrides, load_locked_packages=True
        ).to_path(lockfile_path)
    elif mode == "upgrade":
        # If packages specified, use lockfile and exclude those packages.
        # If no packages specified, skip lockfile entirely (upgrade everything).
        load_locked = bool(args.packages)
        make_lockfile(
            lockfile_path,
            environment_paths,
            overrides,
            load_locked_packages=load_locked,
            upgrade_packages=args.packages,
        ).to_path(lockfile_path)
    elif mode == "test":
        # use delete=False to allow it to be opened and closed multiple times on windows
        with tempfile.NamedTemporaryFile(delete=os.name != "nt") as tmp:
            make_lockfile(
                lockfile_path, environment_paths, overrides, load_locked_packages=True
            ).to_path(tmp.name)
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
