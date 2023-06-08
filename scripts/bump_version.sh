

version=$1
SEMVER=$version

if [ -z $2 ]
then
    sed -E "s/spec.version .+/spec.version      = \"$SEMVER\"/g" "./Skyflow.podspec" > tempfile
    sed -E "s/source .+/source       = { :git => \"https:\/\/github.com\/skyflowapi\/skyflow-iOS.git\", :tag => \"$1\" }/g" tempfile > ./Skyflow.podspec && rm -f tempfile
    sed -E "s/var SDK_VERSION = .+/var SDK_VERSION = \"$SEMVER\"/g" ./Sources/Skyflow/Version.swift > tempfile && cat tempfile > ./Sources/Skyflow/Version.swift && rm -f tempfile


    echo --------------------------
    echo "Done, Pod now at v$1"

else
    sed -E "s/spec.version .+/spec.version      = \"$SEMVER-dev.$2\"/g" "./Skyflow.podspec" > tempfile
    sed -E "s/source .+/source       = { :git => \"https:\/\/github.com\/skyflowapi\/skyflow-iOS.git\", :commit => \"$2\" }/g" tempfile > ./Skyflow.podspec && rm -f tempfile
    sed -E "s/var SDK_VERSION = .+/var SDK_VERSION = \"$SEMVER-dev.$2\"/g" ./Sources/Skyflow/Version.swift > tempfile && cat tempfile > ./Sources/Skyflow/Version.swift && rm -f tempfile

    echo --------------------------
    echo "Done, Pod now at v$1-dev.$2"
fi

        

