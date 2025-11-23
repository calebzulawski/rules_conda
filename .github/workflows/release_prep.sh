#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

TAG="$1"
VERSION="${TAG#v}"
PREFIX="rules_conda-${VERSION}"
ARCHIVE="rules_conda-$TAG.tar.gz"
DOC_ARCHIVE="${ARCHIVE%.tar.gz}.docs.tar.gz"
WORKSPACE_DIR="${GITHUB_WORKSPACE:-$PWD}"

git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip >"$ARCHIVE"
SHA=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')

docs_output_base="$(mktemp -d)"
targets_file="$(mktemp)"
cleanup() {
	rm -rf "$docs_output_base"
	rm -f "$targets_file"
}
trap cleanup EXIT

bazel --output_base="$docs_output_base" query \
	--output=label \
	--output_file="$targets_file" \
	'kind("starlark_doc_extract rule", //...)'

if [[ ! -s "$targets_file" ]]; then
	echo "No starlark_doc_extract targets were found; expected bazel_lib.bzl_library docs to exist." >&2
	exit 1
fi

bazel --output_base="$docs_output_base" build --target_pattern_file="$targets_file"

tar --create --auto-compress \
	--directory "$(bazel --output_base="$docs_output_base" info bazel-bin)" \
	--file "${WORKSPACE_DIR}/${DOC_ARCHIVE}" \
	.

cat <<EOF
## Using Bzlmod

Paste this snippet into your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_conda", version = "${VERSION}")
\`\`\`

EOF
