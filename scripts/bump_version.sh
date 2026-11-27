# Both SDK products share one version line: this sets the shared SDK_VERSION
# in SkyflowCore/Sources/Version.swift. The release itself is the git tag
# (SPM resolves versions from tags), which must match this value.
#
# Usage:
#   ./scripts/bump_version.sh 1.27.0

version=$1
VERSION_FILE="./SkyflowCore/Sources/Version.swift"

if [ -z "$version" ]
then
    echo "Usage: $0 <version>"
    exit 1
fi

sed -E "s/var SDK_VERSION = .+/var SDK_VERSION = \"$version\"/g" $VERSION_FILE > tempfile && cat tempfile > $VERSION_FILE && rm -f tempfile

echo --------------------------
echo "Done, SDK_VERSION now at v$version"
