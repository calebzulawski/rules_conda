import json
import os
import sys
from rattler import LockFile, Platform

lock_path = sys.argv[1]
name = sys.argv[2]
platform = Platform(sys.argv[3])
json_path = sys.argv[4]

packages = []

# skip special case where we are creating the lockfile for the first time
if os.path.getsize(lock_path) != 0:
    lock = LockFile.from_path(lock_path)
    environment = lock.environment(name)
    if environment:
        records = environment.conda_repodata_records_for_platform(platform)
        noarch_records = (
            environment.conda_repodata_records_for_platform(Platform("noarch")) or []
        )
        if records:
            packages = [
                {
                    "filename": r.file_name,
                    "subdir": r.subdir,
                    "url": r.url,
                    "sha256": r.sha256.hex(),
                }
                for r in records + noarch_records
            ]

with open(json_path, "w") as f:
    json.dump(packages, f)
