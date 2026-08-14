Pod::Spec.new do |spec|

  spec.name         = "Skyflow"

  spec.version      = "1.26.0-beta.1"

  spec.summary      = "skyflow-iOS"

  spec.description  = "Skyflow iOS SDK"

  spec.homepage     = "https://github.com/skyflowapi/skyflow-iOS.git"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Skyflow" => "service-ops@skyflow.com" }

  spec.swift_version = '5.9'

  spec.platform     = :ios, "13.0"

  spec.ios.deployment_target = "13.0"

  spec.source       = { :git => "https://github.com/skyflowapi/skyflow-iOS.git", :tag => "1.26.0-beta.1" }

  # CocoaPods compiles the shared core and the legacy contract layer into a single
  # module, so the SPM-only re-export shim is excluded.
  spec.source_files  = "Sources/SkyflowCore/**/*.{swift}", "Sources/Skyflow/**/*.{swift}"

  spec.exclude_files = "Sources/Skyflow/Exports.swift"

  # `package` access-level declarations (shared across the SPM targets) require a
  # package name when compiled outside SPM.
  spec.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-package-name skyflow_ios_sdk' }

  spec.resource_bundles = {'Skyflow' => ['Sources/SkyflowCore/Resources/**/*.{xcassets}'] }

end
