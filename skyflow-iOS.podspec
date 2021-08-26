Pod::Spec.new do |spec|

  spec.name         = "skyflow-iOS"
  spec.version      = "1.0.0"
  spec.summary      = "skyflow-iOS"

  spec.description  = "skyflow-iOS SDK"

  spec.homepage     = "https://www.skyflow.com"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Skyflow" => "service-ops@skyflow.com" }

  spec.swift_version = '4.2'

  spec.platform     = :ios, "9.0"
  spec.ios.deployment_target = "9.0"

  spec.source       = { :git => "https://github.com/skyflowapi/skyflow-iOS.git", :tag => "#{spec.version}" }

  spec.source_files  = "Sources/Skyflow/**/*.{swift}"

end
