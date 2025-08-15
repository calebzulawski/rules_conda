<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="conda_binary"></a>

## conda_binary

<pre>
load("@rules_conda//environment:environment.bzl", "conda_binary")

conda_binary(<a href="#conda_binary-name">name</a>, <a href="#conda_binary-environment">environment</a>, <a href="#conda_binary-path">path</a>)
</pre>

Creates a binary target from an executable in an environment

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="conda_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="conda_binary-environment"></a>environment |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="conda_binary-path"></a>path |  The path of the binary   | String | required |  |


<a id="environment_glob"></a>

## environment_glob

<pre>
load("@rules_conda//environment:environment.bzl", "environment_glob")

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


