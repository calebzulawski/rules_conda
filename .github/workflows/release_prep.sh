#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

TAG="$1"
VERSION="${TAG#v}"
PREFIX="rules_conda-${VERSION}"
ARCHIVE="rules_conda-$TAG.tar.gz"
git archive --format=tar --prefix=${PREFIX}/ ${TAG} | gzip > $ARCHIVE
SHA=$(shasum -a 256 $ARCHIVE | awk '{print $1}')

cat << EOF
## Using Bzlmod

Paste this snippet into your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_conda", version = "${VERSION}")
\`\`\`

EOF
