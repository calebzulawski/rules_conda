<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="environment_glob"></a>

## environment_glob

<pre>
load("@rules_conda//conda/environment:defs.bzl", "environment_glob")

environment_glob(<a href="#environment_glob-name">name</a>, <a href="#environment_glob-srcs">srcs</a>, <a href="#environment_glob-data">data</a>, <a href="#environment_glob-allow_empty">allow_empty</a>, <a href="#environment_glob-environment">environment</a>, <a href="#environment_glob-exclude">exclude</a>, <a href="#environment_glob-include_package_dependencies">include_package_dependencies</a>,
                 <a href="#environment_glob-packages">packages</a>)
</pre>

Globs files from an environment

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="environment_glob-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="environment_glob-srcs"></a>srcs |  A list of globs to files within the environment to put in the files.<br><br>For example, `srcs = ["foo/**"]` would collect the file at `<environment>/foo` into the files.   | List of strings | optional |  `[]`  |
| <a id="environment_glob-data"></a>data |  A list of globs to files within the environment to put in the runfiles.<br><br>For example, `data = ["foo/**"]` would collect all files contained within `<environment>/foo` into the runfiles.   | List of strings | optional |  `[]`  |
| <a id="environment_glob-allow_empty"></a>allow_empty |  If true, allows globs to not match anything.   | Boolean | optional |  `False`  |
| <a id="environment_glob-environment"></a>environment |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="environment_glob-exclude"></a>exclude |  A list of globs to files within the environment to exclude from the files and runfiles.   | List of strings | optional |  `[]`  |
| <a id="environment_glob-include_package_dependencies"></a>include_package_dependencies |  If true, includes dependencies of `packages` as well.   | Boolean | optional |  `True`  |
| <a id="environment_glob-packages"></a>packages |  A list of packages globs are allowed to match.<br><br>If empty, matches all packages.   | List of strings | optional |  `[]`  |


<a id="run_binary"></a>

## run_binary

<pre>
load("@rules_conda//conda/environment:defs.bzl", "run_binary")

run_binary(<a href="#run_binary-name">name</a>, <a href="#run_binary-environment">environment</a>, <a href="#run_binary-path">path</a>)
</pre>

Creates a binary target from an executable in an environment

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="run_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="run_binary-environment"></a>environment |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="run_binary-path"></a>path |  The path of the binary   | String | required |  |


<a id="lock_environments"></a>

## lock_environments

<pre>
load("@rules_conda//conda/environment:defs.bzl", "lock_environments")

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


