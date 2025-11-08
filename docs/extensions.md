<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Module extensions for loading Conda environments.

<a id="conda"></a>

## conda

<pre>
conda = use_extension("@rules_conda//conda/extensions:module.bzl", "conda")
conda.environment(<a href="#conda.environment-name">name</a>, <a href="#conda.environment-environment">environment</a>, <a href="#conda.environment-execute_link_scripts">execute_link_scripts</a>, <a href="#conda.environment-lockfile">lockfile</a>, <a href="#conda.environment-platform">platform</a>)
conda.pkg_config(<a href="#conda.pkg_config-name">name</a>, <a href="#conda.pkg_config-environment">environment</a>, <a href="#conda.pkg_config-extra_pkg_config_paths">extra_pkg_config_paths</a>, <a href="#conda.pkg_config-modules">modules</a>, <a href="#conda.pkg_config-static">static</a>)
</pre>

Create Conda environments


**TAG CLASSES**

<a id="conda.environment"></a>

### environment

Create a Conda environment

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="conda.environment-name"></a>name |  The name of the repository to create.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="conda.environment-environment"></a>environment |  The environment to create. Defaults to `name`.   | String | optional |  `""`  |
| <a id="conda.environment-execute_link_scripts"></a>execute_link_scripts |  Execute link scripts when installing the environment. Only applies to the host platform.   | Boolean | optional |  `False`  |
| <a id="conda.environment-lockfile"></a>lockfile |  The lockfile containing the environment.   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="conda.environment-platform"></a>platform |  The platform to create an environment for. Defaults to the host platform.   | String | optional |  `""`  |

<a id="conda.pkg_config"></a>

### pkg_config

Create library targets with pkg-config inside a Conda environment repository.

**Attributes**

| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="conda.pkg_config-name"></a>name |  Name of the pkg-config target to create.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="conda.pkg_config-environment"></a>environment |  Repository name of the Conda environment providing `.pc` files.   | String | required |  |
| <a id="conda.pkg_config-extra_pkg_config_paths"></a>extra_pkg_config_paths |  Additional pkg-config search paths, relative to the environment root.   | List of strings | optional |  `[]`  |
| <a id="conda.pkg_config-modules"></a>modules |  pkg-config modules to query. Defaults to `[name]`.   | List of strings | optional |  `[]`  |
| <a id="conda.pkg_config-static"></a>static |  Link statically when available.   | Boolean | optional |  `False`  |


