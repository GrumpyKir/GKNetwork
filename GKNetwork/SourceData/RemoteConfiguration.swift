//
//  RemoteConfiguration.swift
//  GKNetwork
//
//  Created by  Кирилл on 1/10/20.
//  Copyright © 2020 AppCraft. All rights reserved.
//

import Foundation

public class RemoteConfiguration {
    
    // MARK: - Singleton Property
    public static var shared: RemoteConfiguration = RemoteConfiguration()
    
    // MARK: - Props
    public var sessionConfiguration: URLSessionConfiguration
    public var loggerConfiguration: RemoteLoggerConfiguration
    
    // MARK: - Initialization
    private init() {
        self.sessionConfiguration = URLSessionConfiguration.default
        self.loggerConfiguration = RemoteLoggerConfiguration()
    }
}

public class RemoteLoggerConfiguration {
    
    // MARK: - Props
    public var isEnabled: Bool
    public var maxEvents: Int
    
    // MARK: - Initialization
    public init() {
        self.isEnabled = false
        self.maxEvents = 10
    }
}
