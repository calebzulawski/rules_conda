# rules_conda

This repository provides Bazel rules for installing Conda environments.

## Overview

To begin, create an environment file:
```yaml
name: my-environment
channels:
  - conda-forge
dependencies:
  - bash
platforms:
  - linux-64
  - osx-arm64
  - win-64
```

Compile a lockfile by adding the following target and running `bazel run lockfile.update`:

```starlark
load("@rules_conda//conda/lock:lockfile.bzl", "lock_environments")

lock_environments(
    name = "lockfile",
    environments = ["my-environment.yml"],
)
```

In `MODULE.bazel`, load the environment:
```starlark
conda = use_extension("@rules_conda//conda:extensions.bzl", "conda")
conda.environment(name = "my-environment", lockfile = "//:conda.lock")
use_repo(conda, "my-environment")
```
