Pod::Spec.new do |spec|

  spec.name         = "Skyflow"
  spec.version      = "1.0.1"
  spec.summary      = "skyflow-iOS"

  spec.description  = "Skyflow iOS SDK"

  spec.homepage     = "https://github.com/skyflowapi/skyflow-iOS.git"

  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "Skyflow" => "service-ops@skyflow.com" }

  spec.swift_version = '4.2'

  spec.platform     = :ios, "9.0"
  spec.ios.deployment_target = "9.0"

  spec.source       = { :git => "https://github.com/skyflowapi/skyflow-iOS.git", :commit => "1df6553963f2561a62c7557bdbb9c7ff0852b3e6" }

  spec.source_files  = "Sources/Skyflow/**/*.{swift}"

end
