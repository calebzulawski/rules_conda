import asyncio
import os
import sys
import rattler
from rattler import LockFile, Platform, RepoDataRecord
from tempfile import TemporaryDirectory

client = rattler.Client.authenticated_client()

lock_path = sys.argv[1]
name = sys.argv[2]
platform = Platform(sys.argv[3])
execute_link_scripts = sys.argv[4].lower() == "true"
paths = dict(zip(sys.argv[5::2], sys.argv[6::2]))

lock = LockFile.from_path(lock_path)
environment = lock.environment(name)
records = environment.conda_repodata_records_for_platform(platform)
records = [
    RepoDataRecord(r, r.file_name, f"file://{paths[r.file_name]}", r.channel)
    for r in records
]
print(records, file=sys.stderr)
with TemporaryDirectory() as cache_dir:
    asyncio.run(
        rattler.install(
            records,
            os.getcwd(),
            cache_dir=cache_dir,
            platform=platform,
            execute_link_scripts=execute_link_scripts,
            client=client,
        )
    )
