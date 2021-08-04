//
//  RemoteWorker.swift
//  GKNetwork
//
//  Created by  Кирилл on 4/12/19.
//  Copyright © 2019 AppCraft. All rights reserved.
//

import Foundation

public protocol RemoteWorkerInterface: AnyObject {
    var tasks: [String: URLSessionDataTask] { get }
    
    func execute(_ request: URLRequest, completion: @escaping (_ result: RemoteWorkerResult) -> Void) -> String
    func cancel(_ taskUid: String)
}

open class RemoteWorker: NSObject, RemoteWorkerInterface {
    
    // MARK: - Private Props
    private var activeTasks: [String: URLSessionDataTask]
    private var urlSession: URLSession?
    
    // MARK: - Delegate Props
    private weak var urlSessionDelegate: URLSessionDelegate?
    
    // MARK: - Initialization
    public init(sessionDelegate: URLSessionDelegate? = nil) {
        self.activeTasks = [:]
        
        super.init()
        
        self.urlSession = URLSession(configuration: RemoteConfiguration.shared.sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
        self.urlSessionDelegate = sessionDelegate
    }
    
    // MARK: - RemoteWorkerInterface
    public var tasks: [String: URLSessionDataTask] {
        return self.activeTasks
    }
    
    public func execute(_ request: URLRequest, completion: @escaping (_ result: RemoteWorkerResult) -> Void) -> String {
        let newTaskUid: String = UUID().uuidString
        RemoteLogger.shared.logEvent(uid: newTaskUid)
        
        let newTask = self.urlSession?.dataTask(with: request, completionHandler: { data, response, error in
            self.activeTasks[newTaskUid] = nil
            
            let result = RemoteWorkerResult(data: data, response: response as? HTTPURLResponse, error: error)
            RemoteLogger.shared.logEvent(uid: newTaskUid, result: result)
            
            completion(result)
        })
        
        self.activeTasks[newTaskUid] = newTask
        self.activeTasks[newTaskUid]?.resume()
        
        return newTaskUid
    }
    
    public func cancel(_ taskUid: String) {
        if self.activeTasks[taskUid] != nil {
            RemoteLogger.shared.logEvent(uid: taskUid, isCanceled: true)
            
            self.activeTasks[taskUid]?.cancel()
        }
    }
}

public class RemoteWorkerResult {
    public var data: Data?
    public var response: HTTPURLResponse?
    public var error: Error?
    
    public init(data: Data?, response: HTTPURLResponse?, error: Error?) {
        self.data = data
        self.response = response
        self.error = error
    }
}
