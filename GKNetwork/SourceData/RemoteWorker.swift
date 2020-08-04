//
//  RemoteWorker.swift
//  GKNetwork
//
//  Created by  Кирилл on 4/12/19.
//  Copyright © 2019 AppCraft. All rights reserved.
//

import UIKit

public protocol RemoteWorkerInterface: AnyObject {
    func execute<T: Codable>(_ request: URLRequest, model: T.Type, completion: @escaping (_ result: T?, _ response: HTTPURLResponse?, _ error: Error?) -> Void)
    func cancel(_ request: URLRequest)
}

open class RemoteWorker: NSObject, RemoteWorkerInterface {
    
    // MARK: - Props
    private weak var sessionDelegate: URLSessionDelegate?
    private var activeTasks: [String: URLSessionDataTask]
    private var urlSession: URLSession?
    private var isLoggingEnabled: Bool
    
    // MARK: - Initialization
    public init(sessionConfiguration: URLSessionConfiguration? = nil, isLoggingEnabled: Bool = RemoteConfiguration.shared.isLoggingEnabled, sessionDelegate: URLSessionDelegate? = nil) {
        self.activeTasks = [:]
        self.isLoggingEnabled = isLoggingEnabled
        self.sessionDelegate = sessionDelegate
        
        super.init()
        
        if let sessionConfiguration = sessionConfiguration {
            self.urlSession = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
        } else {
            self.urlSession = URLSession(configuration: RemoteConfiguration.shared.sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
        }
    }
    
    // MARK: - RemoteWorkerInterface
    public func execute<T: Codable>(_ request: URLRequest, model: T.Type, completion: @escaping (_ result: T?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) {
        guard let taskAbsoluteString: String = request.url?.absoluteString else {
            let invalidRequestError = NSError(domain: "Invalid request", code: 999, userInfo: nil)
            completion(nil, nil, invalidRequestError)
            
            return
        }
        if self.activeTasks[taskAbsoluteString] != nil {
            if self.isLoggingEnabled {
                NSLog("[GKNetwork:RemoteWorker] - WARNING: Same task < \(request.url?.absoluteString ?? "UNKNOWN") > canceled")
            }
            self.activeTasks[taskAbsoluteString]?.cancel()
        }
        
        let newTask = self.urlSession?.dataTask(with: request, completionHandler: { (data, response, error) in
            if let receivedData = data, let receivedResponse = response as? HTTPURLResponse, error == nil {
                if self.isLoggingEnabled {
                    NSLog("[GKNetwork:RemoteWorker] - STATUS CODE: \(receivedResponse.statusCode)")
                    NSLog("[GKNetwork:RemoteWorker] - RESPONSE HEADER:\n\(receivedResponse.allHeaderFields)")
                    NSLog("[GKNetwork:RemoteWorker] - RESPONSE DATA:\n\(String(data: receivedData, encoding: .utf8) ?? "UNKNOWN")")
                }
                
                switch receivedResponse.statusCode {
                case 200:
                    if let okString = String(data: receivedData, encoding: .utf8), okString.lowercased() == "ok" {
                        self.activeTasks[taskAbsoluteString] = nil
                        completion(nil, receivedResponse, nil)
                        
                        return
                    }
                    
                    do {
                        let jsonDecoder = JSONDecoder()
                        let object = try jsonDecoder.decode(model, from: receivedData)
                        
                        self.activeTasks[taskAbsoluteString] = nil
                        completion(object, receivedResponse, nil)
                    } catch let parsingError {
                        if self.isLoggingEnabled {
                            NSLog("[GKNetwork:RemoteWorker] - ERROR: Parsing error \(parsingError.localizedDescription)")
                        }
                        
                        self.activeTasks[taskAbsoluteString] = nil
                        completion(nil, receivedResponse, parsingError)
                    }
                default:
                    let serverError = NSError(domain: "",
                                              code: receivedResponse.statusCode,
                                              userInfo: nil)
                    self.activeTasks[taskAbsoluteString] = nil
                    completion(nil, receivedResponse, serverError)
                }
            } else {
                if let receivedResponse = response as? HTTPURLResponse {
                    if self.isLoggingEnabled {
                        NSLog("[GKNetwork:RemoteWorker] - STATUS CODE: \(receivedResponse.statusCode)")
                        NSLog("[GKNetwork:RemoteWorker] - ERROR: Session error")
                        NSLog("[GKNetwork:RemoteWorker] - ERROR CODE: \((error as NSError?)?.code ?? -1)")
                        NSLog("[GKNetwork:RemoteWorker] - ERROR DESCRIPTION: \((error as NSError?)?.description ?? "UNKNOWN")")
                    }
                    
                    self.activeTasks[taskAbsoluteString] = nil
                    completion(nil, receivedResponse, error)
                } else {
                    if self.isLoggingEnabled {
                        NSLog("[GKNetwork:RemoteWorker] - ERROR: Internal error")
                        NSLog("[GKNetwork:RemoteWorker] - ERROR CODE: \((error as NSError?)?.code ?? -1)")
                        NSLog("[GKNetwork:RemoteWorker] - ERROR DESCRIPTION: \((error as NSError?)?.description ?? "UNKNOWN")")
                    }
                    
                    self.activeTasks[taskAbsoluteString] = nil
                    completion(nil, nil, error)
                }
            }
        })
        
        self.activeTasks[taskAbsoluteString] = newTask
        self.activeTasks[taskAbsoluteString]?.resume()
    }
    
    public func cancel(_ request: URLRequest) {
        guard let taskAbsoluteString: String = request.url?.absoluteString else { return }
        
        if self.activeTasks[taskAbsoluteString] != nil {
            if self.isLoggingEnabled {
                NSLog("[GKNetwork:RemoteWorker] - WARNING: Task < \(request.url?.absoluteString ?? "UNKNOWN") > canceled")
            }
            self.activeTasks[taskAbsoluteString]?.cancel()
        }
    }
    
    // MARK: - Module functions
}
