load("//environment/private:environment_glob.bzl", _environment_glob = "environment_glob")
load("//environment/private:import_library.bzl", _import_library = "import_library")
load("//environment/private:run_binary.bzl", _run_binary = "run_binary")

run_binary = _run_binary
environment_glob = _environment_glob
import_library = _import_library
