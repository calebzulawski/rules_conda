<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="EnvironmentInfo"></a>

## EnvironmentInfo

<pre>
load("@rules_conda//environment:providers.bzl", "EnvironmentInfo")

EnvironmentInfo(<a href="#EnvironmentInfo-metadata">metadata</a>, <a href="#EnvironmentInfo-files">files</a>)
</pre>

Information about a Conda environment

**FIELDS**

| Name  | Description |
| :------------- | :------------- |
| <a id="EnvironmentInfo-metadata"></a>metadata |  (Dict[string, Dict]) Conda metadata for each package    |
| <a id="EnvironmentInfo-files"></a>files |  (DirectoryInfo) The files contained in this environment    |


<a id="get_files_provided_by"></a>

## get_files_provided_by

<pre>
load("@rules_conda//environment:providers.bzl", "get_files_provided_by")

get_files_provided_by(<a href="#get_files_provided_by-environment_info">environment_info</a>, <a href="#get_files_provided_by-package_name">package_name</a>, <a href="#get_files_provided_by-include_dependencies">include_dependencies</a>)
</pre>

Get all files provided by a package.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="get_files_provided_by-environment_info"></a>environment_info |  (EnvironmentInfo) The environment to use   |  none |
| <a id="get_files_provided_by-package_name"></a>package_name |  (string or List[string]) The name of the package or packages   |  none |
| <a id="get_files_provided_by-include_dependencies"></a>include_dependencies |  (bool) Whether or not to include files from dependencies as well   |  `True` |

**RETURNS**

(depset[File]) The files contained in the package


<a id="what_provides"></a>

## what_provides

<pre>
load("@rules_conda//environment:providers.bzl", "what_provides")

what_provides(<a href="#what_provides-environment_info">environment_info</a>, <a href="#what_provides-path">path</a>)
</pre>

Find the package that provided a file

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="what_provides-environment_info"></a>environment_info |  (EnvironmentInfo) The environment to use   |  none |
| <a id="what_provides-path"></a>path |  (string) The file path   |  none |

**RETURNS**

(string) The package containing the file, or None if the file doesn't exist in the environment


