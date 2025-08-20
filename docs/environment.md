<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="environment_glob"></a>

## environment_glob

<pre>
load("@rules_conda//environment:defs.bzl", "environment_glob")

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


<a id="import_library"></a>

## import_library

<pre>
load("@rules_conda//environment:defs.bzl", "import_library")

import_library(<a href="#import_library-name">name</a>, <a href="#import_library-deps">deps</a>, <a href="#import_library-alwayslink">alwayslink</a>, <a href="#import_library-environment">environment</a>, <a href="#import_library-includes">includes</a>, <a href="#import_library-interface_library">interface_library</a>, <a href="#import_library-packages">packages</a>,
               <a href="#import_library-pic_static_library">pic_static_library</a>, <a href="#import_library-shared_library">shared_library</a>, <a href="#import_library-static_library">static_library</a>)
</pre>

Imports a library from an environment, as if by cc_import

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="import_library-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="import_library-deps"></a>deps |  The list of other libraries that the target depends on.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional |  `[]`  |
| <a id="import_library-alwayslink"></a>alwayslink |  If true, link in all object files specified by the static library, even if no symbols are referenced.   | Boolean | optional |  `False`  |
| <a id="import_library-environment"></a>environment |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="import_library-includes"></a>includes |  List of include dirs to be added to the compile line, relative to the conda environment include directory root.   | List of strings | optional |  `[]`  |
| <a id="import_library-interface_library"></a>interface_library |  -   | String | optional |  `""`  |
| <a id="import_library-packages"></a>packages |  Packages containing libraries and headers to import   | List of strings | optional |  `[]`  |
| <a id="import_library-pic_static_library"></a>pic_static_library |  -   | String | optional |  `""`  |
| <a id="import_library-shared_library"></a>shared_library |  -   | String | optional |  `""`  |
| <a id="import_library-static_library"></a>static_library |  -   | String | optional |  `""`  |


<a id="run_binary"></a>

## run_binary

<pre>
load("@rules_conda//environment:defs.bzl", "run_binary")

run_binary(<a href="#run_binary-name">name</a>, <a href="#run_binary-environment">environment</a>, <a href="#run_binary-path">path</a>)
</pre>

Creates a binary target from an executable in an environment

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="run_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="run_binary-environment"></a>environment |  -   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="run_binary-path"></a>path |  The path of the binary   | String | required |  |


