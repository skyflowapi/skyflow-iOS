Pod::Spec.new do |spec|

  spec.name         = "Skyflow"

  spec.version      = "1.17.5-dev.cb7b1ab"

  spec.summary      = "skyflow-iOS"

  spec.description  = "Skyflow iOS SDK"

  spec.homepage     = "https://github.com/skyflowapi/skyflow-iOS.git"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Skyflow" => "service-ops@skyflow.com" }

  spec.swift_version = '4.2'

  spec.platform     = :ios, "9.0"
  
  spec.ios.deployment_target = "9.0"

  spec.source       = { :git => "https://github.com/skyflowapi/skyflow-iOS.git", :commit => "cb7b1ab" }

  spec.source_files  = "Sources/Skyflow/**/*.{swift}"

  spec.resource_bundles = {'Skyflow' => ['Sources/Skyflow/Resources/**/*.{xcassets}'] }

  spec.dependency "AEXML"
end

