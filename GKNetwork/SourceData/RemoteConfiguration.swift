//
//  RemoteConfiguration.swift
//  GKNetwork
//
//  Created by  Кирилл on 1/10/20.
//  Copyright © 2020 AppCraft. All rights reserved.
//

import Foundation
import UIKit

public class RemoteConfiguration {
    
    public static var shared: RemoteConfiguration = RemoteConfiguration()
    
    public var sessionConfiguration: URLSessionConfiguration {
        return self.sessionConfigurationValue
    }
    
    public var isLoggingEnabled: Bool {
        #if DEBUG
        return self.isLoggingEnabledValue
        #else
        return false
        #endif
    }
    
    private var sessionConfigurationValue: URLSessionConfiguration
    private var isLoggingEnabledValue: Bool
    
    private init() {
        self.sessionConfigurationValue = URLSessionConfiguration()
        self.sessionConfigurationValue = .default
        
        self.isLoggingEnabledValue = false
    }
    
    public func setConfiguration(value: URLSessionConfiguration) {
        self.sessionConfigurationValue = value
    }
    
    public func enableLogging(value: Bool) {
        self.isLoggingEnabledValue = value
    }
    
}
