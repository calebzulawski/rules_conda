import asyncio
import os
import rattler
import sys
import yaml

lockfile_path = os.path.realpath(sys.argv[1])
environment_paths = sys.argv[2:]


async def solve():
    client = rattler.Client.authenticated_client()
    gateway = rattler.Gateway(client=client)

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
            )
    return environments


environments = asyncio.run(solve())

rattler.LockFile(
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
).to_path(lockfile_path)
