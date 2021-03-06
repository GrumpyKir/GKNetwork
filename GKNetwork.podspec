Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '10.0'
s.name = "GKNetwork"
s.summary = "Network layer"
s.requires_arc = true
s.version = "1.1.2"
s.license = { :type => "MIT", :file => "LICENSE" }
s.author = { "Opekishev Kirill" => "grumpykir@gmail.com" }
s.homepage = "https://github.com/GrumpyKir/GKNetwork"
s.source = { :git => "https://github.com/GrumpyKir/GKNetwork.git",
			 :tag => "#{s.version}" }
s.framework = "UIKit"
s.dependency 'GKExtensions', '~> 1.1.0'
s.source_files = "GKNetwork/SourceData/*.swift"
s.swift_version = "5.0"

end
