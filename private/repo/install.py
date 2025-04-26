import os
import sys
from rattler import LockFile

lock_path = sys.argv[1]
run_install_scripts = bool(sys.argv[2])
paths = dict(zip(sys.argv[3::2], sys.argv[4::2]))

lock = LockFile.from_path(lock_path)
for path in paths.values():
    print(path, file=sys.stderr)
    assert os.path.exists(path)
