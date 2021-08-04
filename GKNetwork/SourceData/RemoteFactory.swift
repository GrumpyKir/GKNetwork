//
//  RemoteFactory.swift
//
//  Created by  Кирилл on 4/12/19.
//  Copyright © 2019 AppCraft. All rights reserved.
//

import GKExtensions

public enum RequestBodyType {
    case json
    case formData
}

public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
    
    public var stringValue: String {
        return self.rawValue
    }
}

public enum RemoteFactory {
    
    // MARK: - Public methods
    public static func request(path: String, parameters: [String: Any]?, headers: [String: String]?, method: HTTPMethod, bodyType: RequestBodyType = .json) -> URLRequest? {
        switch method {
        case .get,
             .head:
            return self.createRequestWithUrlParameters(path: path, parameters: parameters, headers: headers, method: method)
        case .post,
             .put,
             .patch,
             .delete:
            return self.createRequestWithBodyParameters(path: path, parameters: parameters, headers: headers, method: method, bodyType: bodyType)
        case .options,
             .trace,
             .connect:
            // TODO: Add support to other http methods
            NSLog("[GKNetwork:RemoteFactory] - ERROR: method \(method.stringValue) is not supporting now.")
        }
        
        return nil
    }
    
    public static func request<RequestModel: Codable>(path: String, object: RequestModel, headers: [String: String]?, method: HTTPMethod) -> URLRequest? {
        switch method {
        case .get,
             .head:
            NSLog("[GKNetwork:RemoteFactory] - ERROR: request with generic parameters does not support GET and HEAD methodы. Please use dictionary parameters instead.")
        case .post,
             .put,
             .patch,
             .delete:
            let urlString = path
            guard let url = URL(string: urlString) else { return nil }
            
            var request = URLRequest(url: url)
            request.httpMethod = method.stringValue
            
            let jsonEncoder = JSONEncoder()
            var jsonData: Data?
            do {
                jsonData = try jsonEncoder.encode(object)
            } catch let error {
                NSLog("[GKNetwork:RemoteFactory] - ERROR: could not serialize object, \(error.localizedDescription).")
            }
            request.httpBody = jsonData
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let headers = headers {
                for header in headers {
                    request.setValue(header.value, forHTTPHeaderField: header.key)
                }
            }
            
            return request
        case .options,
             .trace,
             .connect:
            // TODO: Add support to other http methods
            NSLog("[GKNetwork:RemoteFactory] - ERROR: method \(method.stringValue) is not supporting now.")
        }
        
        return nil
    }
    
    public static func upload(path: String, fileKey: String, files: [RemoteUploadModel], parameters: [String: Any]?, headers: [String: String]?) -> URLRequest? {
        let urlString = path
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.stringValue
        
        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        let boundary = self.generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = self.generateFormDataBody(boundary: boundary, parameters: parameters, fileKey: fileKey, files: files)
        
        return request
    }
    
    // MARK: - Private methods
    private static func createRequestWithUrlParameters(path: String, parameters: [String: Any]?, headers: [String: String]?, method: HTTPMethod) -> URLRequest? {
        var parameterString = ""
        if let parameters = parameters {
            parameterString = self.generateUrlString(with: parameters)
        }
        
        var urlString = path
        if !parameterString.isEmpty {
            urlString += "?" + parameterString
        }
        
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method.stringValue
        
        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        return request
    }
    
    private static func createRequestWithBodyParameters(path: String, parameters: [String: Any]?, headers: [String: String]?, method: HTTPMethod, bodyType: RequestBodyType) -> URLRequest? {
        let urlString = path
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.stringValue
        
        switch bodyType {
        case .json:
            var jsonData: Data?
            if let parameters = parameters {
                do {
                    jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
                } catch let error {
                    NSLog("[GKNetwork:RemoteFactory] - ERROR: could not serialize dictionary, \(error.localizedDescription).")
                }
            }
            request.httpBody = jsonData
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .formData:
            let boundary = self.generateBoundaryString()
            
            if let parameters = parameters {
                request.httpBody = self.generateFormDataBody(boundary: boundary, parameters: parameters)
            }
            
            request.setValue("application/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        }
        
        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        return request
    }
    
    private static func generateUrlString(with parameters: [String: Any]) -> String {
        let parameterArray = parameters.map { key, value -> String in
            guard let escapedKey = key.addingPercentEncodingForUrlQueryValue() else { return "" }
            
            if let stringValue = value as? String {
                guard let escapedValue = stringValue.addingPercentEncodingForUrlQueryValue() else { return "" }
                
                return "\(escapedKey)=\(escapedValue)"
            }
            
            if let arrayValue = value as? [Any] {
                var arrayParameter: [String] = []
                
                for index in 0..<arrayValue.count {
                    var element: String
                    if let stringElement = arrayValue[index] as? String {
                        element = stringElement
                    } else {
                        element = "\(arrayValue[index])"
                    }
                    
                    guard let escapedElement = element.addingPercentEncodingForUrlQueryValue() else { continue }
                    
                    arrayParameter.append("\(escapedKey)[]=\(escapedElement)")
                }
                
                return arrayParameter.joined(separator: "&")
            }
            
            guard let escapedValue = "\(value)".addingPercentEncodingForUrlQueryValue() else { return "" }
            
            return "\(escapedKey)=\(escapedValue)"
        }
        
        return parameterArray.joined(separator: "&")
    }
    
    private static func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    private static func generateFormDataBody(boundary: String, parameters: [String: Any]?, fileKey: String = "", files: [RemoteUploadModel] = []) -> Data {
        var body = Data()
        
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        for file in files {
            let filename = file.filename
            let data = file.data
            let mimetype = data.mimeType
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(fileKey)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
}

public struct RemoteUploadModel {
    public var filename: String
    public var data: Data
    
    public init(filename: String, data: Data) {
        self.filename = filename
        self.data = data
    }
}
