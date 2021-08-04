Pod::Spec.new do |spec|
	spec.platform				= :ios
	spec.ios.deployment_target	= "10.0"

	spec.name 			= "GKNetwork"
	spec.version 		= "2.0.0"
	spec.license 		= { :type => "MIT", :file => "LICENSE" }
	spec.homepage 		= "https://github.com/GrumpyKir/GKRepresentable"
	spec.author 		= { "Opekishev Kirill" => "grumpykir@gmail.com" }
	spec.summary 		= "Native network layer with logger and request builder"
	spec.source 		= { :git => "https://github.com/GrumpyKir/GKNetwork.git", :tag => "#{spec.version}" }
	spec.swift_version 	= "5.0"

	spec.source_files = "GKNetwork/SourceData/*.swift"
	
	spec.framework		= "UIKit"
	spec.requires_arc	= true
	spec.dependency 'GKExtensions', '~> 1.2.0'
end
