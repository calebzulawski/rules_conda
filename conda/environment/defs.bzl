load("//conda/cc:import.bzl", _import_library = "import_library")
load("//conda/environment/private:environment_glob.bzl", _environment_glob = "environment_glob")
load("//conda/environment/private:run_binary.bzl", _run_binary = "run_binary")

environment_glob = _environment_glob
run_binary = _run_binary
import_library = _import_library
