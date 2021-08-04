//
//  RemoteLogger.swift
//  GKNetwork
//
//  Created by Кирилл Опекишев on 04.08.2021.
//  Copyright © 2021 AppCraft. All rights reserved.
//

import Foundation

public class RemoteLogger {
    
    // MARK: - Singleton Property
    public static var shared: RemoteLogger = RemoteLogger()
    
    // MARK: - Props
    private var events: [RemoteLoggerEvent]
    private let loggerQueue: DispatchQueue
    
    // MARK: - Initialization
    private init() {
        self.events = []
        self.loggerQueue = DispatchQueue(label: "RemoteLoggerQueue", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
    }
    
    // MARK: - Public methods
    public func logEvent(uid: String) {
        if RemoteConfiguration.shared.loggerConfiguration.isEnabled {
            let now = Date()
            
            self.loggerQueue.sync {
                if !self.events.contains(where: { $0.eventId == uid }) {
                    let newEvent = RemoteLoggerEvent(uid: uid, createdAt: now)
                    
                    let maxEvents: Int = RemoteConfiguration.shared.loggerConfiguration.maxEvents < 1 ? 1 : RemoteConfiguration.shared.loggerConfiguration.maxEvents
                    
                    if self.events.count >= maxEvents {
                        self.events.remove(at: 0)
                    }
                    self.events.append(newEvent)
                }
            }
        }
    }
    
    public func logEvent(uid: String, request: URLRequest) {
        if RemoteConfiguration.shared.loggerConfiguration.isEnabled {
            let now = Date()
            
            self.logEvent(uid: uid)
            
            self.loggerQueue.sync {
                if let event = self.events.first(where: { $0.eventId == uid }) {
                    event.start(with: request, startAt: now)
                }
            }
        }
    }
    
    public func logEvent(uid: String, result: RemoteWorkerResult) {
        if RemoteConfiguration.shared.loggerConfiguration.isEnabled {
            let now = Date()
            
            self.logEvent(uid: uid)
            
            self.loggerQueue.sync {
                if let event = self.events.first(where: { $0.eventId == uid }) {
                    event.finish(with: result, finishAt: now)
                }
            }
        }
    }
    
    public func logEvent(uid: String, isCanceled: Bool) {
        if RemoteConfiguration.shared.loggerConfiguration.isEnabled {
            let now = Date()
            
            self.logEvent(uid: uid)
            
            if isCanceled {
                self.loggerQueue.sync {
                    if let event = self.events.first(where: { $0.eventId == uid }) {
                        event.cancel(cancelAt: now)
                    }
                }
            }
        }
    }
    
    public func getEvent(uid: String) -> RemoteLoggerEvent? {
        self.loggerQueue.sync {
            return self.events.first(where: { $0.eventId == uid })
        }
    }
    
    public func getAllEvents() -> [RemoteLoggerEvent] {
        self.loggerQueue.sync {
            return self.events
        }
    }
    
    
    public func getLastEvent() -> RemoteLoggerEvent? {
        self.loggerQueue.sync {
            return self.events.last
        }
    }
    
    public func getLastEvents(numberOfEvents: Int) -> [RemoteLoggerEvent] {
        self.loggerQueue.sync {
            if self.events.isEmpty {
                return []
            }
            
            let firstEventIndex = (self.events.count - numberOfEvents) < 0 ? 0 : self.events.count - numberOfEvents
            let lastEventIndex = self.events.count - 1
            
            var filteredEvents: [RemoteLoggerEvent] = []
            for index in (firstEventIndex...lastEventIndex) {
                filteredEvents.append(self.events[index])
            }
            
            return filteredEvents
        }
    }
    
    public func clearAllEvents() {
        self.loggerQueue.sync {
            self.events = []
        }
    }
    
    // MARK: - Private methods
}

public enum RemoteLoggerEventStatus {
    case new
    case executing
    case finished
    case canceled
}

public class RemoteLoggerEvent {
    
    // MARK: - Private Props
    private let uid: String
    private var status: RemoteLoggerEventStatus
    private var requestData: URLRequest?
    private var resultData: RemoteWorkerResult?
    private var dateCreated: Date
    private var dateStartRequest: Date?
    private var dateFinishRequest: Date?
    
    // MARK: - Computed Props
    public var eventId: String {
        return self.uid
    }
    
    public var currentStatus: RemoteLoggerEventStatus {
        return self.status
    }
    
    public var request: RemoteLoggerEventRequest? {
        guard let request = self.requestData else { return nil }
        
        return RemoteLoggerEventRequest(request: request)
    }
    
    public var result: RemoteLoggerEventResult? {
        guard let result = self.resultData else { return nil }
        
        return RemoteLoggerEventResult(result: result)
    }
    
    public var dates: RemoteLoggerEventDate {
        return RemoteLoggerEventDate(dateCreated: self.dateCreated, dateStartRequest: self.dateStartRequest, dateFinishRequest: self.dateFinishRequest)
    }
    
    // MARK: - Initialization
    public init(uid: String, createdAt: Date = Date()) {
        self.uid = uid
        self.status = .new
        self.dateCreated = createdAt
    }
    
    // MARK: - Public methods
    public func start(with request: URLRequest, startAt: Date = Date()) {
        if self.status == .new {
            self.status = .executing
            
            self.requestData = request
            self.dateStartRequest = startAt
        }
    }
    
    public func finish(with result: RemoteWorkerResult, finishAt: Date = Date()) {
        if self.status == .executing {
            self.status = .finished
            
            self.resultData = result
            self.dateFinishRequest = finishAt
        }
    }
    
    public func cancel(cancelAt: Date = Date()) {
        if self.status == .executing {
            self.status = .canceled
            self.dateFinishRequest = cancelAt
        }
    }
}

public class RemoteLoggerEventRequest {
    
    // MARK: - Private Props
    private let request: URLRequest
    
    // MARK: - Computed Props
    public var raw: URLRequest {
        return self.request
    }
    
    public var url: URL? {
        return self.request.url
    }
    
    public var headers: [String: String]? {
        return self.request.allHTTPHeaderFields
    }
    
    public var body: Data? {
        return self.request.httpBody
    }
    
    public var bodyString: String? {
        guard let bodyData = self.body else { return nil }
        
        return String(data: bodyData, encoding: .utf8)
    }
    
    public var bodyJSON: [[String: Any]]? {
        guard let bodyData = self.body else { return nil }
        
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: bodyData, options: .allowFragments) as? [[String: Any]]
            return jsonArray
        } catch {
            return nil
        }
    }
    
    // MARK: - Initialization
    public init(request: URLRequest) {
        self.request = request
    }
}

public class RemoteLoggerEventResult {
    
    // MARK: - Private Props
    private let result: RemoteWorkerResult
    
    // MARK: - Computed Props
    public var code: Int? {
        return self.result.response?.statusCode
    }
    
    public var headers: [String: Any]? {
        return self.result.response?.allHeaderFields as? [String: Any]
    }
    
    public var body: Data? {
        return self.result.data
    }
    
    public var bodyString: String? {
        guard let bodyData = self.body else { return nil }
        
        return String(data: bodyData, encoding: .utf8)
    }
    
    public var bodyJSON: [[String: Any]]? {
        guard let bodyData = self.body else { return nil }
        
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: bodyData, options: .allowFragments) as? [[String: Any]]
            return jsonArray
        } catch {
            return nil
        }
    }
    
    public var error: Error? {
        return self.result.error
    }
    
    // MARK: - Initialization
    public init(result: RemoteWorkerResult) {
        self.result = result
    }
}

public class RemoteLoggerEventDate {
    
    // MARK: - Private Props
    private var dateCreated: Date
    private var dateStartRequest: Date?
    private var dateFinishRequest: Date?
    
    // MARK: - Computed Props
    public var createdAt: Date {
        return self.dateCreated
    }
    
    public var startedAt: Date? {
        return self.dateStartRequest
    }
    
    public var finishedAt: Date? {
        return self.dateFinishRequest
    }
    
    public var duration: TimeInterval? {
        guard let dateStartRequest = self.dateStartRequest else { return nil }
        guard let dateFinishRequest = self.dateFinishRequest else { return nil }
        
        return dateFinishRequest.timeIntervalSinceReferenceDate - dateStartRequest.timeIntervalSinceReferenceDate
    }
    
    // MARK: - Initialization
    public init(dateCreated: Date, dateStartRequest: Date?, dateFinishRequest: Date?) {
        self.dateCreated = dateCreated
        self.dateStartRequest = dateStartRequest
        self.dateFinishRequest = dateFinishRequest
    }
}
