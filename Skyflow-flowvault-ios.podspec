Pod::Spec.new do |spec|

  spec.name         = "Skyflow-flowvault-ios"

  # Consumers import the SDK as `import SkyflowFlowVaultIOS` (Swift module names
  # cannot contain hyphens).
  spec.module_name  = "SkyflowFlowVaultIOS"

  spec.version      = "1.26.0-beta.1-dev.09b6e4d"

  spec.summary      = "skyflow-flowvault-iOS"

  spec.description  = "Skyflow FlowVault iOS SDK (v2 API)"

  spec.homepage     = "https://github.com/skyflowapi/skyflow-iOS.git"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Skyflow" => "service-ops@skyflow.com" }

  spec.swift_version = '5.9'

  spec.platform     = :ios, "13.0"

  spec.ios.deployment_target = "13.0"

  # Both SDKs share one version line: a single x.y.z tag releases both pods.
  spec.source       = { :git => "https://github.com/skyflowapi/skyflow-iOS.git", :commit => "09b6e4d" }

  # CocoaPods compiles the shared core and the FlowVault contract layer into a
  # single module, so the SPM-only re-export shim is excluded.
  spec.source_files  = "Sources/SkyflowCore/**/*.{swift}", "Sources/SkyflowFlowVaultIOS/**/*.{swift}"

  spec.exclude_files = "Sources/SkyflowFlowVaultIOS/Exports.swift"

  # `package` access-level declarations (shared across the SPM targets) require a
  # package name when compiled outside SPM.
  spec.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-package-name skyflow_ios_sdk' }

  # Bundle name intentionally stays 'Skyflow' — the shared core's asset lookups
  # load "Skyflow.bundle" (see SkyflowAssetBundle), and keeping one name for both
  # pods avoids any build-configuration dependence. The bundle is internal to the
  # pod and never seen by SDK consumers.
  spec.resource_bundles = {'Skyflow' => ['Sources/SkyflowCore/Resources/**/*.{xcassets}'] }

end
