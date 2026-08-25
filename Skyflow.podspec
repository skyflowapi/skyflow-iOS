Pod::Spec.new do |spec|

  spec.name         = "Skyflow"

  spec.version      = "1.26.0"

  spec.summary      = "skyflow-iOS"

  spec.description  = "Skyflow iOS SDK"

  spec.homepage     = "https://github.com/skyflowapi/skyflow-iOS.git"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Skyflow" => "service-ops@skyflow.com" }

  spec.swift_version = '5.9'

  spec.platform     = :ios, "13.0"

  spec.ios.deployment_target = "13.0"

  spec.source       = { :git => "https://github.com/skyflowapi/skyflow-iOS.git", :tag => "1.26.0" }

  spec.source_files  = "SkyflowCore/Sources/**/*.{swift}", "Skyflow/Sources/**/*.{swift}"

  spec.exclude_files = "Skyflow/Sources/Exports.swift"

  spec.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-package-name skyflow_ios_sdk' }

  spec.resource_bundles = {'Skyflow' => ['SkyflowCore/Sources/Resources/**/*.{xcassets}'] }

end
