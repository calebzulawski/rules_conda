EnvironmentInfo = provider(
    doc = "Information about a Conda environment",
    fields = {
        "metadata": "(Dict[string, Dict]) Conda metadata for each package",
        "files": "(DirectoryInfo) The files contained in this environment",
    },
)

def dependent_packages(environment_info, package):
    """
    Get the dependent packages of a package

    Args:
        environment_info: (EnvironmentInfo) The environment to use
        package: (string) The name of a package

    Returns:
        (string) The names of dependent packages
    """
    depends = []
    for d in environment_info.metadata[package]["depends"]:
        d = d.split(" ")[0]

        # exclude virtual packages
        if d in environment_info.metadata:
            depends.append(d)
    return depends

def get_files_provided_by(environment_info, package_name, include_dependencies = True):
    """
    Get all files provided by a package.

    Args:
        environment_info: (EnvironmentInfo) The environment to use
        package_name: (string or List[string]) The name of the package or packages
        include_dependencies: (bool) Whether or not to include files from dependencies as well

    Returns:
        (depset[File]) The files contained in the package
    """
    if type(package_name) == type(""):
        package_name = [package_name]

    files = []
    packages_remaining = [] + package_name
    packages_searched = []

    # hack to loop over every package dependency
    for _ in range(2147483647):
        if len(packages_remaining) == 0:
            break

        package = packages_remaining.pop()
        packages_searched.append(package)
        files.extend(environment_info.metadata[package]["files"])

        if include_dependencies:
            for d in dependent_packages(environment_info, package):
                if d not in packages_remaining and d not in packages_searched:
                    packages_remaining.append(d)

    return environment_info.files.glob(include = files, exclude = [], allow_empty = True)

def file_relative_path(environment_info, file):
    """
    Get the relative path of a file to the environment

    Args:
        environment_info: (EnvironmentInfo) The environment to use
        file: (File) The file

    Returns:
        (string) The file path relative to the environment
    """
    return file.path.removeprefix(environment_info.files.path).removeprefix("/")

def what_provides(environment_info, path):
    """
    Find the package that provided a file

    Args:
        environment_info: (EnvironmentInfo) The environment to use
        path: (string) The file path

    Returns:
        (string) The package containing the file, or None if the file doesn't exist in the environment
    """
    if type(path) != type(""):
        fail("Expected string")
    for package in environment_info.metadata.values():
        if path in package["files"]:
            return package["name"]
    return None
