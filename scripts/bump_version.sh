

# Both SDK products share one version line: this bumps Skyflow.podspec,
# SkyflowFlowVault.podspec, and the shared SDK_VERSION together.
#
# Usage:
#   ./scripts/bump_version.sh 1.27.0            # release version, tag 1.27.0
#   ./scripts/bump_version.sh 1.27.0 <commit>   # dev version pinned to a commit

version=$1
SEMVER=$version

PODSPECS="Skyflow.podspec SkyflowFlowVault.podspec"
VERSION_FILE="./Sources/SkyflowCore/Version.swift"

if [ -z $2 ]
then
    for podspec in $PODSPECS
    do
        sed -E "s/spec.version .+/spec.version      = \"$SEMVER\"/g" "./$podspec" > tempfile
        sed -E "s/source .+/source       = { :git => \"https:\/\/github.com\/skyflowapi\/skyflow-iOS.git\", :tag => \"$1\" }/g" tempfile > "./$podspec" && rm -f tempfile
    done
    sed -E "s/var SDK_VERSION = .+/var SDK_VERSION = \"$SEMVER\"/g" $VERSION_FILE > tempfile && cat tempfile > $VERSION_FILE && rm -f tempfile


    echo --------------------------
    echo "Done, Pods now at v$1"

else
    for podspec in $PODSPECS
    do
        sed -E "s/spec.version .+/spec.version      = \"$SEMVER-dev.$2\"/g" "./$podspec" > tempfile
        sed -E "s/source .+/source       = { :git => \"https:\/\/github.com\/skyflowapi\/skyflow-iOS.git\", :commit => \"$2\" }/g" tempfile > "./$podspec" && rm -f tempfile
    done
    sed -E "s/var SDK_VERSION = .+/var SDK_VERSION = \"$SEMVER-dev.$2\"/g" $VERSION_FILE > tempfile && cat tempfile > $VERSION_FILE && rm -f tempfile

    echo --------------------------
    echo "Done, Pods now at v$1-dev.$2"
fi
