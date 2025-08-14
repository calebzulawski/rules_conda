<!-- Generated with Stardoc: http://skydoc.bazel.build -->



<a id="conda_binary"></a>

## conda_binary

<pre>
load("@rules_conda//environment:environment.bzl", "conda_binary")

conda_binary(<a href="#conda_binary-name">name</a>, <a href="#conda_binary-environment">environment</a>, <a href="#conda_binary-path">path</a>)
</pre>

Create a binary target for an executable from an environment

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="conda_binary-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="conda_binary-environment"></a>environment |  The environment containing the binary   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="conda_binary-path"></a>path |  The path of the binary   | String | required |  |


