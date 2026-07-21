Pod::Spec.new do |spec|

  spec.name         = "SkyflowFlowVault"

  spec.version      = "3.0.0"

  spec.summary      = "skyflow-iOS-flowvault"

  spec.description  = "Skyflow iOS SDK for FlowDB-backed vaults"

  spec.homepage     = "https://github.com/skyflowapi/skyflow-iOS.git"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Skyflow" => "service-ops@skyflow.com" }

  spec.swift_version = '5.0'

  spec.platform     = :ios, "13.0"

  spec.ios.deployment_target = "13.0"

  # NOTE: this tag does not exist yet - create it (or update this field) when
  # the first SkyflowFlowVault release is actually cut.
  spec.source       = { :git => "https://github.com/skyflowapi/skyflow-iOS.git", :tag => "flowvault-3.0.0" }

  spec.source_files  = "Sources/SkyflowCore/**/*.{swift}", "Sources/SkyflowFlowVault/**/*.{swift}"

  spec.resource_bundles = {'SkyflowFlowVault' => ['Sources/SkyflowCore/Resources/**/*.{xcassets}'] }

end
