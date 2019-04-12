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

open class RemoteWorker: RemoteWorkerInterface {
    
    // MARK: - Props
    private var activeTasks: [String: URLSessionDataTask]
    
    // MARK: - Initialization
    public init() {
        self.activeTasks = [:]
    }
    
    // MARK: - RemoteWorkerInterface
    public func execute<T: Codable>(_ request: URLRequest, model: T.Type, completion: @escaping (_ result: T?, _ response: HTTPURLResponse?, _ error: Error?) -> Void) {
        guard let taskAbsoluteString: String = request.url?.absoluteString else {
            let invalidRequestError = NSError(domain: "[RemoteWorker] - Invalid request",
                                              code: 400,
                                              userInfo: nil)
            completion(nil, nil, invalidRequestError)
            
            return
        }
        if self.activeTasks[taskAbsoluteString] != nil {
            self.activeTasks[taskAbsoluteString]?.cancel()
        }
        
        let newTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let receivedData = data, let receivedResponse = response as? HTTPURLResponse, error == nil {
                NSLog("[RemoteWorker] - Response: \(receivedResponse)")
                
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
                        print("[NetworkWorker] - Data: \(object)")
                        
                        self.activeTasks[taskAbsoluteString] = nil
                        completion(object, receivedResponse, nil)
                    } catch let parsingError {
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
                NSLog("[RemoteWorker] - Error: \(error?.localizedDescription ?? "unknown error")")
                if let receivedResponse = response as? HTTPURLResponse {
                    NSLog("[RemoteWorker] - Response: \(receivedResponse)")
                    self.activeTasks[taskAbsoluteString] = nil
                    completion(nil, receivedResponse, error)
                } else {
                    self.activeTasks[taskAbsoluteString] = nil
                    completion(nil, nil, error)
                }
            }
        }
        
        self.activeTasks[taskAbsoluteString] = newTask
        self.activeTasks[taskAbsoluteString]?.resume()
    }
    
    public func cancel(_ request: URLRequest) {
        guard let taskAbsoluteString: String = request.url?.absoluteString else { return }
        
        if self.activeTasks[taskAbsoluteString] != nil {
            self.activeTasks[taskAbsoluteString]?.cancel()
        }
    }
    
    // MARK: - Module functions
}
