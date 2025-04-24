import json
import sys
from rattler import LockFile

lock_path = sys.argv[1]
json_path = sys.argv[2]

lock = LockFile.from_path(lock_path)
packages = {}
for _, environment in lock.environments():
    for records in environment.conda_repodata_records().values():
        for record in records:
            packages[record.file_name] = { "url": record.url, "sha256": record.sha256.hex() }

with open(json_path, "w") as f:
    json.dump(packages, f, indent=2)
