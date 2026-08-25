Pod::Spec.new do |spec|

  spec.name         = "SkyflowFlowVault"

  spec.version      = "1.26.0"

  spec.summary      = "SkyflowFlowVault"

  spec.description  = "Skyflow FlowVault iOS SDK"

  spec.homepage     = "https://github.com/skyflowapi/skyflow-iOS.git"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author       = { "Skyflow" => "service-ops@skyflow.com" }

  spec.swift_version = '5.9'

  spec.platform     = :ios, "13.0"

  spec.ios.deployment_target = "13.0"

  # Both SDKs share one version line: a single x.y.z tag releases both pods.
  spec.source       = { :git => "https://github.com/skyflowapi/skyflow-iOS.git", :tag => "1.26.0" }

  # CocoaPods compiles the shared core and the FlowVault contract layer into a
  # single module, so the SPM-only re-export shim is excluded.
  spec.source_files  = "SkyflowCore/Sources/**/*.{swift}", "SkyflowFlowVault/Sources/**/*.{swift}"

  spec.exclude_files = "SkyflowFlowVault/Sources/Exports.swift"

  # `package` access-level declarations (shared across the SPM targets) require a
  # package name when compiled outside SPM.
  spec.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-package-name skyflow_ios_sdk' }

  # Bundle name intentionally stays 'Skyflow' — the shared core's asset lookups
  # load "Skyflow.bundle" (see SkyflowAssetBundle), and keeping one name for both
  # pods avoids any build-configuration dependence. The bundle is internal to the
  # pod and never seen by SDK consumers.
  spec.resource_bundles = {'Skyflow' => ['SkyflowCore/Sources/Resources/**/*.{xcassets}'] }

end
