EnvironmentInfo = provider(
    doc = "Information about a Conda environment",
    fields = {
        "metadata": "(Dict[string, Dict]) Conda metadata for each package",
        "files": "(DirectoryInfo) The files contained in this environment",
    },
)

def get_files_provided_by(environment_info, package_name, include_dependencies = True):
    """
    Get all files provided by a package.

    Args:
        environment_info: (EnvironmentInfo) The environment to use
        package_name: (string) The name of the package
        include_dependencies: (bool) Whether or not to include files from dependencies as well

    Returns:
        (depset[File]) The files contained in the package
    """
    files = []
    packages_remaining = [package_name]
    packages_searched = []

    # hack to loop over every package dependency
    for _ in range(2147483647):
        if len(packages_remaining) == 0:
            break

        package = packages_remaining[-1]

        if include_dependencies:
            for d in environment_info.metadata[package]["depends"]:
                d = d.split(" ")[0]
                if d not in packages_remaining and d not in packages_searched and d in environment_info.metadata:
                    packages_remaining.append(d)

        files.extend(environment_info.metadata[package]["files"])
        packages_searched.append(packages_remaining.pop())

    return environment_info.files.glob(include = files, exclude = [], allow_empty = True)

def what_provides(environment_info, path):
    """
    Find the package that provided a file

    Args:
        environment_info: (EnvironmentInfo) The environment to use
        path: (string) The file path

    Returns:
        (string) The package containing the file, or None if the file doesn't exist in the environment
    """
    for package in environment_info.metadata.values():
        if path in package["files"]:
            return package["name"]
    return None
