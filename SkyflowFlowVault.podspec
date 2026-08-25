Pod::Spec.new do |spec|

  spec.name         = "SkyflowFlowVault"

  spec.version      = "1.26.0-beta.1-dev.230f920"

  spec.summary      = "SkyflowFlowVault"

  spec.description  = "Skyflow FlowVault iOS SDK"

  spec.homepage     = "https://github.com/skyflowapi/skyflow-iOS.git"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author       = { "Skyflow" => "service-ops@skyflow.com" }

  spec.swift_version = '5.9'

  spec.platform     = :ios, "13.0"

  spec.ios.deployment_target = "13.0"

  spec.source       = { :git => "https://github.com/skyflowapi/skyflow-iOS.git", :commit => "230f920" }

  spec.source_files  = "SkyflowCore/Sources/**/*.{swift}", "SkyflowFlowVault/Sources/**/*.{swift}"

  spec.exclude_files = "SkyflowFlowVault/Sources/Exports.swift"

  spec.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-package-name skyflow_ios_sdk' }

  spec.resource_bundles = {'Skyflow' => ['SkyflowCore/Sources/Resources/**/*.{xcassets}'] }

end
