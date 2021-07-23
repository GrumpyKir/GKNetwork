//
//  RemoteWorker.swift
//  GKNetwork
//
//  Created by  Кирилл on 4/12/19.
//  Copyright © 2019 AppCraft. All rights reserved.
//

import UIKit

public protocol RemoteWorkerInterface: AnyObject {
    var isLoggingEnabled: Bool { get set }
    
    func execute(_ request: URLRequest, completion: @escaping (_ result: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) -> String
    func cancel(_ taskUid: String)
}

open class RemoteWorker: NSObject, RemoteWorkerInterface {
    
    // MARK: - Props
    public var isLoggingEnabled: Bool
    
    private weak var sessionDelegate: URLSessionDelegate?
    private var activeTasks: [String: URLSessionDataTask]
    private var urlSession: URLSession?
    
    // MARK: - Initialization
    public init(sessionConfiguration: URLSessionConfiguration? = nil, sessionDelegate: URLSessionDelegate? = nil) {
        self.activeTasks = [:]
        self.isLoggingEnabled = RemoteConfiguration.shared.isLoggingEnabled
        self.sessionDelegate = sessionDelegate
        
        super.init()
        
        if let sessionConfiguration = sessionConfiguration {
            self.urlSession = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
        } else {
            self.urlSession = URLSession(configuration: RemoteConfiguration.shared.sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
        }
    }
    
    // MARK: - RemoteWorkerInterface
    public func execute(_ request: URLRequest, completion: @escaping (_ result: Data?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) -> String {
        let newTaskUid: String = UUID()
        
        let newTask = self.urlSession?.dataTask(with: request, completionHandler: { data, response, error in
            if self.isLoggingEnabled {
                NSLog("[GKNetwork:RemoteWorker] - REQUEST URL: \(request.url?.absoluteString ?? "UNKNOWN")")
                if let requestHeaders = request.allHTTPHeaderFields {
                    NSLog("[GKNetwork:RemoteWorker] - REQUEST HEADERS: \(requestHeaders)")
                }
                if let requestBody = request.httpBody, let requestBodyString = String(data: requestBody, encoding: .utf8) {
                    NSLog("[GKNetwork:RemoteWorker] - REQUEST BODY: \(requestBodyString)")
                }
                
                NSLog("[GKNetwork:RemoteWorker] - RESPONSE CODE: \(receivedResponse.statusCode)")
                if let responseHeaders = receivedResponse.allHeaderFields as? [String: Any] {
                    NSLog("[GKNetwork:RemoteWorker] - RESPONSE HEADERS: \(responseHeaders)")
                }
                if let stringData = String(data: receivedData, encoding: .utf8) {
                    NSLog("[GKNetwork:RemoteWorker] - RESPONSE DATA: \(stringData)")
                } else {
                    NSLog("[GKNetwork:RemoteWorker] - RESPONSE DATA: UNKNOWN")
                }
            }
            
            self.activeTasks[newTaskUid] = nil
            completion(data, response as? HTTPURLResponse, error)
        })
        
        self.activeTasks[newTaskUid] = newTask
        self.activeTasks[newTaskUid]?.resume()
        
        return newTaskUid
    }
    
    public func cancel(_ taskUid: String) {
        if self.activeTasks[taskUid] != nil {
            if self.isLoggingEnabled {
                NSLog("[GKNetwork:RemoteWorker] - WARNING: Task < \(taskUid) > canceled")
            }
            
            self.activeTasks[taskUid]?.cancel()
        }
    }
    
    // MARK: - Module functions
}
