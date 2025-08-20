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


<a id="dependent_packages"></a>

## dependent_packages

<pre>
load("@rules_conda//environment:providers.bzl", "dependent_packages")

dependent_packages(<a href="#dependent_packages-environment_info">environment_info</a>, <a href="#dependent_packages-package">package</a>)
</pre>

Get the dependent packages of a package

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="dependent_packages-environment_info"></a>environment_info |  (EnvironmentInfo) The environment to use   |  none |
| <a id="dependent_packages-package"></a>package |  (string) The name of a package   |  none |

**RETURNS**

(string) The names of dependent packages


<a id="file_relative_path"></a>

## file_relative_path

<pre>
load("@rules_conda//environment:providers.bzl", "file_relative_path")

file_relative_path(<a href="#file_relative_path-environment_info">environment_info</a>, <a href="#file_relative_path-file">file</a>)
</pre>

Get the relative path of a file to the environment

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="file_relative_path-environment_info"></a>environment_info |  (EnvironmentInfo) The environment to use   |  none |
| <a id="file_relative_path-file"></a>file |  (File) The file   |  none |

**RETURNS**

(string) The file path relative to the environment


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


