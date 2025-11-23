load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("//conda/environment:providers.bzl", "EnvironmentInfo", "dependent_packages", "file_relative_path", "get_files_provided_by", "what_provides")

def _build_linking_context(ctx):
    cc_toolchain = find_cc_toolchain(ctx)

    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    env_info = ctx.attr.environment[EnvironmentInfo]
    dir_info = env_info.files

    interface_library = dir_info.get_file(ctx.attr.interface_library) if ctx.attr.interface_library else None
    pic_static_library = dir_info.get_file(ctx.attr.pic_static_library) if ctx.attr.pic_static_library else None
    static_library = dir_info.get_file(ctx.attr.static_library) if ctx.attr.static_library else None
    shared_library = dir_info.get_file(ctx.attr.shared_library) if ctx.attr.shared_library else None

    libs = []
    if interface_library or pic_static_library or static_library or shared_library:
        libs.append(cc_common.create_library_to_link(
            actions = ctx.actions,
            cc_toolchain = cc_toolchain,
            feature_configuration = feature_configuration,
            interface_library = interface_library,
            dynamic_library = shared_library,
            static_library = static_library,
            pic_static_library = pic_static_library,
            alwayslink = ctx.attr.alwayslink,
        ))

    linker_input = cc_common.create_linker_input(
        owner = ctx.label,
        libraries = depset(libs),
    )
    return cc_common.create_linking_context(
        linker_inputs = depset([linker_input]),
    )

def _import_library(ctx):
    env_info = ctx.attr.environment[EnvironmentInfo]
    dir_info = env_info.files

    # Determine dev root dir
    if ctx.target_platform_has_constraint(ctx.attr._windows[platform_common.ConstraintValueInfo]):
        include_dir = "Library/include"
    else:
        include_dir = "include"

    # Collect package dependencies
    packages = {}
    for package in ctx.attr.packages:
        packages[package] = ()
        for dep in dependent_packages(env_info, package):
            packages[dep] = ()

    # Check library paths and packages
    for library in [ctx.attr.interface_library, ctx.attr.pic_static_library, ctx.attr.static_library, ctx.attr.shared_library]:
        if library == "":
            continue
        package = what_provides(env_info, library)
        if package == None:
            fail("Environment doesn't contain file: " + library)
        if package not in packages:
            fail("Library `{}` is in package `{}`, which isn't selected for import".format(library, package))

    # Get headers
    include_dir_info = dir_info.get_subdirectory(include_dir)
    headers = include_dir_info.transitive_files.to_list() if include_dir_info else []
    headers = [h for h in headers if what_provides(env_info, file_relative_path(env_info, h)) in packages]

    # Build include paths
    includes = [include_dir] + ctx.attr.includes
    includes = [paths.join(dir_info.path, i) for i in includes]

    # Build contexts
    compilation_context = cc_common.create_compilation_context(
        headers = depset(headers),
        direct_public_headers = headers,
        system_includes = depset(includes),
    )

    linking_context = _build_linking_context(ctx)

    # Merge with dependencies
    compilation_context = cc_common.merge_compilation_contexts(
        compilation_contexts = [d[CcInfo].compilation_context for d in ctx.attr.deps] + [compilation_context],
    )
    linking_context = cc_common.merge_linking_contexts(
        linking_contexts = [d[CcInfo].linking_context for d in ctx.attr.deps] + [linking_context],
    )

    return [CcInfo(
        compilation_context = compilation_context,
        linking_context = linking_context,
    )]

import_library = rule(
    doc = "Imports a library from an environment, as if by cc_import",
    implementation = _import_library,
    provides = [CcInfo],
    attrs = {
        "environment": attr.label(mandatory = True, providers = [EnvironmentInfo]),
        "deps": attr.label_list(default = [], providers = [CcInfo], doc = "The list of other libraries that the target depends on."),
        "packages": attr.string_list(default = [], doc = "Packages containing libraries and headers to import"),
        "alwayslink": attr.bool(default = False, doc = "If true, link in all object files specified by the static library, even if no symbols are referenced."),
        "includes": attr.string_list(default = [], doc = "List of include dirs to be added to the compile line, relative to the conda environment include directory root."),
        "interface_library": attr.string(),
        "pic_static_library": attr.string(),
        "shared_library": attr.string(),
        "static_library": attr.string(),
        "_windows": attr.label(default = "@platforms//os:windows"),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)
