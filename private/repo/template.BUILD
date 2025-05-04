filtered_files = [f for f in glob(
    ["**/*"],
) if ":" not in f]

filegroup(
    name = "files",
    srcs = filtered_files,
    visibility = ["//visibility:public"],
)

exports_files(filtered_files)
