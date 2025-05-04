import json
import sys
from rattler import LockFile

lock_path = sys.argv[1]
json_path = sys.argv[2]

lock = LockFile.from_path(lock_path)
environments = {}
for name, environment in lock.environments():
    environments[name] = {}
    for platform, records in environment.conda_repodata_records().items():
        environments[name][platform] = [
            {
                "filename": r.file_name,
                "subdir": r.subdir,
                "url": r.url,
                "sha256": r.sha256.hex(),
            }
            for r in records
        ]

with open(json_path, "w") as f:
    json.dump(environments, f, indent=2)
