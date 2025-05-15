<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Rules for creating lockfiles.

<a id="lock_environments"></a>

## lock_environments

<pre>
load("@rules_conda//:lockfile.bzl", "lock_environments")

lock_environments(<a href="#lock_environments-name">name</a>, <a href="#lock_environments-environments">environments</a>, <a href="#lock_environments-lockfile">lockfile</a>, <a href="#lock_environments-cuda_version">cuda_version</a>, <a href="#lock_environments-macos_version">macos_version</a>, <a href="#lock_environments-glibc_version">glibc_version</a>,
                  <a href="#lock_environments-visibility">visibility</a>, <a href="#lock_environments-tags">tags</a>, <a href="#lock_environments-kwargs">**kwargs</a>)
</pre>

Lock Conda environments.

Creates two targets:
* `bazel run [name].update` to update the lockfile
* `bazel test [name].test` to ensure the lockfile is up-to-date


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="lock_environments-name"></a>name |  The name of this rule   |  `None` |
| <a id="lock_environments-environments"></a>environments |  A list of environment files, in YAML format   |  `[]` |
| <a id="lock_environments-lockfile"></a>lockfile |  The lockfile to create   |  `"conda.lock"` |
| <a id="lock_environments-cuda_version"></a>cuda_version |  The CUDA version to use to solve   |  `None` |
| <a id="lock_environments-macos_version"></a>macos_version |  The macOS version to use to solve   |  `None` |
| <a id="lock_environments-glibc_version"></a>glibc_version |  The glibc version to use to solve   |  `None` |
| <a id="lock_environments-visibility"></a>visibility |  passed to both .update and .test   |  `["//visibility:private"]` |
| <a id="lock_environments-tags"></a>tags |  passed to both .update and .test   |  `[]` |
| <a id="lock_environments-kwargs"></a>kwargs |  additional arguments passed to .test   |  none |


